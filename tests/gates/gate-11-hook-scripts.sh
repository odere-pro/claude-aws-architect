#!/usr/bin/env bash
# Gate 11: every hook script under hooks/scripts/ matches §7.3 contract.
# Per SPEC §11.A gate 11 + §7.3.
# Required: header comment block, exit-code documentation, set -euo pipefail,
# IFS=$'\n\t', shellcheck-clean.

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=11

cd "$PLUGIN_ROOT" || exit 1

if [[ ! -d hooks/scripts ]]; then
  gate_pass "$GATE" "hooks/scripts/ does not exist yet (no-op)"
  exit 0
fi

scripts=()
read_into scripts < <(find hooks/scripts -maxdepth 1 -type f -name '*.sh')

if [[ ${#scripts[@]} -eq 0 ]]; then
  gate_pass "$GATE" "no hooks/scripts/*.sh yet (no-op)"
  exit 0
fi

failed=0
for s in "${scripts[@]}"; do
  if ! head -n 30 "$s" | grep -qE '^#.*(input|output|exit code)' -i; then
    gate_warn "$GATE" "$s: missing header comment block describing input/output/exit-codes"
    failed=$((failed + 1))
  fi
  if ! grep -q 'set -euo pipefail' "$s"; then
    gate_warn "$GATE" "$s: missing 'set -euo pipefail'"
    failed=$((failed + 1))
  fi
  if ! grep -q "IFS=\$'\\\\n\\\\t'" "$s" && ! grep -qE "IFS=" "$s"; then
    gate_warn "$GATE" "$s: missing IFS hardening"
    failed=$((failed + 1))
  fi
  if command -v shellcheck >/dev/null 2>&1; then
    if ! shellcheck "$s" >&2; then
      gate_warn "$GATE" "$s: shellcheck failed"
      failed=$((failed + 1))
    fi
  fi
done

if [[ $failed -gt 0 ]]; then
  gate_fail "$GATE" "$failed contract violations across ${#scripts[@]} hook scripts"
fi

gate_pass "$GATE" "${#scripts[@]} hook scripts match §7.3 contract"
