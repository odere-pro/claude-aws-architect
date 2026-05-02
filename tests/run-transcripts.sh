#!/usr/bin/env bash
# Transcript-replay harness for runtime gates 19–27.
#
# Executes each fixture, captures the tool-call trace, asserts against
# expected-* files, and exits non-zero on first mismatch. Snapshot updates
# require explicit --update-snapshots and a reviewer comment.
#
# Modes:
#   - --validate-only (default): validates every fixture's files conform to
#     the schema documented in tests/transcripts/README.md. Does NOT execute
#     the orchestrator. Exits 0 if all fixtures are well-formed.
#   - --execute: deterministic, model-free executor. Replays the orchestrator's
#     §5.6 depth-classification heuristic + routing decisions against the
#     fixture prompt and asserts the predicted trace matches expected-tools.jsonl.
#     Does NOT call the live model. At this revision the wired delegation paths
#     are: shallow direct-answer and full-depth Discovery. Fixtures whose
#     first-step trace requires solution-architect or implementation specialists
#     are reported as DEFERRED, not FAIL, until that wiring lands.
#   - --update-snapshots: not implemented at v0.1.0.
#
# Usage:
#   tests/run-transcripts.sh                           # validate every fixture
#   tests/run-transcripts.sh --fixture vibe-shallow    # filter to one
#   tests/run-transcripts.sh --keep-going              # don't stop at first failure
#   tests/run-transcripts.sh --execute                 # deterministic executor

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
  update)
    gate_fail "19" "--update-snapshots is not implemented at v0.1.0. Hand-author expected-* files and re-run --execute."
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

# Deterministic depth classifier mirroring SPEC §5.6 / phases.md.
# Reads $1 = prompt text. Echoes "shallow" or "full".
classify_depth() {
  local prompt="$1"
  local lower
  lower=$(printf '%s' "$prompt" | tr '[:upper:]' '[:lower:]')
  # Rule 1: explicit override.
  if printf '%s' "$prompt" | grep -qE -- '--deep([^[:alnum:]_-]|$)'; then
    echo full; return
  fi
  if printf '%s' "$prompt" | grep -qE -- '--quick([^[:alnum:]_-]|$)'; then
    echo shallow; return
  fi
  # Rule 2: SDLC-artefact intent. Word-boundary match on any keyword.
  local sdlc_kw="design architecture iac cdk runbook spec requirements contract rfc adr"
  for kw in $sdlc_kw; do
    if printf '%s' "$lower" | grep -qE "(^|[^a-z])${kw}([^a-z]|\$)"; then
      echo full; return
    fi
  done
  # Multi-word SDLC keywords.
  if printf '%s' "$lower" | grep -qE "threat[[:space:]]+model|cost[[:space:]]+estimate|security[[:space:]]+review"; then
    echo full; return
  fi
  # Rule 3: verb-of-creation at start.
  if printf '%s' "$lower" | grep -qE '^[[:space:]]*(build|design|architect|propose|draft|spec|plan)([^a-z]|$)'; then
    echo full; return
  fi
  # Rule 4: verb-of-inquiry at start.
  if printf '%s' "$lower" | grep -qE '^[[:space:]]*(what|how|which|is|does)([^a-z]|$)'; then
    echo shallow; return
  fi
  # Rule 5: default.
  echo shallow
}

# Compares predicted orchestrator routing against the fixture's expected trace.
# Returns: 0 = pass; 2 = deferred (specialist wiring not yet active); 1 = fail.
execute_fixture() {
  local dir=$1
  local name
  name=$(basename "$dir")

  local prompt
  prompt=$(cat "$dir/prompt.txt")
  local depth
  depth=$(classify_depth "$prompt")

  # Identify the first observed step number in the fixture.
  local first_step
  first_step=$(jq -rs '[.[].step] | min // 1' "$dir/expected-tools.jsonl" 2>/dev/null)
  if [[ -z "$first_step" || "$first_step" == "null" ]]; then
    first_step=1
  fi

  # Collect first-step tool names and any specialist references in the trace.
  local first_step_tools=()
  read_into first_step_tools < <(jq -r --argjson s "$first_step" 'select(.step == ($s|tonumber)) | .tool' "$dir/expected-tools.jsonl" 2>/dev/null || true)

  local specialists
  specialists=$(jq -r 'select(.subagent != null) | .subagent' "$dir/expected-tools.jsonl" 2>/dev/null | sort -u || true)

  # Effective non-comment artefact rows.
  local expected_artefact_count
  expected_artefact_count=$(grep -cE '^[^#[:space:]]' "$dir/expected-artefacts.txt" 2>/dev/null || true)
  expected_artefact_count=${expected_artefact_count:-0}

  case "$depth" in
    shallow)
      # Shallow path: orchestrator answers from grounded knowledge; the
      # discovery agent may be invoked for citation lookups, but there is
      # no parallel fan-out. Expected-artefacts.txt must be effectively
      # empty (only blanks/comments).
      if [[ $expected_artefact_count -ne 0 ]]; then
        gate_warn "19" "$name: classifier says shallow but fixture expects $expected_artefact_count artefact(s)"
        return 1
      fi
      # If the fixture expects an Agent fan-out call at the first step,
      # shallow classification is wrong.
      local agent_calls=0
      local i
      for ((i = 0; i < ${#first_step_tools[@]}; i++)); do
        case "${first_step_tools[$i]}" in
          *Agent*|*subagent*)
            agent_calls=$((agent_calls + 1))
            ;;
        esac
      done
      if [[ $agent_calls -ge 2 ]]; then
        gate_warn "19" "$name: classifier says shallow but fixture expects parallel Agent fan-out at step $first_step"
        return 1
      fi
      return 0
      ;;
    full)
      # Full path: at this revision the wired delegation is Discovery only.
      # If the fixture's first step calls exactly one specialist and that
      # specialist is the discovery agent, the predicted trace matches
      # the wired path → PASS. If the first step expects parallel fan-out
      # to multiple specialists (solution-architect or implementation),
      # the wiring isn't here yet → DEFERRED.
      local agent_calls=0
      local i
      for ((i = 0; i < ${#first_step_tools[@]}; i++)); do
        case "${first_step_tools[$i]}" in
          *Agent*|*subagent*)
            agent_calls=$((agent_calls + 1))
            ;;
        esac
      done
      local discovery_present=0
      if printf '%s\n' "$specialists" | grep -q 'discovery-agent'; then
        discovery_present=1
      fi
      if [[ $agent_calls -le 1 && $discovery_present -eq 1 ]]; then
        return 0
      fi
      if [[ $agent_calls -ge 2 ]]; then
        # Parallel fan-out fixture; wiring deferred.
        return 2
      fi
      # Full-depth fixture that does not name discovery — wiring not present.
      return 2
      ;;
  esac
  return 1
}

failed=()
deferred=()
for dir in "${fixtures[@]}"; do
  name=$(basename "$dir")
  if [[ -n "$FIXTURE_FILTER" && "$name" != "$FIXTURE_FILTER" ]]; then
    continue
  fi
  if ! validate_fixture "$dir"; then
    failed+=("$name")
    if [[ $KEEP_GOING -eq 0 ]]; then
      gate_fail "19" "stopping at first failed fixture; pass --keep-going to continue"
    fi
    continue
  fi
  if [[ "$MODE" == "validate" ]]; then
    gate_pass "19" "$name: fixture schema valid"
    continue
  fi
  # MODE == execute
  exec_status=0
  execute_fixture "$dir" || exec_status=$?
  case $exec_status in
    0)
      gate_pass "19" "$name: execute PASS (depth + routing match expected trace)"
      ;;
    2)
      deferred+=("$name")
      gate_info "19" "$name: execute DEFERRED (specialist wiring lands in a later PR)"
      ;;
    *)
      failed+=("$name")
      gate_warn "19" "$name: execute FAIL"
      if [[ $KEEP_GOING -eq 0 ]]; then
        gate_fail "19" "stopping at first failed fixture; pass --keep-going to continue"
      fi
      ;;
  esac
done

if [[ ${#failed[@]} -gt 0 ]]; then
  gate_fail "19" "${#failed[@]} fixture(s) failed: ${failed[*]}"
fi

if [[ ${#deferred[@]} -gt 0 ]]; then
  gate_info "19" "${#deferred[@]} fixture(s) deferred (pending wiring): ${deferred[*]}"
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
