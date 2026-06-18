#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

MODE="${2:-}"

if [[ "${1:-}" != "--mode" ]] || [[ -z "$MODE" ]]; then
  die "Usage: bash scripts/check-env.sh --mode <shell|yaml|structure|firewall|all>"
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
  local package_pattern='^(iptables|ip6tables|iptables-nft|iptables-legacy|ip6tables-legacy|iptables-mod-.*|ip6tables-mod-.*|kmod-ipt-.*)$'
  local config_pattern='^CONFIG_PACKAGE_(iptables|ip6tables|iptables-nft|iptables-legacy|ip6tables-legacy|iptables-mod-.*|ip6tables-mod-.*|kmod-ipt-.*)=y$'

  while IFS= read -r file; do
    while IFS= read -r line; do
      printf 'Forbidden explicit xtables package in %s: %s\n' "$file" "$line" >&2
      failed=1
    done < <(awk -v pattern="$package_pattern" 'NF && $1 !~ /^#/ && $1 ~ pattern { print NR ":" $1 }' "$file")
  done < <(find "$ROOT_DIR/configs/imagebuilder" -type f -name '*.txt' | sort)

  while IFS= read -r file; do
    while IFS= read -r line; do
      printf 'Forbidden explicit xtables config in %s: %s\n' "$file" "$line" >&2
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
  all)
    check_shell
    check_yaml
    check_structure
    check_firewall_stack
    ;;
  *)
    die "Unknown mode: $MODE"
    ;;
esac
