#!/usr/bin/env bash
# uninstall.sh — reverse install.sh by replaying the manifest in reverse.
#
# Reads .claude/.claude-aws-architect-installed.jsonl and for every recorded
# action removes exactly the path it created — never anything else. Files,
# directories, and symlinks created by install.sh are removed; pre-existing
# consumer files are untouched (they were never recorded). The manifest itself
# is removed last.
#
# Flags:
#   --dry-run   Print every action without performing it. Output is identical
#               in line content and order to a real run; gate-33 diffs the two.
#   --help      Print this header and exit 0.
#
# Exit codes (per SPEC §8.1):
#   0   OK
#   64  bad arg

# shellcheck source=SCRIPTDIR/lib/common.sh disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --help|-h)
      sed -n '2,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      log_err "unknown arg: $arg"
      exit 64
      ;;
  esac
done

manifest_path="$CONSUMER_ROOT/$MANIFEST_REL"
if [[ ! -f "$manifest_path" ]]; then
  log_info "no manifest at $MANIFEST_REL — nothing to uninstall"
  exit 0
fi

# Read manifest into two parallel arrays so we can iterate in reverse.
actions=()
paths=()
while IFS=$'\t' read -r a p; do
  actions+=("$a")
  paths+=("$p")
done < <(manifest_read)

# Build the set of paths the run will remove. A directory is treated as
# post-removal-empty when every entry it currently contains is either the
# manifest itself or another tracked path. This makes the action stream
# deterministic — independent of current filesystem state (so --dry-run
# matches a real run line-for-line, asserted by gate-33).
tracked_set=$'\n'
for p in "${paths[@]}"; do
  tracked_set+="$p"$'\n'
done
tracked_set+="$MANIFEST_REL"$'\n'

is_tracked() {
  local p=$1
  case "$tracked_set" in
    *$'\n'"$p"$'\n'*) return 0 ;;
  esac
  return 1
}

dir_post_empty() {
  local abs="$CONSUMER_ROOT/$1" entry rel_entry
  [[ -d "$abs" ]] || return 0
  for entry in "$abs"/* "$abs"/.[!.]*; do
    [[ -e "$entry" || -L "$entry" ]] || continue
    rel_entry="${entry#"$CONSUMER_ROOT/"}"
    is_tracked "$rel_entry" || return 1
  done
  return 0
}

emit_action() {
  local kind=$1 path=$2
  printf 'REMOVE %s %s\n' "$kind" "$path"
  [[ $DRY_RUN -eq 1 ]] && return 0
  case "$kind" in
    file)    rm -f "$CONSUMER_ROOT/$path" ;;
    symlink) rm -f "$CONSUMER_ROOT/$path" ;;
    dir)
      # Best-effort: if the consumer added content into a dir we created,
      # rmdir will fail; leave the dir in place and warn.
      if rmdir "$CONSUMER_ROOT/$path" 2>/dev/null; then
        :
      else
        log_warn "kept non-empty dir $path (consumer content present)"
      fi
      ;;
  esac
}

# Remove the manifest first so directories that contain only the manifest can
# be reported as post-empty in the reverse-iteration pass below. Both real and
# dry-run print this line at the same point so gate-33 sees identical output.
emit_action file "$MANIFEST_REL"

# Reverse iteration: leaves first, parents last.
i=${#actions[@]}
while (( i > 0 )); do
  i=$((i - 1))
  action=${actions[$i]}
  path=${paths[$i]}
  case "$action" in
    file|symlink) emit_action "$action" "$path" ;;
    dir)
      if dir_post_empty "$path"; then
        emit_action dir "$path"
      else
        printf 'KEEP   dir %s (non-empty; consumer content remains)\n' "$path"
      fi
      ;;
  esac
done

exit 0
