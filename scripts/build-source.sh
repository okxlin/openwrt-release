#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

CONFIG_FILE="${1:-}"
[[ -n "$CONFIG_FILE" ]] || die "Usage: bash scripts/build-source.sh <config-file>"

bash "$SCRIPT_DIR/prepare-source.sh" "$CONFIG_FILE"

SOURCE_DIR="$ROOT_DIR/workdir/source/openwrt"
OUTPUT_DIR="$ROOT_DIR/dist/source"

ensure_dir "$OUTPUT_DIR"
require_dir "$SOURCE_DIR"

pushd "$SOURCE_DIR" >/dev/null
./scripts/feeds update -a
./scripts/feeds install -a

# If daed or mosdns is selected, patch golang to Go 1.26 for compatibility
# daed requires Go >= 1.26.0; mosdns v2dat requires Go >= 1.25.0
if grep -qE 'CONFIG_PACKAGE_daed=y|CONFIG_PACKAGE_mosdns=y' "$SOURCE_DIR/.config" 2>/dev/null; then
  GOLANG_MAKEFILE="$SOURCE_DIR/feeds/packages/lang/golang/golang/Makefile"
  if [[ -f "$GOLANG_MAKEFILE" ]]; then
    log 'Patching golang to 1.26 (needed by daed/mosdns)'
    sed -i 's/GO_VERSION_MAJOR_MINOR:=.*/GO_VERSION_MAJOR_MINOR:=1.26/' "$GOLANG_MAKEFILE"
    sed -i 's/GO_VERSION_PATCH:=.*/GO_VERSION_PATCH:=4/' "$GOLANG_MAKEFILE"
    sed -i 's/PKG_HASH:=.*/PKG_HASH:=4f668a32fbfc1132e6a881fb968c2f1dada631492a339211735fbb255a42602d/' "$GOLANG_MAKEFILE"
    sed -i 's|GOROOT_BOOTSTRAP=".*"|GOROOT_BOOTSTRAP="/usr/local/go"|' "$GOLANG_MAKEFILE"
    log 'golang patched to 1.26 - using /usr/local/go as bootstrap'
  else
    warn "golang Makefile not found at $GOLANG_MAKEFILE; daed/mosdns build may fail"
  fi
fi

# If openclash is selected, pre-download Meta core (mihomo) for offline use
if grep -q 'CONFIG_PACKAGE_luci-app-openclash=y' "$SOURCE_DIR/.config" 2>/dev/null; then
  CORE_DIR="$SOURCE_DIR/files/etc/openclash/core"
  CORE_FILE="$CORE_DIR/clash_meta"
  if [[ ! -f "$CORE_FILE" ]]; then
    log 'Downloading OpenClash Meta core (mihomo v1.19.27)'
    mkdir -p "$CORE_DIR"
    curl -sL -o /tmp/clash_meta.gz \
      'https://github.com/MetaCubeX/mihomo/releases/download/v1.19.27/mihomo-linux-amd64-v1-v1.19.27.gz'
    gunzip -c /tmp/clash_meta.gz > "$CORE_FILE"
    chmod +x "$CORE_FILE"
    log "OpenClash core installed: $(du -h "$CORE_FILE" | cut -f1)"
  else
    log 'OpenClash Meta core already cached, skipping download'
  fi
fi

export FORCE_UNSAFE_CONFIGURE=1
make defconfig
make -j"$(nproc)"
popd >/dev/null

bash "$SCRIPT_DIR/package-artifacts.sh" "$SOURCE_DIR/bin/targets" "$OUTPUT_DIR"

log "Full source build completed."
