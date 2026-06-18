#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

MODE="${2:-}"

if [[ "${1:-}" != "--mode" ]] || [[ -z "$MODE" ]]; then
  die "Usage: bash scripts/check-env.sh --mode <shell|yaml|structure|firewall|bypass|imagebuilder|all>"
fi

check_shell() {
  local files=()
  while IFS= read -r file; do
    files+=("$file")
  done < <(find "$ROOT_DIR/scripts" -type f -name '*.sh' | sort)

  [[ ${#files[@]} -gt 0 ]] || die "No shell scripts found in scripts/."

  for file in "${files[@]}"; do
    bash -n "$file"
  done

  log "Shell syntax validation passed."
}

check_yaml() {
  local workflow_dir="$ROOT_DIR/.github/workflows"
  require_dir "$workflow_dir"
  local python_cmd=""

  local files=()
  while IFS= read -r file; do
    files+=("$file")
  done < <(find "$workflow_dir" -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)

  [[ ${#files[@]} -gt 0 ]] || die "No workflow YAML files found."

  if command -v python3 >/dev/null 2>&1; then
    python_cmd="python3"
  elif command -v python >/dev/null 2>&1; then
    python_cmd="python"
  else
    die "Python interpreter not found for YAML validation."
  fi

  "$python_cmd" "$ROOT_DIR/scripts/validate_workflows.py" "${files[@]}"

  log "Workflow structure validation passed."
}

check_structure() {
  require_dir "$ROOT_DIR/configs"
  require_dir "$ROOT_DIR/docs"
  require_dir "$ROOT_DIR/feeds"
  require_dir "$ROOT_DIR/files"
  require_dir "$ROOT_DIR/scripts"

  require_file "$ROOT_DIR/.editorconfig"
  require_file "$ROOT_DIR/.gitattributes"
  require_file "$ROOT_DIR/README.md"
  require_file "$ROOT_DIR/configs/imagebuilder/example-x86_64.env"
  require_file "$ROOT_DIR/configs/source/example-x86_64.config"

  log "Repository structure validation passed."
}

check_firewall_stack() {
  local failed=0
  local package_pattern='^(iptables|ip6tables|iptables-nft|iptables-legacy|ip6tables-legacy|iptables-zz-legacy|iptables-mod-.*|ip6tables-mod-.*|xtables.*|kmod-ipt-.*|luci-app-sqm|sqm-scripts)$'
  local config_pattern='^CONFIG_PACKAGE_(iptables|ip6tables|iptables-nft|iptables-legacy|ip6tables-legacy|iptables-zz-legacy|iptables-mod-.*|ip6tables-mod-.*|xtables.*|kmod-ipt-.*|luci-app-sqm|sqm-scripts)=y$'

  while IFS= read -r file; do
    while IFS= read -r line; do
      printf 'Forbidden explicit legacy firewall package in %s: %s\n' "$file" "$line" >&2
      failed=1
    done < <(awk -v pattern="$package_pattern" 'NF && $1 !~ /^#/ && $1 ~ pattern { print NR ":" $1 }' "$file")
  done < <(find "$ROOT_DIR/configs/imagebuilder" -type f -name '*.txt' | sort)

  while IFS= read -r file; do
    while IFS= read -r line; do
      printf 'Forbidden explicit legacy firewall config in %s: %s\n' "$file" "$line" >&2
      failed=1
    done < <(awk -v pattern="$config_pattern" '$0 ~ pattern { print NR ":" $0 }' "$file")
  done < <(find "$ROOT_DIR/configs/source" -type f -name '*.config' | sort)

  while IFS= read -r file; do
    while IFS= read -r line; do
      printf 'Forbidden direct xtables command in %s: %s\n' "$file" "$line" >&2
      failed=1
    done < <(awk '/(^|[^A-Za-z0-9_-])(iptables|ip6tables|iptables-save|ip6tables-save|iptables-legacy|ip6tables-legacy)([^A-Za-z0-9_-]|$)/ { print NR ":" $0 }' "$file")
  done < <(find "$ROOT_DIR/files" "$ROOT_DIR/packages" "$ROOT_DIR/scripts" \
    -type f \
    ! -path "$ROOT_DIR/scripts/check-env.sh" \
    ! -path '*/.github/*' \
    ! -path '*/luci-theme-argon/*' \
    ! -name '*.md' \
    ! -name '*.yml' \
    ! -name '*.yaml' \
    ! -name '*.po' \
    ! -name '*.pot' \
    ! -name '*.css' \
    ! -name '*.less' \
    | sort)

  [[ "$failed" -eq 0 ]] || die "Firewall stack validation failed."
  log "Firewall stack validation passed."
}

check_bypass_preset() {
  local preset_script="$ROOT_DIR/files/presets/bypass-router/etc/uci-defaults/30-bypass-router"
  require_file "$preset_script"
  bash -n "$preset_script"

  local temp_dir uci_log fake_uci
  temp_dir="$(mktemp -d)"
  uci_log="$temp_dir/uci.log"
  fake_uci="$temp_dir/uci"
  trap 'rm -rf "$temp_dir"' RETURN

  {
    printf '%s\n' '#!/usr/bin/env sh'
    printf '%s\n' 'if [ "$*" = "-q show firewall" ]; then'
    printf '%s\n' "  printf '%s\n' \"firewall.@zone[0].name='lan'\""
    printf '%s\n' 'fi'
    printf '%s\n' 'printf "%s\n" "$*" >> "$UCI_LOG"'
  } > "$fake_uci"
  chmod +x "$fake_uci"

  UCI_LOG="$uci_log" PATH="$temp_dir:$PATH" sh "$preset_script"

  local required_commands=(
    "-q set network.lan.proto=static"
    "-q set network.lan.ipaddr=10.0.0.2"
    "-q set network.lan.netmask=255.255.255.0"
    "-q set network.lan.gateway=10.0.0.1"
    "-q add_list network.lan.dns=10.0.0.1"
    "-q set dhcp.lan.ignore=1"
    "-q set dhcp.lan.ra=disabled"
    "-q set dhcp.lan.dhcpv6=disabled"
    "-q set dhcp.lan.ndp=disabled"
    "-q set firewall.@zone[0].forward=ACCEPT"
    "-q commit network"
    "-q commit dhcp"
    "-q commit firewall"
  )

  local command
  for command in "${required_commands[@]}"; do
    grep -Fx -- "$command" "$uci_log" >/dev/null || die "Bypass preset missing UCI command: $command"
  done

  log "Bypass router preset validation passed."
}

check_imagebuilder_overrides() {
  load_env_file "$ROOT_DIR/configs/imagebuilder/example-x86_64.env"
  OVERRIDE_PRESET_FILE="$ROOT_DIR/configs/imagebuilder/presets/bypass-router.env"
  resolve_imagebuilder_components

  [[ "$COMPONENT_BYPASS" == "on" ]] || die "ImageBuilder override preset did not enable COMPONENT_BYPASS."
  [[ "$COMPONENT_PROXY" == "none" ]] || die "Bypass ImageBuilder preset should not require source-only proxy packages."

  log "ImageBuilder override validation passed."
}

check_imagebuilder_overlay_copy() {
  local temp_dir source_dir dest_dir
  temp_dir="$(mktemp -d)"
  source_dir="$temp_dir/source"
  dest_dir="$temp_dir/dest"
  trap 'rm -rf "$temp_dir"' RETURN

  mkdir -p "$source_dir/etc" "$source_dir/presets/bypass-router/etc"
  printf '%s\n' base > "$source_dir/etc/base"
  printf '%s\n' preset > "$source_dir/presets/bypass-router/etc/preset"

  copy_imagebuilder_base_files "$source_dir" "$dest_dir"

  [[ -f "$dest_dir/etc/base" ]] || die "ImageBuilder base overlay copy missed files/etc content."
  [[ ! -e "$dest_dir/presets" ]] || die "ImageBuilder base overlay copy leaked files/presets into rootfs."

  log "ImageBuilder overlay copy validation passed."
}

case "$MODE" in
  shell)
    check_shell
    ;;
  yaml)
    check_yaml
    ;;
  structure)
    check_structure
    ;;
  firewall)
    check_firewall_stack
    ;;
  bypass)
    check_bypass_preset
    ;;
  imagebuilder)
    check_imagebuilder_overrides
    check_imagebuilder_overlay_copy
    ;;
  all)
    check_shell
    check_yaml
    check_structure
    check_firewall_stack
    check_bypass_preset
    check_imagebuilder_overrides
    check_imagebuilder_overlay_copy
    ;;
  *)
    die "Unknown mode: $MODE"
    ;;
esac
