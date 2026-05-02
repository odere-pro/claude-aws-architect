#!/usr/bin/env bash
# Gate 2: .claude-plugin/plugin.json parses; `name` and `engines.claude-code` present.
# Per SPEC §11.A gate 2 + O1.

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=02
FILE="$PLUGIN_ROOT/.claude-plugin/plugin.json"

[[ -f "$FILE" ]] || gate_fail "$GATE" ".claude-plugin/plugin.json missing"
jq -e . "$FILE" >/dev/null 2>&1 || gate_fail "$GATE" "plugin.json is not valid JSON"

NAME=$(jq -r '.name // empty' "$FILE")
ENGINE=$(jq -r '.engines."claude-code" // empty' "$FILE")

[[ -n "$NAME" ]] || gate_fail "$GATE" "missing required key: name"
[[ -n "$ENGINE" ]] || gate_fail "$GATE" "missing required key: engines.claude-code"

[[ "$NAME" == "claude-aws-architect" ]] || gate_fail "$GATE" "name must be 'claude-aws-architect', got '$NAME'"

gate_pass "$GATE" "name=$NAME, engines.claude-code=$ENGINE"
