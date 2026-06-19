#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

ENV_FILE="${1:-}"
[[ -n "$ENV_FILE" ]] || die "Usage: bash scripts/generate-imagebuilder-manifest.sh <env-file>"

load_env_file "$ENV_FILE"

CATEGORY_DIR="$ROOT_DIR/configs/imagebuilder/categories"
OUTPUT_MANIFEST="${GENERATED_PACKAGES_FILE:-$ROOT_DIR/dist/imagebuilder/generated-packages.txt}"
OUTPUT_COMPONENTS="${GENERATED_COMPONENTS_FILE:-$ROOT_DIR/dist/imagebuilder/generated-components.txt}"

ensure_dir "$(dirname "$OUTPUT_MANIFEST")"
ensure_dir "$(dirname "$OUTPUT_COMPONENTS")"

resolve_imagebuilder_components

temp_manifest="$(mktemp)"
trap 'rm -f "$temp_manifest"' EXIT

append_category() {
  local category_name="$1"
  local category_file="$CATEGORY_DIR/$category_name.txt"

  [[ "$category_name" == "none" || "$category_name" == "off" || "$category_name" == "default" || "$category_name" =~ -none$ || "$category_name" =~ -off$ || "$category_name" =~ -default$ ]] && return 0
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
append_category "tools-$COMPONENT_EXTRAS"


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
  "component_image=$COMPONENT_IMAGE" \
  "component_extras=$COMPONENT_EXTRAS" \

printf '%s\n' "$OUTPUT_MANIFEST"
