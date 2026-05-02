#!/usr/bin/env bash
# Shared helpers for scripts/*.sh.
# Source this file at the top of every script.
#
# Bash 3.2 compatible (macOS default). No associative arrays, no mapfile.

set -euo pipefail
IFS=$'\n\t'

# Resolve the plugin root from this lib's location.
PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PLUGIN_ROOT

# Consumer .claude/ tree. Default is the directory the user invokes from.
CONSUMER_ROOT="${CONSUMER_ROOT:-$PWD}"
export CONSUMER_ROOT

# Manifest file recording every install action; uninstall.sh reads it.
MANIFEST_REL=".claude/.claude-aws-architect-installed.jsonl"
export MANIFEST_REL

# Colour helpers honouring NO_COLOR. All log output goes to stderr.
if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then
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

log_info() { printf '%sinfo%s %s\n' "$C_DIM" "$C_RESET" "$*" >&2; }
log_ok()   { printf '%sok%s   %s\n' "$C_GREEN" "$C_RESET" "$*" >&2; }
log_warn() { printf '%swarn%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
log_err()  { printf '%serr%s  %s\n' "$C_RED" "$C_RESET" "$*" >&2; }

# Make a temp dir owned by this script and trap-clean it.
mktempdir() {
  local d
  d=$(mktemp -d -t "claude-aws-architect.XXXXXX")
  # Caller is responsible for installing the trap; we keep the helper pure.
  printf '%s' "$d"
}

# Append one JSON line to the manifest. Bash 3.2 friendly (no jq required).
manifest_append() {
  local action=$1 path=$2
  local manifest="$CONSUMER_ROOT/$MANIFEST_REL"
  mkdir -p "$(dirname "$manifest")"
  printf '{"action":"%s","path":"%s"}\n' "$action" "$path" >> "$manifest"
}

# Read manifest paths back as `action<TAB>path` lines on stdout.
manifest_read() {
  local manifest="$CONSUMER_ROOT/$MANIFEST_REL"
  [[ -f "$manifest" ]] || return 0
  # Strict, declarative parser: each line is exactly
  # {"action":"<a>","path":"<p>"}
  awk '
    match($0, /"action":"[^"]+"/) {
      a = substr($0, RSTART+10, RLENGTH-11)
    }
    match($0, /"path":"[^"]+"/) {
      p = substr($0, RSTART+8, RLENGTH-9)
      print a "\t" p
    }
  ' "$manifest"
}

# Print declared usage and exit 0.
print_help_and_exit() {
  local body=$1
  printf '%s\n' "$body"
  exit 0
}
