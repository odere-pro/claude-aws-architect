#!/usr/bin/env bash
# Gate 4: shellcheck clean across every bash script.

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=04

command -v shellcheck >/dev/null 2>&1 || gate_fail "$GATE" "shellcheck not installed (install via brew/apt)"

cd "$PLUGIN_ROOT" || exit 1

scripts=()
read_into scripts < <(find . \
  -path ./.git -prune -o \
  -path ./node_modules -prune -o \
  -type f -name '*.sh' -print)

if [[ ${#scripts[@]} -eq 0 ]]; then
  gate_pass "$GATE" "no .sh files yet (no-op)"
  exit 0
fi

failed=0
for script in "${scripts[@]}"; do
  if ! shellcheck -x "$script" >&2; then
    failed=$((failed + 1))
  fi
done

if [[ $failed -gt 0 ]]; then
  gate_fail "$GATE" "$failed of ${#scripts[@]} scripts failed shellcheck"
fi

gate_pass "$GATE" "${#scripts[@]} scripts shellcheck-clean"
