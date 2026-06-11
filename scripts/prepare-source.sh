#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

CONFIG_FILE="${1:-}"
[[ -n "$CONFIG_FILE" ]] || die "Usage: bash scripts/prepare-source.sh <config-file>"

OPENWRT_REPO="${OPENWRT_REPO:-https://github.com/openwrt/openwrt.git}"
OPENWRT_REF="${OPENWRT_REF:-openwrt-24.10}"
SOURCE_DIR="$ROOT_DIR/workdir/source/openwrt"
DIST_DIR="$ROOT_DIR/dist/source"
METADATA_DIR="$DIST_DIR/metadata"

load_config_file "$CONFIG_FILE"
require_linux_host
ensure_dir "$ROOT_DIR/workdir/source"
ensure_dir "$DIST_DIR"
ensure_dir "$METADATA_DIR"

if [[ ! -d "$SOURCE_DIR/.git" ]]; then
  git clone --depth 1 --branch "$OPENWRT_REF" "$OPENWRT_REPO" "$SOURCE_DIR"
fi

if [[ -f "$ROOT_DIR/feeds/custom-feeds.conf" ]]; then
  if [[ ! -f "$SOURCE_DIR/feeds.conf.default.template" ]]; then
    cp "$SOURCE_DIR/feeds.conf.default" "$SOURCE_DIR/feeds.conf.default.template"
  fi

  {
    cat "$SOURCE_DIR/feeds.conf.default.template"
    printf '\n'
    sed '/^#$/d' "$ROOT_DIR/feeds/custom-feeds.conf"
  } > "$SOURCE_DIR/feeds.conf.default"
fi

cp "$CONFIG_FILE" "$SOURCE_DIR/.config"

if [[ -d "$ROOT_DIR/packages" ]]; then
  ensure_dir "$SOURCE_DIR/package/custom"
  find "$SOURCE_DIR/package/custom" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
  rsync -a --exclude '.gitkeep' "$ROOT_DIR/packages/" "$SOURCE_DIR/package/custom/"
fi

if [[ -d "$ROOT_DIR/files" ]]; then
  rm -rf "$SOURCE_DIR/files"
  rsync -a "$ROOT_DIR/files/" "$SOURCE_DIR/files/"
fi

if compgen -G "$ROOT_DIR/configs/source/fragments/*.config" >/dev/null; then
  cat "$ROOT_DIR"/configs/source/fragments/*.config >> "$SOURCE_DIR/.config"
fi

if compgen -G "$ROOT_DIR/patches/openwrt/*.patch" >/dev/null; then
  for patch in "$ROOT_DIR"/patches/openwrt/*.patch; do
    if git -C "$SOURCE_DIR" apply --reverse --check "$patch" >/dev/null 2>&1; then
      warn "Skipping patch already applied: $patch"
      continue
    fi

    git -C "$SOURCE_DIR" apply --check "$patch" >/dev/null 2>&1 || die "Patch cannot be applied cleanly: $patch"
    git -C "$SOURCE_DIR" apply "$patch"
  done
fi

write_metadata_file "$DIST_DIR/source-build-metadata.txt"
cp "$CONFIG_FILE" "$METADATA_DIR/source.config.snapshot"
copy_if_exists "$ROOT_DIR/feeds/custom-feeds.conf" "$METADATA_DIR/feeds.conf.snapshot"

if compgen -G "$ROOT_DIR/configs/source/fragments/*.config" >/dev/null; then
  cat "$ROOT_DIR"/configs/source/fragments/*.config > "$METADATA_DIR/source.fragments.snapshot"
fi

log "Source tree preparation completed."
