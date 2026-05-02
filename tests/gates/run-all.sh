#!/usr/bin/env bash
# Run every deterministic gate in tests/gates/, in numerical order.
# Per SPEC §11.A. Exits 0 only if every gate passes; non-zero on first
# failure (unless --keep-going is passed).
#
# Gates 1 (doctor.sh) and 13 (init.sh idempotency) are deferred until PR 27,
# when those scripts land. They are skipped here with an INFO line.

set -euo pipefail
IFS=$'\n\t'

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

KEEP_GOING=0
for arg in "$@"; do
  case "$arg" in
    --keep-going) KEEP_GOING=1 ;;
    --help|-h)
      cat <<'EOF'
Usage: run-all.sh [--keep-going]

Runs every gate-NN-*.sh script in numerical order. By default exits non-zero
on the first failure. With --keep-going, runs all gates and exits non-zero
only if any failed.

Gates 1 and 13 are deferred to PR 27 (depend on init.sh / doctor.sh).
EOF
      exit 0
      ;;
    *)
      echo "unknown arg: $arg" >&2
      exit 64
      ;;
  esac
done

cd "$PLUGIN_ROOT" || exit 1

gates=()
read_into gates < <(find tests/gates -maxdepth 1 -type f -name 'gate-*.sh' | sort)

if [[ ${#gates[@]} -eq 0 ]]; then
  echo "No gate scripts found under tests/gates/" >&2
  exit 1
fi

# Note deferred gates
gate_info "00" "gate-01 (doctor.sh exits 0): DEFERRED — lands with PR 27"
gate_info "00" "gate-13 (init.sh idempotency): DEFERRED — lands with PR 27"

failed_gates=()
for gate in "${gates[@]}"; do
  if ! bash "$gate"; then
    failed_gates+=("$gate")
    if [[ $KEEP_GOING -eq 0 ]]; then
      printf '\n%sStopping at first failure. Use --keep-going to run remaining gates.%s\n' "$C_RED" "$C_RESET" >&2
      exit 1
    fi
  fi
done

if [[ ${#failed_gates[@]} -gt 0 ]]; then
  printf '\n%s%d gate(s) failed:%s\n' "$C_RED" "${#failed_gates[@]}" "$C_RESET" >&2
  for g in "${failed_gates[@]}"; do
    printf '  - %s\n' "$g" >&2
  done
  exit 1
fi

printf '\n%sAll deterministic gates passed.%s\n' "$C_GREEN" "$C_RESET" >&2
