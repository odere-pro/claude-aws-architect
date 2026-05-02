#!/usr/bin/env bash
# Gate 32: install.sh --symlink followed by a second install.sh --symlink
# (re-install) — no errors, no duplicate writes, no lock contention.
# Idempotency assertion: the manifest after the second run is byte-identical
# to the manifest after the first.

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=32
INSTALL="$PLUGIN_ROOT/scripts/install.sh"
UNINSTALL="$PLUGIN_ROOT/scripts/uninstall.sh"

tmpdir=$(mktemp -d -t "claude-aws-architect-gate32.XXXXXX")
# shellcheck disable=SC2064
trap "rm -rf '$tmpdir'" EXIT INT TERM

manifest="$tmpdir/.claude/.claude-aws-architect-installed.jsonl"

CONSUMER_ROOT="$tmpdir" "$INSTALL" --symlink >/dev/null 2>&1 || gate_fail "$GATE" "first install.sh failed"
[[ -f "$manifest" ]] || gate_fail "$GATE" "manifest missing after first install"
cp "$manifest" "$tmpdir/manifest-1.jsonl"

CONSUMER_ROOT="$tmpdir" "$INSTALL" --symlink >/dev/null 2>&1 || gate_fail "$GATE" "second install.sh failed"
cp "$manifest" "$tmpdir/manifest-2.jsonl"

if diff "$tmpdir/manifest-1.jsonl" "$tmpdir/manifest-2.jsonl" >/dev/null 2>&1; then
  gate_pass "$GATE" "re-install produced no duplicate manifest writes"
else
  gate_fail "$GATE" "re-install produced duplicate manifest writes"
fi

# Cleanup so we leave no stale install behind.
CONSUMER_ROOT="$tmpdir" "$UNINSTALL" >/dev/null 2>&1 || true
