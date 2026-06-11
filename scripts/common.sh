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
