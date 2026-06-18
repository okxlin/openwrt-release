#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() {
  printf '[INFO] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

require_file() {
  local file_path="$1"
  [[ -f "$file_path" ]] || die "Required file not found: $file_path"
}

require_dir() {
  local dir_path="$1"
  [[ -d "$dir_path" ]] || die "Required directory not found: $dir_path"
}

ensure_dir() {
  local dir_path="$1"
  mkdir -p "$dir_path"
}

require_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 || die "Required command not found: $command_name"
}

require_linux_host() {
  local kernel_name
  kernel_name="$(uname -s)"

  case "$kernel_name" in
    Linux)
      ;;
    *)
      die "OpenWrt build steps require a Linux host. Current host reports: $kernel_name"
      ;;
  esac
}

sha256_file() {
  local file_path="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file_path"
  else
    shasum -a 256 "$file_path"
  fi
}

# GNU tar >= 1.35 refuses to run configure as root.
# Set this unconditionally when running as root to keep both root and non-root compatible.
if [[ "$(id -u)" -eq 0 ]]; then
  export FORCE_UNSAFE_CONFIGURE=1
fi
