#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

ENV_FILE="${1:-}"
[[ -n "$ENV_FILE" ]] || die "Usage: bash scripts/generate-imagebuilder-manifest.sh <env-file>"

load_env_file "$ENV_FILE"

CATEGORY_DIR="$ROOT_DIR/configs/imagebuilder/categories"
PRESET_FILE="${PRESET_FILE:-}"
OUTPUT_MANIFEST="${GENERATED_PACKAGES_FILE:-$ROOT_DIR/dist/imagebuilder/generated-packages.txt}"
OUTPUT_COMPONENTS="${GENERATED_COMPONENTS_FILE:-$ROOT_DIR/dist/imagebuilder/generated-components.txt}"

ensure_dir "$(dirname "$OUTPUT_MANIFEST")"
ensure_dir "$(dirname "$OUTPUT_COMPONENTS")"

if [[ -n "${OVERRIDE_PRESET_FILE:-}" ]]; then
  PRESET_FILE="$OVERRIDE_PRESET_FILE"
fi

if [[ -n "$PRESET_FILE" ]]; then
  require_file "$PRESET_FILE"
  # shellcheck disable=SC1090
  source "$PRESET_FILE"
fi

if [[ -n "${OVERRIDE_COMPONENT_THEMES:-}" ]]; then
  COMPONENT_THEMES="$OVERRIDE_COMPONENT_THEMES"
fi

if [[ -n "${OVERRIDE_COMPONENT_PROXY:-}" ]]; then
  COMPONENT_PROXY="$OVERRIDE_COMPONENT_PROXY"
fi

if [[ -n "${OVERRIDE_COMPONENT_STORAGE:-}" ]]; then
  COMPONENT_STORAGE="$OVERRIDE_COMPONENT_STORAGE"
fi

if [[ -n "${OVERRIDE_COMPONENT_NETWORK:-}" ]]; then
  COMPONENT_NETWORK="$OVERRIDE_COMPONENT_NETWORK"
fi

if [[ -n "${OVERRIDE_COMPONENT_BYPASS:-}" ]]; then
  COMPONENT_BYPASS="$OVERRIDE_COMPONENT_BYPASS"
fi

if [[ -n "${OVERRIDE_COMPONENT_DNS:-}" ]]; then
  COMPONENT_DNS="$OVERRIDE_COMPONENT_DNS"
fi

if [[ -n "${OVERRIDE_COMPONENT_IMAGE:-}" ]]; then
  COMPONENT_IMAGE="$OVERRIDE_COMPONENT_IMAGE"
fi
if [[ -n "${OVERRIDE_COMPONENT_EXTRAS:-}" ]]; then
  COMPONENT_EXTRAS="$OVERRIDE_COMPONENT_EXTRAS"
fi


: "${COMPONENT_THEMES:=stock}"
: "${COMPONENT_PROXY:=none}"
: "${COMPONENT_STORAGE:=common}"
: "${COMPONENT_NETWORK:=enhanced}"
: "${COMPONENT_BYPASS:=off}"
: "${COMPONENT_DNS:=none}"
: "${COMPONENT_IMAGE:=default}"
: "${COMPONENT_EXTRAS:=none}"

temp_manifest="$(mktemp)"
trap 'rm -f "$temp_manifest"' EXIT

append_category() {
  local category_name="$1"
  local category_file="$CATEGORY_DIR/$category_name.txt"

  [[ "$category_name" == "none" || "$category_name" == "off" || "$category_name" == "default" ]] && return 0
  require_file "$category_file"
  cat "$category_file" >> "$temp_manifest"
  printf '\n' >> "$temp_manifest"
}

append_category "base"
append_category "tools-common"
append_category "theme-$COMPONENT_THEMES"
append_category "network-$COMPONENT_NETWORK"
append_category "storage-$COMPONENT_STORAGE"
append_category "dns-$COMPONENT_DNS"
append_category "tools-extras"


if [[ "$COMPONENT_PROXY" != "none" ]]; then
  append_category "proxy-$COMPONENT_PROXY"
fi

if [[ "$COMPONENT_BYPASS" == "on" ]]; then
  append_category "network-bypass"
fi

sort -u "$temp_manifest" | awk 'NF > 0' > "$OUTPUT_MANIFEST"

write_key_value_file "$OUTPUT_COMPONENTS" \
  "preset_file=${PRESET_FILE:-none}" \
  "component_themes=$COMPONENT_THEMES" \
  "component_proxy=$COMPONENT_PROXY" \
  "component_storage=$COMPONENT_STORAGE" \
  "component_network=$COMPONENT_NETWORK" \
  "component_bypass=$COMPONENT_BYPASS" \
  "component_dns=$COMPONENT_DNS" \
  "component_image=$COMPONENT_IMAGE"
  "component_extras=$COMPONENT_EXTRAS" \

printf '%s\n' "$OUTPUT_MANIFEST"
