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

if [[ -d "$DEST_DIR/metadata" ]]; then
  log "Preserving metadata directory in $DEST_DIR/metadata"
fi

local_checksums_file="$DEST_DIR/sha256sums"
rm -f "$local_checksums_file"

while IFS= read -r file; do
  sha256_file "$file" >> "$local_checksums_file"
done < <(find "$DEST_DIR" -type f ! -name 'sha256sums' | sort)

log "Artifacts packaged into $DEST_DIR"
