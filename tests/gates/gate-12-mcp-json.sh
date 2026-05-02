#!/usr/bin/env bash
# Gate 12: .mcp.json lists every required server (by short key); every entry
# carries a pinned `version` and a `timeoutMs`.

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=12
FILE="$PLUGIN_ROOT/.mcp.json"

[[ -f "$FILE" ]] || gate_fail "$GATE" ".mcp.json missing"
jq -e . "$FILE" >/dev/null 2>&1 || gate_fail "$GATE" ".mcp.json is not valid JSON"

# Required server keys per the README short-key mapping
REQUIRED=(kb iac cost sec iam cw)
actual=()
read_into actual < <(jq -r '.mcpServers | keys[]' "$FILE" | sort)
required_sorted=()
read_into required_sorted < <(printf '%s\n' "${REQUIRED[@]}" | sort)

# Compare sets
extra=$(comm -23 <(printf '%s\n' "${actual[@]}") <(printf '%s\n' "${required_sorted[@]}"))
missing=$(comm -13 <(printf '%s\n' "${actual[@]}") <(printf '%s\n' "${required_sorted[@]}"))

if [[ -n "$missing" ]]; then
  gate_warn "$GATE" "missing required servers: $(echo "$missing" | tr '\n' ' ')"
fi
if [[ -n "$extra" ]]; then
  gate_warn "$GATE" "unexpected servers (v0.2 servers gated behind explicit version bump): $(echo "$extra" | tr '\n' ' ')"
fi
[[ -z "$missing" && -z "$extra" ]] || gate_fail "$GATE" ".mcp.json server set does not match required set"

# Per-server: version pinned, timeoutMs present
failed=0
for key in "${REQUIRED[@]}"; do
  version=$(jq -r ".mcpServers.$key.version // \"\"" "$FILE")
  timeout=$(jq -r ".mcpServers.$key.timeoutMs // \"\"" "$FILE")
  if [[ -z "$version" ]]; then
    gate_warn "$GATE" "$key: missing 'version' field"
    failed=$((failed + 1))
  fi
  if [[ -z "$timeout" ]]; then
    gate_warn "$GATE" "$key: missing 'timeoutMs' field"
    failed=$((failed + 1))
  elif ! [[ "$timeout" =~ ^[0-9]+$ ]]; then
    gate_warn "$GATE" "$key: timeoutMs must be integer, got '$timeout'"
    failed=$((failed + 1))
  fi
done

if [[ $failed -gt 0 ]]; then
  gate_fail "$GATE" "$failed per-server schema violations"
fi

gate_pass "$GATE" "${#REQUIRED[@]} servers, all pinned and timeout-configured"
