#!/usr/bin/env bash
# Gate 18: tool-name length budget.
# The longest fully-qualified tool name (`mcp__plugin_<plugin>_<server>__<tool>`)
# must be < 64 chars to satisfy Bedrock's tool-name limit.
#
# Tool lists are sourced from tests/gates/cache/tools-<server>.txt
# (statically declared; HTTP servers are seeded once and refreshed manually
# when their tool list changes).
#
# Upstream-controlled overshoots (tools defined in awslabs.* MCP packages)
# are documented in tests/gates/cache/known-overshoots.txt and treated as
# WARN rather than FAIL. The plugin cannot rename upstream tools without
# forking the package.

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=18
BUDGET=64

cd "$PLUGIN_ROOT" || exit 1

PLUGIN_NAME=$(jq -r '.name' .claude-plugin/plugin.json)
# Prefix: "mcp__plugin_<plugin>_" = 12 + len(plugin) + 1 = 13 + len(plugin)
PREFIX_LEN=$(( 13 + ${#PLUGIN_NAME} ))

overshoot_file="tests/gates/cache/known-overshoots.txt"

# bash 3.2 has no associative arrays, so we check membership by grep'ing
# the cleaned overshoot list. Returns 0 if "$1" is a known overshoot.
is_known_overshoot() {
  local key=$1
  [[ -f "$overshoot_file" ]] || return 1
  grep -Fxq "$key" "$overshoot_file"
}

servers=()
read_into servers < <(jq -r '.mcpServers | keys[]' .mcp.json)

failed=0
warned=0
total_tools=0

for server in "${servers[@]}"; do
  cache_file="tests/gates/cache/tools-$server.txt"
  if [[ ! -f "$cache_file" ]]; then
    gate_warn "$GATE" "$server: no tool cache at $cache_file (cannot enforce budget for this server)"
    warned=$((warned + 1))
    continue
  fi

  server_len=${#server}
  # Format: "mcp__plugin_<plugin>_<server>__<tool>" — total length:
  # 13 + len(plugin) + len(server) + 2 + len(tool)
  # = PREFIX_LEN + len(server) + 2 + len(tool)
  # Tool budget per server: BUDGET - PREFIX_LEN - len(server) - 2 - 1 (strict <)
  tool_budget=$(( BUDGET - PREFIX_LEN - server_len - 2 - 1 ))
  gate_info "$GATE" "$server: per-tool budget = $tool_budget chars (server-name occupies $server_len)"

  while IFS= read -r tool; do
    [[ -z "$tool" ]] && continue
    total_tools=$((total_tools + 1))
    tool_len=${#tool}
    full_len=$(( PREFIX_LEN + server_len + 2 + tool_len ))
    if [[ $full_len -ge $BUDGET ]]; then
      if is_known_overshoot "$server:$tool"; then
        gate_warn "$GATE" "$server:$tool overshoots ($full_len ≥ $BUDGET) — known upstream deviation"
        warned=$((warned + 1))
      else
        gate_warn "$GATE" "$server:$tool overshoots ($full_len ≥ $BUDGET) — NOT in known-overshoots.txt"
        failed=$((failed + 1))
      fi
    fi
  done < "$cache_file"
done

if [[ $failed -gt 0 ]]; then
  gate_fail "$GATE" "$failed un-acknowledged tool-name overshoots"
fi

if [[ $warned -gt 0 ]]; then
  gate_pass "$GATE" "$total_tools tool names checked; $warned known upstream overshoots WARN-only"
else
  gate_pass "$GATE" "$total_tools tool names checked; all within budget"
fi
