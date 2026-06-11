#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

MODE="${2:-}"

if [[ "${1:-}" != "--mode" ]] || [[ -z "$MODE" ]]; then
  die "Usage: bash scripts/check-env.sh --mode <shell|yaml|structure|all>"
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
  all)
    check_shell
    check_yaml
    check_structure
    ;;
  *)
    die "Unknown mode: $MODE"
    ;;
esac
