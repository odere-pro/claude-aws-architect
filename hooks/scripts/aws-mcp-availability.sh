#!/usr/bin/env bash
# aws-mcp-availability — UserPromptSubmit hook that warns the user when an
# MCP server declared in .mcp.json is explicitly disabled in the consumer's
# Claude Code settings. Emits an additionalContext block naming each
# disabled server and the remediation path (/mcp UI or settings edit).
#
# Input (stdin, JSON, from Claude Code):
#   { "session_id": "...", "prompt": "user message text" }
#
# Output (stdout, JSON): hookSpecificOutput.additionalContext when there are
#   disabled MCPs; otherwise empty (exit 0 silently).
# Output (stderr): on parse/lookup failure, a one-line diagnostic.
#
# Exit codes:
#   0  always (warning is informational; do not block prompts).
#
# This hook reads:
#   - $CLAUDE_PLUGIN_ROOT/.mcp.json — declared servers.
#   - $CONSUMER_ROOT/.claude/settings.local.json  (if present)
#   - $CONSUMER_ROOT/.claude/settings.json        (if present)
#   - $HOME/.claude/settings.json                 (if present)
#
# $CONSUMER_ROOT defaults to $PWD. Settings files later in the precedence
# list above are still inspected; the verdict per server is "disabled" if
# any file lists it in disabledMcpjsonServers, "enabled" if any file
# explicitly allows it, otherwise "pending".

set -euo pipefail
IFS=$'\n\t'

export HOOK_NAME=aws-mcp-availability

# Drain stdin so Claude Code does not see a SIGPIPE; we do not need the body
# for this hook beyond optional session_id passthrough.
if [[ ! -t 0 ]]; then
  cat >/dev/null
fi

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CONSUMER="${CONSUMER_ROOT:-$PWD}"

mcp_file="$PLUGIN_ROOT/.mcp.json"

if [[ ! -f "$mcp_file" ]] || ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

settings_files=(
  "$CONSUMER/.claude/settings.local.json"
  "$CONSUMER/.claude/settings.json"
  "$HOME/.claude/settings.json"
)

lookup_state() {
  # Args: $1 = server name. Echoes one of: enabled | disabled | pending.
  local server="$1"
  local enable_all=0 in_enabled=0 in_disabled=0 verdict f
  for f in "${settings_files[@]}"; do
    [[ -f "$f" ]] || continue
    verdict=$(jq -r --arg s "$server" '
      [
        (if (.enableAllProjectMcpServers // false) then "all" else empty end),
        (if ((.disabledMcpjsonServers // []) | index($s)) != null then "dis" else empty end),
        (if ((.enabledMcpjsonServers  // []) | index($s)) != null then "en"  else empty end)
      ] | join(",")
    ' "$f" 2>/dev/null) || verdict=""
    [[ "$verdict" == *"all"* ]] && enable_all=1
    [[ "$verdict" == *"dis"* ]] && in_disabled=1
    [[ "$verdict" == *"en"*  ]] && in_enabled=1
  done
  if [[ $in_disabled -eq 1 ]]; then
    echo "disabled"
  elif [[ $in_enabled -eq 1 || $enable_all -eq 1 ]]; then
    echo "enabled"
  else
    echo "pending"
  fi
}

disabled_servers=()
while IFS= read -r name; do
  [[ -z "$name" ]] && continue
  state=$(lookup_state "$name")
  if [[ "$state" == "disabled" ]]; then
    disabled_servers+=("$name")
  fi
done < <(jq -r '.mcpServers | keys[]' "$mcp_file" 2>/dev/null)

if [[ ${#disabled_servers[@]} -eq 0 ]]; then
  exit 0
fi

# Build a human-readable context block.
list=$(printf -- '- %s\n' "${disabled_servers[@]}")
context=$(printf '%s\n%s\n%s\n%s\n' \
  "claude-aws-architect: MCP availability warning" \
  "" \
  "The following MCP servers are declared in .mcp.json but explicitly disabled in this consumer's settings:" \
  "$list")
context+=$(printf '\n%s\n%s\n%s\n%s\n%s\n' \
  "" \
  "Skills and recipes that depend on these servers will emit mcp-disabled markers and degrade." \
  "" \
  "Remediation:" \
  "  1. Run /mcp to review and approve the server, or")
context+=$(printf '\n%s\n%s\n%s\n' \
  "  2. Remove the server name from \"disabledMcpjsonServers\" in .claude/settings.json or .claude/settings.local.json, or" \
  "  3. Run /aws-doctor for a full environment health report." \
  "")

# Emit per the UserPromptSubmit hook contract.
jq -n --arg ctx "$context" '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: $ctx
  }
}'

exit 0
