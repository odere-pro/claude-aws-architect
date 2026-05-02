#!/usr/bin/env bash
# Shared helpers for tests/gates/*.sh.
# Source this file at the top of every gate script.

set -euo pipefail
IFS=$'\n\t'

# Resolve the plugin root from this script's location.
# Works whether the gate is invoked directly or via run-all.sh.
PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
export PLUGIN_ROOT

# Colour helpers honouring NO_COLOR.
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_DIM=$'\033[2m'
  C_RESET=$'\033[0m'
else
  C_RED=""
  C_GREEN=""
  C_YELLOW=""
  C_DIM=""
  C_RESET=""
fi

gate_pass() {
  local id=$1 msg=$2
  printf '%sPASS%s gate-%s: %s\n' "$C_GREEN" "$C_RESET" "$id" "$msg" >&2
}

gate_fail() {
  local id=$1 msg=$2
  printf '%sFAIL%s gate-%s: %s\n' "$C_RED" "$C_RESET" "$id" "$msg" >&2
  exit 1
}

gate_warn() {
  local id=$1 msg=$2
  printf '%sWARN%s gate-%s: %s\n' "$C_YELLOW" "$C_RESET" "$id" "$msg" >&2
}

gate_info() {
  local id=$1 msg=$2
  printf '%sinfo%s gate-%s: %s\n' "$C_DIM" "$C_RESET" "$id" "$msg" >&2
}

# Extract the YAML frontmatter block (between the first two `---` lines)
# from a Markdown file. Prints the YAML body to stdout. Empty if no
# frontmatter present.
extract_frontmatter() {
  local file=$1
  awk '
    BEGIN { state = "before" }
    state == "before" && /^---$/ { state = "in"; next }
    state == "in" && /^---$/ { exit }
    state == "in" { print }
  ' "$file"
}

# Validate that a YAML string parses cleanly. Exits 0 on success, 1 on failure.
yaml_valid() {
  python3 -c '
import sys, yaml
try:
    yaml.safe_load(sys.stdin.read())
    sys.exit(0)
except yaml.YAMLError as exc:
    sys.stderr.write(f"yaml parse error: {exc}\n")
    sys.exit(1)
'
}

# bash 3.2 compatible replacement for `mapfile -t VAR < <(cmd)`.
# Usage: read_into VAR_NAME < <(command)
# Reads stdin one line per element into the named array variable.
read_into() {
  local _var=$1
  eval "$_var=()"
  local _line
  while IFS= read -r _line; do
    eval "$_var+=(\"\$_line\")"
  done
}

# Walk the plugin tree, excluding noisy directories. Prints relative paths.
plugin_files() {
  local pattern=${1:-}
  cd "$PLUGIN_ROOT"
  if [[ -n "$pattern" ]]; then
    find . \
      -path ./.git -prune -o \
      -path ./node_modules -prune -o \
      -path ./.venv -prune -o \
      -path ./tests/gates/cache -prune -o \
      -type f -name "$pattern" -print
  else
    find . \
      -path ./.git -prune -o \
      -path ./node_modules -prune -o \
      -path ./.venv -prune -o \
      -path ./tests/gates/cache -prune -o \
      -type f -print
  fi
}
