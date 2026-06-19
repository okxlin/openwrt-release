#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

SOURCE_ARTIFACT_DIR="${1:-}"
DEST_DIR="${2:-}"

[[ -n "$SOURCE_ARTIFACT_DIR" && -n "$DEST_DIR" ]] || die "Usage: bash scripts/package-artifacts.sh <source-dir> <dest-dir>"

require_dir "$SOURCE_ARTIFACT_DIR"
ensure_dir "$DEST_DIR"

cp -R "$SOURCE_ARTIFACT_DIR"/. "$DEST_DIR/"

# If BUILD_TAG is set, rename firmware images to include version and tag
# Example: openwrt-24.10.7-v1.0-x86-64-generic-squashfs-combined-efi.img.gz
if [[ -n "${BUILD_TAG:-}" ]]; then
  ver="${OPENWRT_VERSION:-openwrt}"
  log "Renaming artifacts with tag: ${ver}-${BUILD_TAG}"
  while IFS= read -r -d '' img; do
    dir="$(dirname "$img")"
    base="$(basename "$img")"
    if [[ "$base" == openwrt-"${ver}"-"${BUILD_TAG}"-* ]]; then
      continue
    fi
    # Normalize both release ImageBuilder and source-build names.
    if [[ "$base" == openwrt-"${ver}"-* ]]; then
      suffix="${base#openwrt-${ver}-}"
    elif [[ "$base" == openwrt-* ]]; then
      suffix="${base#openwrt-}"
    else
      suffix="$base"
    fi
    new_base="openwrt-${ver}-${BUILD_TAG}-${suffix}"
    if [[ "$base" == "$new_base" ]]; then
      continue
    fi
    mv "$img" "${dir}/${new_base}"
    log "  $(basename "$img") -> ${new_base}"
  done < <(find "$DEST_DIR" -name '*.img.gz' -print0)
fi

if [[ -d "$DEST_DIR/metadata" ]]; then
  log "Preserving metadata directory in $DEST_DIR/metadata"
fi

local_checksums_file="$DEST_DIR/sha256sums"
rm -f "$local_checksums_file"

while IFS= read -r file; do
  sha256_file "$file" >> "$local_checksums_file"
done < <(find "$DEST_DIR" -type f ! -name 'sha256sums' | sort)

log "Artifacts packaged into $DEST_DIR"
