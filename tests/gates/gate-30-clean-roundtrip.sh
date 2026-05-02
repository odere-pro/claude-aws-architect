#!/usr/bin/env bash
# Gate 30: install.sh --symlink on a clean tree → uninstall.sh → tree state
# byte-identical to pre-install (asserted against a tar snapshot).

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=30
INSTALL="$PLUGIN_ROOT/scripts/install.sh"
UNINSTALL="$PLUGIN_ROOT/scripts/uninstall.sh"

workdir=$(mktemp -d -t "claude-aws-architect-gate30.XXXXXX")
# shellcheck disable=SC2064
trap "rm -rf '$workdir'" EXIT INT TERM

# Use one dir for the tree under test, another for snapshot files, so listing
# the tree doesn't see our own diagnostic output.
tree="$workdir/tree"
snaps="$workdir/snaps"
mkdir -p "$tree" "$snaps"

pre="$snaps/pre.list"
post="$snaps/post.list"
( cd "$tree" && find . -mindepth 1 | sort > "$pre" )

CONSUMER_ROOT="$tree" "$INSTALL" --symlink >/dev/null 2>&1 || gate_fail "$GATE" "install.sh failed"
CONSUMER_ROOT="$tree" "$UNINSTALL" >/dev/null 2>&1 || gate_fail "$GATE" "uninstall.sh failed"

( cd "$tree" && find . -mindepth 1 | sort > "$post" )

if diff "$pre" "$post" >/dev/null 2>&1; then
  gate_pass "$GATE" "clean tree byte-identical after install→uninstall"
else
  gate_fail "$GATE" "clean tree diverged after install→uninstall (see $workdir)"
fi
