#!/usr/bin/env bash
# Gate 31: install.sh --symlink on a dirty tree containing pre-existing
# .claude/specs/, .claude/steering/, .claude/hooks/ with consumer-authored
# content → uninstall.sh → all consumer-authored content present, byte-
# identical (asserted against a tar snapshot of the dirty subset).

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=31
INSTALL="$PLUGIN_ROOT/scripts/install.sh"
UNINSTALL="$PLUGIN_ROOT/scripts/uninstall.sh"

tmpdir=$(mktemp -d -t "claude-aws-architect-gate31.XXXXXX")
# shellcheck disable=SC2064
trap "rm -rf '$tmpdir'" EXIT INT TERM

# Plant pre-existing consumer-authored content.
mkdir -p "$tmpdir/.claude/specs" "$tmpdir/.claude/steering" "$tmpdir/.claude/hooks"
printf 'consumer spec body\n' > "$tmpdir/.claude/specs/feature-a.md"
printf 'consumer steering body\n' > "$tmpdir/.claude/steering/aws-conventions.md"
printf '#!/usr/bin/env bash\necho consumer hook\n' > "$tmpdir/.claude/hooks/local-hook.sh"
chmod +x "$tmpdir/.claude/hooks/local-hook.sh"

pre_tar="$tmpdir/pre-dirty.tar"
( cd "$tmpdir" && tar -cf "$pre_tar" .claude/specs .claude/steering .claude/hooks )

CONSUMER_ROOT="$tmpdir" "$INSTALL" --symlink >/dev/null 2>&1 || gate_fail "$GATE" "install.sh failed"
CONSUMER_ROOT="$tmpdir" "$UNINSTALL" >/dev/null 2>&1 || gate_fail "$GATE" "uninstall.sh failed"

post_tar="$tmpdir/post-dirty.tar"
( cd "$tmpdir" && tar -cf "$post_tar" .claude/specs .claude/steering .claude/hooks )

if diff "$pre_tar" "$post_tar" >/dev/null 2>&1; then
  gate_pass "$GATE" "dirty-tree consumer content preserved byte-identical"
else
  gate_fail "$GATE" "consumer content diverged after install→uninstall (see $tmpdir)"
fi
