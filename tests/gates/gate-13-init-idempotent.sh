#!/usr/bin/env bash
# Gate 13: re-running init.sh is idempotent — no errors, no duplicate writes.
# Asserted by snapshotting the consumer .claude/ tree before and after a
# second invocation; the diff must be empty.

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=13
SCRIPT="$PLUGIN_ROOT/scripts/init.sh"

[[ -x "$SCRIPT" ]] || gate_fail "$GATE" "scripts/init.sh missing or not executable"

tmpdir=$(mktemp -d -t "claude-aws-architect-gate13.XXXXXX")
# shellcheck disable=SC2064
trap "rm -rf '$tmpdir'" EXIT INT TERM

# init.sh execs doctor.sh at the end; doctor's exit code is environment-
# dependent (no AWS creds in CI), so we only care about the side-effects on
# .claude/. Force exit-status of init to be ignored for this gate.
set +e
CONSUMER_ROOT="$tmpdir" "$SCRIPT" --profile gate13 --region us-east-1 >/dev/null 2>&1
CONSUMER_ROOT="$tmpdir" "$SCRIPT" --profile gate13 --region us-east-1 >/dev/null 2>&1
set -e

snap1="$tmpdir/.snap1"
mkdir -p "$snap1"
cp -R "$tmpdir/.claude" "$snap1/" 2>/dev/null || true

set +e
CONSUMER_ROOT="$tmpdir" "$SCRIPT" --profile gate13 --region us-east-1 >/dev/null 2>&1
set -e

if diff -r "$snap1/.claude" "$tmpdir/.claude" >/dev/null 2>&1; then
  gate_pass "$GATE" "init.sh idempotent across re-runs"
else
  gate_fail "$GATE" "init.sh produced different .claude/ contents on re-run"
fi
