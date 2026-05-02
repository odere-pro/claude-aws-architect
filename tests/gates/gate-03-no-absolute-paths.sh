#!/usr/bin/env bash
# Gate 3: no absolute paths anywhere in claude-aws-architect/.
# Excludes: docs/ (planning docs may quote example paths), .git/, tests/gates/cache/.
# Tilde-prefixed paths (e.g. ~/.claude/...) are portable and NOT flagged.

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=03

# Patterns that indicate true absolute paths (not portable)
PATTERNS=(
  '/Users/'
  '/home/'
  '/opt/homebrew/'
  '/opt/local/'
  '/usr/local/bin/'
  '/private/var/'
  '/private/tmp/'
)

cd "$PLUGIN_ROOT" || exit 1

# Build grep -e args from patterns
grep_args=()
for p in "${PATTERNS[@]}"; do
  grep_args+=(-e "$p")
done

# Files in scope: everything except docs/ (planning docs may quote example
# paths), .git/, tests/gates/ (the gate scripts themselves contain pattern
# strings that match these patterns by definition), node_modules/, .venv/.
# Other test directories (tests/transcripts/, tests/install/ from later PRs)
# ARE scanned — fixtures with leaked absolute paths must fail.
files=()
read_into files < <(find . \
  -path ./.git -prune -o \
  -path ./docs -prune -o \
  -path ./tests/gates -prune -o \
  -path ./node_modules -prune -o \
  -path ./.venv -prune -o \
  -type f \
  \( -name '*.md' -o -name '*.json' -o -name '*.sh' -o -name '*.yml' -o -name '*.yaml' -o -name '*.jsonc' -o -name '*.txt' -o -name 'LICENSE' \) \
  -print)

if [[ ${#files[@]} -eq 0 ]]; then
  gate_pass "$GATE" "no files to scan"
  exit 0
fi

# Run grep across all files; collect hits
hits=$(grep -nH "${grep_args[@]}" "${files[@]}" 2>/dev/null || true)

if [[ -n "$hits" ]]; then
  while IFS= read -r line; do
    gate_warn "$GATE" "absolute path: $line"
  done <<< "$hits"
  gate_fail "$GATE" "found absolute paths in plugin tree (see WARN lines above)"
fi

gate_pass "$GATE" "scanned ${#files[@]} files; no absolute paths"
