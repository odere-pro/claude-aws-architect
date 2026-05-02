#!/usr/bin/env bash
# Transcript-replay harness for runtime gates 19–27.
#
# Executes each fixture, captures the tool-call trace, asserts against
# expected-* files, and exits non-zero on first mismatch. Snapshot updates
# require explicit --update-snapshots and a reviewer comment.
#
# v0.1.0 PR 3 ships skeleton-mode only:
#   - --validate-only (default): validates every fixture's files conform to
#     the schema documented in tests/transcripts/README.md. Does NOT execute
#     Claude Code. Exits 0 if all fixtures are well-formed.
#   - --execute: stubbed; lands in PR 18 with the orchestrator wiring.
#   - --update-snapshots: stubbed; same.
#
# Usage:
#   tests/run-transcripts.sh                           # validate every fixture
#   tests/run-transcripts.sh --fixture vibe-shallow    # filter to one
#   tests/run-transcripts.sh --keep-going              # don't stop at first failure
#   tests/run-transcripts.sh --execute                 # NotImplemented (PR 18)

set -euo pipefail
IFS=$'\n\t'

# Resolve plugin root and reuse the gate-script colour helpers via a sibling source.
HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$HARNESS_DIR/.." && pwd)"
# shellcheck source=SCRIPTDIR/gates/lib/common.sh
source "$HARNESS_DIR/gates/lib/common.sh"

MODE=validate
FIXTURE_FILTER=""
KEEP_GOING=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --validate-only) MODE=validate; shift ;;
    --execute) MODE=execute; shift ;;
    --update-snapshots) MODE=update; shift ;;
    --fixture) FIXTURE_FILTER="$2"; shift 2 ;;
    --keep-going) KEEP_GOING=1; shift ;;
    --help|-h)
      sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown arg: $1" >&2
      exit 64
      ;;
  esac
done

case "$MODE" in
  execute|update)
    gate_fail "19" "$MODE mode is not yet implemented; lands in PR 18 with the orchestrator wiring. Use --validate-only (default) for now."
    ;;
esac

cd "$PLUGIN_ROOT" || exit 1

fixtures=()
read_into fixtures < <(find tests/transcripts -mindepth 1 -maxdepth 1 -type d ! -name 'lib' ! -name '_*')

if [[ ${#fixtures[@]} -eq 0 ]]; then
  gate_warn "19" "no fixtures found under tests/transcripts/"
  exit 0
fi

# Validate one fixture; emits gate_warn on each issue, returns 0 if clean.
validate_fixture() {
  local dir=$1
  local name
  name=$(basename "$dir")
  local issues=0

  # 1. prompt.txt — required, non-empty
  if [[ ! -f "$dir/prompt.txt" ]]; then
    gate_warn "19" "$name: missing prompt.txt"
    issues=$((issues + 1))
  elif [[ ! -s "$dir/prompt.txt" ]]; then
    gate_warn "19" "$name: prompt.txt is empty"
    issues=$((issues + 1))
  fi

  # 2. expected-tools.jsonl — required; if non-empty, every line must be valid JSON
  #    with required fields {step, tool}; optional fields {server, fan_out_index}.
  if [[ ! -f "$dir/expected-tools.jsonl" ]]; then
    gate_warn "19" "$name: missing expected-tools.jsonl"
    issues=$((issues + 1))
  else
    local line_no=0
    while IFS= read -r line; do
      line_no=$((line_no + 1))
      [[ -z "$line" ]] && continue
      if ! echo "$line" | jq -e . >/dev/null 2>&1; then
        gate_warn "19" "$name: expected-tools.jsonl line $line_no is not valid JSON"
        issues=$((issues + 1))
        continue
      fi
      for field in step tool; do
        if [[ "$(echo "$line" | jq -r ".$field // empty")" == "" ]]; then
          gate_warn "19" "$name: expected-tools.jsonl line $line_no missing required field '$field'"
          issues=$((issues + 1))
        fi
      done
      # Type check for step
      if ! echo "$line" | jq -e '.step | type == "number"' >/dev/null 2>&1; then
        gate_warn "19" "$name: expected-tools.jsonl line $line_no: 'step' must be a number"
        issues=$((issues + 1))
      fi
    done < "$dir/expected-tools.jsonl"
  fi

  # 3. expected-artefacts.txt — required (may be empty)
  if [[ ! -f "$dir/expected-artefacts.txt" ]]; then
    gate_warn "19" "$name: missing expected-artefacts.txt (may be empty for shallow fixtures)"
    issues=$((issues + 1))
  fi

  # 4. expected-merge.json — optional; if present, must be valid JSON with required fields
  if [[ -f "$dir/expected-merge.json" ]]; then
    if ! jq -e . "$dir/expected-merge.json" >/dev/null 2>&1; then
      gate_warn "19" "$name: expected-merge.json is not valid JSON"
      issues=$((issues + 1))
    else
      for field in specialists open_questions priority_rules_applied; do
        if [[ "$(jq -r ".$field | type" "$dir/expected-merge.json")" != "array" ]]; then
          gate_warn "19" "$name: expected-merge.json '$field' must be an array"
          issues=$((issues + 1))
        fi
      done
    fi
  fi

  if [[ $issues -gt 0 ]]; then
    gate_warn "19" "$name: $issues schema violation(s)"
    return 1
  fi
  return 0
}

failed=()
for dir in "${fixtures[@]}"; do
  name=$(basename "$dir")
  if [[ -n "$FIXTURE_FILTER" && "$name" != "$FIXTURE_FILTER" ]]; then
    continue
  fi
  if validate_fixture "$dir"; then
    gate_pass "19" "$name: fixture schema valid"
  else
    failed+=("$name")
    if [[ $KEEP_GOING -eq 0 ]]; then
      gate_fail "19" "stopping at first failed fixture; pass --keep-going to continue"
    fi
  fi
done

if [[ ${#failed[@]} -gt 0 ]]; then
  gate_fail "19" "${#failed[@]} fixture(s) failed validation: ${failed[*]}"
fi

if [[ -n "$FIXTURE_FILTER" ]]; then
  matched_count=0
  for dir in "${fixtures[@]}"; do
    [[ "$(basename "$dir")" == "$FIXTURE_FILTER" ]] && matched_count=$((matched_count + 1))
  done
  if [[ $matched_count -eq 0 ]]; then
    gate_fail "19" "fixture filter '$FIXTURE_FILTER' matched no fixtures"
  fi
fi

gate_info "19" "executor mode (--execute / --update-snapshots) lands in PR 18"
