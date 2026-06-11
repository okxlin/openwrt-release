#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

ENV_FILE="${1:-}"
[[ -n "$ENV_FILE" ]] || die "Usage: bash scripts/prepare-imagebuilder.sh <env-file>"

load_env_file "$ENV_FILE"
require_linux_host

WORKDIR="$ROOT_DIR/workdir/imagebuilder/$OPENWRT_TARGET-$OPENWRT_SUBTARGET-$OPENWRT_PROFILE"
ARCHIVE_EXT="${OPENWRT_IMAGEBUILDER_EXT:-.tar.zst}"
ARCHIVE_FILE="$WORKDIR/${IMAGEBUILDER_NAME}${ARCHIVE_EXT}"
DOWNLOAD_URL="https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/${OPENWRT_RELEASE_PATH}/${IMAGEBUILDER_NAME}${ARCHIVE_EXT}"

ensure_dir "$WORKDIR"
ensure_dir "$OUTPUT_DIR"

log "Preparing ImageBuilder workspace in $WORKDIR"
log "Downloading $DOWNLOAD_URL"

if [[ ! -f "$ARCHIVE_FILE" ]]; then
  curl -fL "$DOWNLOAD_URL" -o "$ARCHIVE_FILE"
fi

if [[ ! -d "$WORKDIR/$IMAGEBUILDER_NAME" ]]; then
  tar -xf "$ARCHIVE_FILE" -C "$WORKDIR"
fi

write_metadata_file "$OUTPUT_DIR/build-metadata.txt"
log "ImageBuilder preparation completed."
