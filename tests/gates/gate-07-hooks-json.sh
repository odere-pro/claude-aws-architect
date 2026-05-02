#!/usr/bin/env bash
# Gate 7: every hooks/hooks.json entry matches the hook-entry schema.
# Required per entry: name, event, matcher, command (must reference ${CLAUDE_PLUGIN_ROOT}),
# enabledByDefault. Optional: filePattern, enabledWhen.

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=07

cd "$PLUGIN_ROOT" || exit 1

if [[ ! -f hooks/hooks.json ]]; then
  gate_pass "$GATE" "hooks/hooks.json does not exist yet (no-op)"
  exit 0
fi

if ! jq -e . hooks/hooks.json >/dev/null 2>&1; then
  gate_fail "$GATE" "hooks/hooks.json is not valid JSON"
fi

# Schema is an object whose values are arrays of hook entries, keyed by event name.
# Validate every entry across every event array.
failed=0
total=0

while IFS= read -r line; do
  # Lines emitted by `jq` below as "<parent-event-key>\t<entry-json>".
  parent_event="${line%%$'\t'*}"
  entry_json="${line#*$'\t'}"
  total=$((total + 1))
  for key in name event matcher command enabledByDefault; do
    if [[ "$(echo "$entry_json" | jq -r ".$key // \"__MISSING__\"")" == "__MISSING__" ]]; then
      gate_warn "$GATE" "entry missing required key '$key': $entry_json"
      failed=$((failed + 1))
    fi
  done
  # Cross-validate that entry.event matches the parent object key
  declared_event=$(echo "$entry_json" | jq -r '.event // ""')
  if [[ -n "$declared_event" && "$declared_event" != "$parent_event" ]]; then
    gate_warn "$GATE" "entry under '$parent_event' declares event='$declared_event' (must match parent key)"
    failed=$((failed + 1))
  fi
  cmd=$(echo "$entry_json" | jq -r '.command // ""')
  # shellcheck disable=SC2016
  # We deliberately match the literal string ${CLAUDE_PLUGIN_ROOT}; not expanding it.
  if [[ "$cmd" != *'${CLAUDE_PLUGIN_ROOT}'* && "$cmd" != *'$CLAUDE_PLUGIN_ROOT'* ]]; then
    gate_warn "$GATE" "entry command must reference \${CLAUDE_PLUGIN_ROOT}: $cmd"
    failed=$((failed + 1))
  fi
  ebd_kind=$(echo "$entry_json" | jq -r '.enabledByDefault | type')
  if [[ "$ebd_kind" != "boolean" ]]; then
    gate_warn "$GATE" "entry enabledByDefault must be boolean, got $ebd_kind"
    failed=$((failed + 1))
  fi
done < <(jq -r 'to_entries[] | .key as $event | .value[]? | "\($event)\t\(tojson)"' hooks/hooks.json)

if [[ $total -eq 0 ]]; then
  gate_pass "$GATE" "hooks.json present but no entries yet (no-op)"
  exit 0
fi

if [[ $failed -gt 0 ]]; then
  gate_fail "$GATE" "$failed schema violations across $total entries"
fi

gate_pass "$GATE" "$total hook entries match hook-entry schema"
