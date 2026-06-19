#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

ENV_FILE="${1:-configs/imagebuilder/example-x86_64.env}"

require_linux_host
require_file "$ENV_FILE"

for command_name in bash curl file gawk make rsync tar zstd; do
  require_command "$command_name"
done

log "Running repository validation"
bash "$SCRIPT_DIR/check-env.sh" --mode all

log "Building OpenWrt image from $ENV_FILE"
bash "$SCRIPT_DIR/build-imagebuilder.sh" "$ENV_FILE"

log "Linux helper build completed."
