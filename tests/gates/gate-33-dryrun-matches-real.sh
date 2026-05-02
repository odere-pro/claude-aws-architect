#!/usr/bin/env bash
# Gate 33: install.sh --copy followed by uninstall.sh --dry-run enumerates
# exactly the files uninstall.sh (no --dry-run) would remove. Asserted by
# diffing the two action streams.

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=33
INSTALL="$PLUGIN_ROOT/scripts/install.sh"
UNINSTALL="$PLUGIN_ROOT/scripts/uninstall.sh"

tmpdir=$(mktemp -d -t "claude-aws-architect-gate33.XXXXXX")
# shellcheck disable=SC2064
trap "rm -rf '$tmpdir'" EXIT INT TERM

CONSUMER_ROOT="$tmpdir" "$INSTALL" --copy >/dev/null 2>&1 || gate_fail "$GATE" "install.sh --copy failed"

dry="$tmpdir/dry.txt"
real="$tmpdir/real.txt"

# Capture stdout only — log lines on stderr are advisory and not part of the
# action contract.
CONSUMER_ROOT="$tmpdir" "$UNINSTALL" --dry-run > "$dry" 2>/dev/null
CONSUMER_ROOT="$tmpdir" "$UNINSTALL"           > "$real" 2>/dev/null

if diff "$dry" "$real" >/dev/null 2>&1; then
  count=$(wc -l < "$real" | tr -d ' ')
  gate_pass "$GATE" "uninstall.sh --dry-run matches real run ($count actions)"
else
  gate_fail "$GATE" "uninstall.sh --dry-run output differs from real run (see $tmpdir)"
fi
