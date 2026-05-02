#!/usr/bin/env bash
# aws-test-coverage — PostToolUse hook that surfaces sibling test files for
# AWS-touching implementation writes. Flags missing tests; flags stale tests
# whose mtime is older than the implementation file's mtime.
#
# Input (stdin, JSON, from Claude Code):
#   { "tool_name": "Write|Edit|MultiEdit",
#     "tool_input": { "file_path": "...", ... } }
#
# Output (stdout, JSON): hook decision via dispatcher (always "allow").
# Output (stderr): one human-readable line per finding (no test file
# present, stale test file, candidate test paths not found).
#
# Exit codes:
#   0  always — advisory hook never blocks. Findings live on stderr.
#
# Scope: a file is "AWS-touching implementation" when it satisfies all of:
#   - extension is `.ts` / `.js` / `.py`;
#   - basename does NOT itself end in `.spec.<ext>` / `.test.<ext>` /
#     `_test.py` / `test_*.py` (we don't recurse into test files);
#   - the payload (or, when the file already exists on disk, the file
#     contents) mentions an AWS SDK import, an `aws-cdk-lib` import, an
#     `awscli` invocation, or an `aws_*` symbol — heuristic but cheap.
#
# Test path candidates checked in order (the first existing path wins):
#   <name>.spec.<ext>            (sibling — Jest/Vitest convention)
#   <name>.test.<ext>            (sibling — Jest/Vitest alternate)
#   __tests__/<name>.spec.<ext>  (sibling __tests__ dir)
#   tests/<name>.spec.<ext>      (sibling tests/ dir)
#   test_<name>.py               (Python pytest convention)
#   tests/test_<name>.py         (Python pytest alternate)
#
# Forbidden in this script: running the test suite, invoking jest/pytest,
# touching the network. The hook surfaces the path gap; running the tests
# is a separate decision.

set -euo pipefail
IFS=$'\n\t'

export HOOK_NAME=aws-test-coverage

# shellcheck source=SCRIPTDIR/lib/dispatcher.sh disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib/dispatcher.sh"

hook_read_input

TOOL=$(hook_field '.tool_name')
case "$TOOL" in
  Write|Edit|MultiEdit) ;;
  *)
    hook_allow "tool $TOOL not in test-coverage scope"
    ;;
esac

PATH_VAL=$(hook_field '.tool_input.file_path')
if [[ -z "$PATH_VAL" ]]; then
  hook_allow "no file path in tool input"
fi

base=${PATH_VAL##*/}
ext=""
case "$base" in
  *.ts) ext=ts ;;
  *.tsx) ext=tsx ;;
  *.js) ext=js ;;
  *.jsx) ext=jsx ;;
  *.py) ext=py ;;
  *)
    hook_allow "extension not in scope: $base"
    ;;
esac

# Skip if the file IS already a test.
case "$base" in
  *.spec.ts|*.spec.tsx|*.spec.js|*.spec.jsx|*.test.ts|*.test.tsx|*.test.js|*.test.jsx) hook_allow "file is itself a test: $base" ;;
  *_test.py|test_*.py) hook_allow "file is itself a test: $base" ;;
esac

# Check whether the file looks AWS-touching. Inspect the just-written
# payload first; fall back to the on-disk file if jq returned empty.
payload=""
case "$TOOL" in
  Write)
    payload=$(hook_field '.tool_input.content')
    ;;
  Edit)
    payload=$(hook_field '.tool_input.new_string')
    ;;
  MultiEdit)
    payload=$(hook_field '[.tool_input.edits[]?.new_string] | join("\n")')
    ;;
esac
if [[ -z "$payload" && -r "$PATH_VAL" ]]; then
  payload=$(cat "$PATH_VAL" 2>/dev/null || printf '')
fi
if [[ -z "$payload" ]]; then
  hook_allow "no payload available to classify"
fi

aws_touching=0
if printf '%s' "$payload" | grep -E -q "@aws-sdk/|from[[:space:]]+aws-cdk-lib|import[[:space:]]+aws_cdk|import[[:space:]]+boto3|from[[:space:]]+boto3|aws_iam\\.|aws_lambda\\.|aws_s3\\.|aws_dynamodb\\.|aws-cli|awscli"; then
  aws_touching=1
fi

if [[ $aws_touching -eq 0 ]]; then
  hook_allow "file does not appear AWS-touching"
fi

# Compute candidate test paths.
dir=${PATH_VAL%/*}
[[ "$dir" == "$PATH_VAL" ]] && dir="."
stem=${base%.*}

candidates=()
case "$ext" in
  ts|tsx|js|jsx)
    candidates+=("$dir/$stem.spec.$ext")
    candidates+=("$dir/$stem.test.$ext")
    candidates+=("$dir/__tests__/$stem.spec.$ext")
    candidates+=("$dir/__tests__/$stem.test.$ext")
    candidates+=("$dir/tests/$stem.spec.$ext")
    candidates+=("$dir/tests/$stem.test.$ext")
    ;;
  py)
    candidates+=("$dir/test_$stem.py")
    candidates+=("$dir/tests/test_$stem.py")
    candidates+=("tests/test_$stem.py")
    ;;
esac

found=""
for c in "${candidates[@]}"; do
  if [[ -f "$c" ]]; then
    found="$c"
    break
  fi
done

if [[ -z "$found" ]]; then
  hook_log "INFO" "AWS-touching write at $PATH_VAL has no sibling test"
  hook_log "INFO" "candidate paths searched (none found):"
  for c in "${candidates[@]}"; do
    hook_log "INFO" "  - $c"
  done
  hook_allow "advisory: missing test for AWS-touching $PATH_VAL"
fi

# Stale-test check: if the implementation file exists on disk and is
# newer than the test file, surface a stale-test finding. mtime granularity
# is one second; we use `-nt` which short-circuits to false on equal times.
stale=0
if [[ -f "$PATH_VAL" ]]; then
  if [[ "$PATH_VAL" -nt "$found" ]]; then
    stale=1
  fi
fi

if [[ $stale -eq 1 ]]; then
  hook_log "INFO" "AWS-touching write at $PATH_VAL: test exists at $found but is older than the implementation"
  hook_log "INFO" "review the test against this change before merging"
  hook_allow "advisory: stale test detected for $PATH_VAL"
fi

hook_log "INFO" "AWS-touching write at $PATH_VAL: matching test at $found (test mtime ≥ impl mtime)"
hook_allow "test present and not stale for $PATH_VAL"
