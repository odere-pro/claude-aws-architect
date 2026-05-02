#!/usr/bin/env bash
# Gate 6: every powers/*.power.json matches §9.1 schema.
# Per SPEC §11.A gate 6 + §9.1.
# Required keys: name, version, description, mcpServers[], skills[], hooks[], commands[].

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=06

cd "$PLUGIN_ROOT" || exit 1

if [[ ! -d powers ]]; then
  gate_pass "$GATE" "powers/ does not exist yet (no-op)"
  exit 0
fi

powers=()
read_into powers < <(find powers -maxdepth 1 -type f -name '*.power.json')

if [[ ${#powers[@]} -eq 0 ]]; then
  gate_pass "$GATE" "no powers/*.power.json yet (no-op)"
  exit 0
fi

failed=0
for p in "${powers[@]}"; do
  if ! jq -e . "$p" >/dev/null 2>&1; then
    gate_warn "$GATE" "$p: invalid JSON"
    failed=$((failed + 1))
    continue
  fi

  # Required scalar keys
  for key in name version description; do
    if [[ "$(jq -r ".$key // \"\"" "$p")" == "" ]]; then
      gate_warn "$GATE" "$p: missing required key '$key'"
      failed=$((failed + 1))
    fi
  done

  # Required array keys (non-empty)
  for key in mcpServers skills hooks commands; do
    kind=$(jq -r ".$key | type" "$p")
    if [[ "$kind" != "array" ]]; then
      gate_warn "$GATE" "$p: '$key' must be an array, got $kind"
      failed=$((failed + 1))
    fi
  done

  # File-name vs name field consistency
  expected_name=$(basename "$p" .power.json)
  actual_name=$(jq -r '.name' "$p")
  if [[ "$expected_name" != "$actual_name" ]]; then
    gate_warn "$GATE" "$p: name '$actual_name' does not match filename '$expected_name'"
    failed=$((failed + 1))
  fi
done

if [[ $failed -gt 0 ]]; then
  gate_fail "$GATE" "$failed schema violations across ${#powers[@]} power files"
fi

gate_pass "$GATE" "${#powers[@]} power files match §9.1 schema"
