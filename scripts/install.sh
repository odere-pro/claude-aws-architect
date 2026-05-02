#!/usr/bin/env bash
# install.sh — install claude-aws-architect into a consumer project's .claude/.
#
# Modes (mutually exclusive):
#   --symlink   (default) Create one symlink at .claude/plugins/claude-aws-architect
#               pointing at the plugin root. Cheapest to update.
#   --copy      Copy plugin trees (commands, agents, skills, rules, hooks, powers,
#               templates) into .claude/<dir>/. Files that already exist in the
#               consumer tree are NEVER overwritten — those slots stay consumer-owned.
#
# Idempotent: re-running with the same mode is a no-op (no errors, no duplicate writes).
# Logs every action to stderr and records each created path to a manifest file
# at .claude/.claude-aws-architect-installed.jsonl so uninstall.sh can reverse precisely.
#
# Flags:
#   --help      Print this header and exit 0.
#
# Exit codes (per SPEC §8.1):
#   0   OK
#   64  bad arg
#   65  target conflict (e.g. an existing symlink points at a different plugin root)

# shellcheck source=SCRIPTDIR/lib/common.sh disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

MODE="symlink"
for arg in "$@"; do
  case "$arg" in
    --symlink) MODE="symlink" ;;
    --copy)    MODE="copy" ;;
    --help|-h)
      sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      log_err "unknown arg: $arg"
      exit 64
      ;;
  esac
done

CLAUDE_DIR="$CONSUMER_ROOT/.claude"

# Trees we ship into the consumer .claude/ in --copy mode.
COPY_TREES=(commands agents skills rules hooks powers templates)

# Create a directory only if absent and record it in the manifest so uninstall
# can rmdir it later (only if still empty — consumer content is never touched).
ensure_dir_tracked() {
  local dir=$1
  if [[ ! -d "$CONSUMER_ROOT/$dir" ]]; then
    mkdir -p "$CONSUMER_ROOT/$dir"
    manifest_append dir "$dir"
    log_info "create dir $dir"
  fi
}

# Walk every parent of `dir` (e.g. .claude/plugins → .claude, .claude/plugins)
# and call ensure_dir_tracked in top-down order so the manifest captures the
# whole chain we created.
ensure_chain() {
  local dir=$1
  local parts=() acc=""
  IFS='/' read -r -a parts <<< "$dir"
  for p in "${parts[@]}"; do
    [[ -z "$p" ]] && continue
    if [[ -z "$acc" ]]; then acc="$p"; else acc="$acc/$p"; fi
    ensure_dir_tracked "$acc"
  done
}

install_symlink() {
  local target_rel=".claude/plugins/claude-aws-architect"
  local target_abs="$CONSUMER_ROOT/$target_rel"
  ensure_chain ".claude/plugins"

  if [[ -L "$target_abs" ]]; then
    local existing
    existing=$(readlink "$target_abs")
    if [[ "$existing" = "$PLUGIN_ROOT" ]]; then
      log_info "symlink already in place: $target_rel -> $PLUGIN_ROOT"
      return 0
    fi
    log_err "symlink at $target_rel points at $existing (expected $PLUGIN_ROOT)"
    exit 65
  fi
  if [[ -e "$target_abs" ]]; then
    log_err "target $target_rel exists and is not a symlink"
    exit 65
  fi
  ln -s "$PLUGIN_ROOT" "$target_abs"
  manifest_append symlink "$target_rel"
  log_ok "symlinked $target_rel -> $PLUGIN_ROOT"
}

install_copy() {
  local tree src dst rel d
  for tree in "${COPY_TREES[@]}"; do
    src="$PLUGIN_ROOT/$tree"
    [[ -d "$src" ]] || continue
    ensure_chain ".claude/$tree"
    # Track sub-directories first (so reverse-iteration in uninstall removes
    # leaves before parents).
    while IFS= read -r d; do
      rel=${d#"$src/"}
      [[ "$rel" = "$d" ]] && continue
      ensure_chain ".claude/$tree/$rel"
    done < <(find "$src" -mindepth 1 -type d)
    while IFS= read -r f; do
      rel=${f#"$src/"}
      dst="$CLAUDE_DIR/$tree/$rel"
      if [[ -e "$dst" ]]; then
        log_info "skip (consumer-owned) .claude/$tree/$rel"
        continue
      fi
      cp "$f" "$dst"
      manifest_append file ".claude/$tree/$rel"
      log_ok "copy .claude/$tree/$rel"
    done < <(find "$src" -type f)
  done
}

# Idempotency: in copy mode, manifest_append on a path that's already tracked
# would create a duplicate entry. Guard by reading current manifest into a
# lookup string before this run.
PRIOR_MANIFEST_PATHS=$(manifest_read | awk -F '\t' '{print $2}' | tr '\n' '|')
manifest_append() {
  local action=$1 path=$2
  case "|$PRIOR_MANIFEST_PATHS" in
    *"|$path|"*) return 0 ;;
  esac
  local manifest="$CONSUMER_ROOT/$MANIFEST_REL"
  mkdir -p "$(dirname "$manifest")"
  printf '{"action":"%s","path":"%s"}\n' "$action" "$path" >> "$manifest"
  PRIOR_MANIFEST_PATHS="$PRIOR_MANIFEST_PATHS$path|"
}

case "$MODE" in
  symlink) install_symlink ;;
  copy)    install_copy ;;
esac

log_ok "install complete (mode: $MODE)"
exit 0
