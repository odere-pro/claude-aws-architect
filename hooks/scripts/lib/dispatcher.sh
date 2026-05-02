#!/usr/bin/env bash
# Shared dispatcher helpers for hooks under hooks/scripts/.
#
# Sourced by every per-hook script. Provides a uniform contract for:
#   - reading the Claude Code hook input JSON from stdin into $HOOK_INPUT;
#   - extracting tool_name, tool_input.* fields with jq, with safe defaults;
#   - emitting a permission decision (allow / ask / deny) as JSON on stdout;
#   - emitting structured diagnostics on stderr;
#   - exiting with the conventional codes (0 = pass-through, 2 = block).
#
# Input (from Claude Code, on stdin, JSON):
#   { "session_id": "...", "tool_name": "Write", "tool_input": { ... } }
#
# Output (on stdout when this lib is used to emit a JSON decision):
#   { "hookSpecificOutput": { "hookEventName": "PreToolUse",
#                             "permissionDecision": "allow|ask|deny",
#                             "permissionDecisionReason": "human text" } }
#
# Exit codes (when scripts opt for the simple stderr-and-exit path):
#   0   pass-through (allow)
#   2   block (deny)
#  64   bad usage (input not parseable, etc.) — surfaces to user as a hook error
#
# bash 3.2 compatible: no associative arrays, no mapfile, no `${var,,}`.

set -euo pipefail
IFS=$'\n\t'

HOOK_NAME="${HOOK_NAME:-unnamed}"

# Read all of stdin into HOOK_INPUT once. Subsequent helpers parse this
# captured value with jq so we never read stdin twice.
hook_read_input() {
  if [[ -t 0 ]]; then
    HOOK_INPUT=""
  else
    HOOK_INPUT=$(cat)
  fi
}

# Echo a field from the parsed input. $1 is a jq path expression like
# `.tool_name` or `.tool_input.file_path`. Falls back to empty string when
# the field is absent or jq is unavailable; never throws.
hook_field() {
  local path=$1
  if [[ -z "${HOOK_INPUT:-}" ]]; then
    printf '%s' ''
    return 0
  fi
  if ! command -v jq >/dev/null 2>&1; then
    printf '%s' ''
    return 0
  fi
  printf '%s' "$HOOK_INPUT" | jq -r "${path} // \"\"" 2>/dev/null || printf '%s' ''
}

# Log a structured line on stderr. Format:
#   [hook:<name>] <level> <message>
# The user sees this verbatim; keep messages short and actionable.
hook_log() {
  local level=$1
  shift
  printf '[hook:%s] %s %s\n' "$HOOK_NAME" "$level" "$*" >&2
}

# Emit a JSON permission decision to stdout. $1 = decision (allow|ask|deny),
# $2 = human-readable reason (single line).
hook_emit_decision() {
  local decision=$1
  local reason=${2:-}
  if ! command -v jq >/dev/null 2>&1; then
    # jq missing: degrade safely. Allow defaults to exit 0; deny to exit 2.
    if [[ "$decision" == "deny" ]]; then
      hook_log "ERROR" "$reason"
      exit 2
    fi
    exit 0
  fi
  jq -n \
    --arg event "PreToolUse" \
    --arg decision "$decision" \
    --arg reason "$reason" \
    '{
      hookSpecificOutput: {
        hookEventName: $event,
        permissionDecision: $decision,
        permissionDecisionReason: $reason
      }
    }'
}

# Convenience wrappers.
hook_allow() { hook_emit_decision allow "${1:-}"; exit 0; }
hook_ask()   { hook_emit_decision ask   "${1:-confirm before continuing}"; exit 0; }
hook_deny()  { hook_emit_decision deny  "${1:-blocked by hook}"; exit 2; }
