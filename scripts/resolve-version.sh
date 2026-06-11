#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

ENV_FILE="${1:-}"
[[ -n "$ENV_FILE" ]] || die "Usage: bash scripts/resolve-version.sh <imagebuilder-env-file>"

load_env_file "$ENV_FILE"

cat <<EOF
OPENWRT_VERSION=$OPENWRT_VERSION
OPENWRT_TARGET=$OPENWRT_TARGET
OPENWRT_SUBTARGET=$OPENWRT_SUBTARGET
OPENWRT_PROFILE=$OPENWRT_PROFILE
OPENWRT_RELEASE_PATH=$OPENWRT_RELEASE_PATH
IMAGEBUILDER_NAME=$IMAGEBUILDER_NAME
EOF
