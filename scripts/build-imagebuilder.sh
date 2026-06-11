#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

ENV_FILE="${1:-}"
[[ -n "$ENV_FILE" ]] || die "Usage: bash scripts/build-imagebuilder.sh <env-file>"

load_env_file "$ENV_FILE"
bash "$SCRIPT_DIR/prepare-imagebuilder.sh" "$ENV_FILE"

if [[ -n "${PRESET_FILE:-}" || -n "${COMPONENT_THEMES:-}" || -n "${COMPONENT_PROXY:-}" || -n "${COMPONENT_STORAGE:-}" || -n "${COMPONENT_NETWORK:-}" || -n "${COMPONENT_BYPASS:-}" || -n "${COMPONENT_IMAGE:-}" ]]; then
  GENERATED_PACKAGES_FILE_PATH="$ROOT_DIR/dist/imagebuilder/generated-packages.txt"
  GENERATED_PACKAGES_FILE="$GENERATED_PACKAGES_FILE_PATH" bash "$SCRIPT_DIR/generate-imagebuilder-manifest.sh" "$ENV_FILE" >/dev/null
  PACKAGES_FILE="$GENERATED_PACKAGES_FILE_PATH"
fi

WORKDIR="$ROOT_DIR/workdir/imagebuilder/$OPENWRT_TARGET-$OPENWRT_SUBTARGET-$OPENWRT_PROFILE"
IMAGEBUILDER_DIR="$WORKDIR/$IMAGEBUILDER_NAME"
PACKAGE_LIST="$(join_packages "$PACKAGES_FILE")"
METADATA_DIR="$OUTPUT_DIR/metadata"
BUILD_FILES_DIR="$WORKDIR/build-files"

require_dir "$IMAGEBUILDER_DIR"
require_dir "$FILES_DIR"
ensure_dir "$METADATA_DIR"

rm -rf "$BUILD_FILES_DIR"
ensure_dir "$BUILD_FILES_DIR"
cp -R "$ROOT_DIR/$FILES_DIR"/. "$BUILD_FILES_DIR/"

if [[ "${COMPONENT_BYPASS:-off}" == "on" ]]; then
  cp -R "$ROOT_DIR/files/presets/bypass-router/". "$BUILD_FILES_DIR/"
fi

if [[ -n "${EXTRA_FEEDS_FILE:-}" && -f "$EXTRA_FEEDS_FILE" ]]; then
  cp "$EXTRA_FEEDS_FILE" "$IMAGEBUILDER_DIR/repositories.custom.conf"
fi

log "Building OpenWrt image via ImageBuilder"

make -C "$IMAGEBUILDER_DIR" image \
  PROFILE="$OPENWRT_PROFILE" \
  PACKAGES="$PACKAGE_LIST" \
  FILES="$BUILD_FILES_DIR" \
  DISABLED_SERVICES="${DISABLED_SERVICES:-}"

write_key_value_file "$METADATA_DIR/openwrt-version.txt" \
  "openwrt_version=$OPENWRT_VERSION" \
  "openwrt_target=$OPENWRT_TARGET" \
  "openwrt_subtarget=$OPENWRT_SUBTARGET" \
  "openwrt_profile=$OPENWRT_PROFILE" \
  "openwrt_release_path=$OPENWRT_RELEASE_PATH" \
  "imagebuilder_name=$IMAGEBUILDER_NAME"

cp "$PACKAGES_FILE" "$METADATA_DIR/packages-manifest.txt"
cp "$ENV_FILE" "$METADATA_DIR/profile.env.snapshot"
copy_if_exists "$ROOT_DIR/dist/imagebuilder/generated-components.txt" "$METADATA_DIR/generated-components.txt"

if [[ -n "${EXTRA_FEEDS_FILE:-}" && -f "$EXTRA_FEEDS_FILE" ]]; then
  cp "$EXTRA_FEEDS_FILE" "$METADATA_DIR/feeds.conf.snapshot"
else
  : > "$METADATA_DIR/feeds.conf.snapshot"
fi

if [[ -f "$IMAGEBUILDER_DIR/.config" ]]; then
  cp "$IMAGEBUILDER_DIR/.config" "$METADATA_DIR/imagebuilder.config.snapshot"
fi

if [[ -f "$IMAGEBUILDER_DIR/bin/targets/$OPENWRT_TARGET/$OPENWRT_SUBTARGET/profiles.json" ]]; then
  cp "$IMAGEBUILDER_DIR/bin/targets/$OPENWRT_TARGET/$OPENWRT_SUBTARGET/profiles.json" "$METADATA_DIR/profiles.json"
fi

bash "$SCRIPT_DIR/package-artifacts.sh" "$IMAGEBUILDER_DIR/bin/targets/$OPENWRT_TARGET/$OPENWRT_SUBTARGET" "$OUTPUT_DIR"

log "ImageBuilder build completed."
