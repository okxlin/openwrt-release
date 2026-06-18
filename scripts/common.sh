#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

load_env_file() {
  local env_file="$1"
  require_file "$env_file"

  # shellcheck disable=SC1090
  source "$env_file"
}

load_config_file() {
  local config_file="$1"
  require_file "$config_file"
}

resolve_imagebuilder_components() {
  if [[ -n "${OVERRIDE_PRESET_FILE:-}" ]]; then
    PRESET_FILE="$OVERRIDE_PRESET_FILE"
  fi

  if [[ -n "${PRESET_FILE:-}" ]]; then
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
}

join_packages() {
  local packages_file="$1"
  require_file "$packages_file"
  tr '\n' ' ' < "$packages_file" | xargs
}

write_metadata_file() {
  local output_file="$1"

  cat > "$output_file" <<EOF
build_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
git_sha=${GITHUB_SHA:-local}
workflow=${GITHUB_WORKFLOW:-local}
runner=${RUNNER_OS:-local}
EOF
}

write_key_value_file() {
  local output_file="$1"
  shift

  : > "$output_file"

  while [[ $# -gt 0 ]]; do
    printf '%s\n' "$1" >> "$output_file"
    shift
  done
}

copy_if_exists() {
  local source_path="$1"
  local destination_path="$2"

  if [[ -e "$source_path" ]]; then
    cp "$source_path" "$destination_path"
  fi
}
