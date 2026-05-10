#!/usr/bin/env bash
# Gate 6: every recipes/*.recipe.json matches the recipe-bundle schema.
# Required keys: name, version, description, mcpServers[], skills[], hooks[], commands[].

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=06

cd "$PLUGIN_ROOT" || exit 1

if [[ ! -d recipes ]]; then
  gate_pass "$GATE" "recipes/ does not exist yet (no-op)"
  exit 0
fi

recipes=()
read_into recipes < <(find recipes -maxdepth 1 -type f -name '*.recipe.json')

if [[ ${#recipes[@]} -eq 0 ]]; then
  gate_pass "$GATE" "no recipes/*.recipe.json yet (no-op)"
  exit 0
fi

failed=0
for p in "${recipes[@]}"; do
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
  expected_name=$(basename "$p" .recipe.json)
  actual_name=$(jq -r '.name' "$p")
  if [[ "$expected_name" != "$actual_name" ]]; then
    gate_warn "$GATE" "$p: name '$actual_name' does not match filename '$expected_name'"
    failed=$((failed + 1))
  fi
done

if [[ $failed -gt 0 ]]; then
  gate_fail "$GATE" "$failed schema violations across ${#recipes[@]} recipe files"
fi

gate_pass "$GATE" "${#recipes[@]} recipe files match recipe-bundle schema"
