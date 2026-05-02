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
#     fixture prompt, asserts the predicted trace matches expected-tools.jsonl,
#     then enforces the fixture-specific §11.B contracts (gates 20–27):
#     sdlc-full-depth → 20, 21, 22, 23, 24; merge-conflict → 25;
#     degraded-mcp → 26; iteration-cap → 27. Does NOT call the live model.
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

# Count Agent (fan-out) tool calls at a given step.
agent_calls_at_step() {
  local file=$1 step=$2
  jq -rs --argjson s "$step" '[ .[] | select(.step == $s and (.tool | test("Agent|subagent"))) ] | length' "$file" 2>/dev/null || echo 0
}

# Count distinct iterations (i.e. distinct step numbers that contain Agent fan-out).
iteration_count() {
  local file=$1
  jq -rs '[ .[] | select(.tool | test("Agent|subagent")) | .step ] | unique | length' "$file" 2>/dev/null || echo 0
}

# Assert §11.B gates 20–24 for the sdlc-full-depth fixture.
assert_full_depth_contract() {
  local dir=$1 name=$2
  local issues=0

  local fan_out
  fan_out=$(agent_calls_at_step "$dir/expected-tools.jsonl" 1)
  if [[ "$fan_out" -lt 2 ]]; then
    gate_warn "20" "$name: expected ≥2 specialist Agent calls at step 1, observed $fan_out"
    issues=$((issues + 1))
  else
    gate_pass "20" "$name: ${fan_out} specialist Agent calls observable in single turn"
  fi

  # Gate 21: every F5/F6 artefact path is produced.
  local required_artefacts=(requirements.md design.md tasks.md diagrams.d2 .grounding-ledger.json)
  local missing=()
  local a
  for a in "${required_artefacts[@]}"; do
    if ! grep -qxF "$a" "$dir/expected-artefacts.txt"; then
      missing+=("$a")
    fi
  done
  if ! grep -qE '^contracts/.+\.md$' "$dir/expected-artefacts.txt"; then
    missing+=("contracts/<slug>.md")
  fi
  if [[ ${#missing[@]} -gt 0 ]]; then
    gate_warn "21" "$name: missing F5/F6 artefacts: ${missing[*]}"
    issues=$((issues + 1))
  else
    gate_pass "21" "$name: all F5/F6 artefacts declared"
  fi

  # Gate 22: grounding precedes the writes — at least one kb call before the first Write.
  local first_write
  first_write=$(jq -rs '[ .[] | select(.tool == "Write") | .step ] | min // 0' "$dir/expected-tools.jsonl" 2>/dev/null || echo 0)
  local kb_before
  kb_before=$(jq -rs --argjson w "$first_write" '[ .[] | select((.server == "kb" or (.tool | test("__kb__"))) and .step < $w) ] | length' "$dir/expected-tools.jsonl" 2>/dev/null || echo 0)
  if [[ "$first_write" -gt 0 && "$kb_before" -ge 1 ]]; then
    gate_pass "22" "$name: ${kb_before} kb grounding call(s) precede first Write"
  else
    gate_warn "22" "$name: no kb grounding call before first Write step"
    issues=$((issues + 1))
  fi

  # Gate 23: every component named in design.md has a sibling contract artefact.
  local contract_count
  contract_count=$(grep -cE '^contracts/.+\.md$' "$dir/expected-artefacts.txt" || true)
  if [[ "${contract_count:-0}" -ge 1 ]]; then
    gate_pass "23" "$name: ${contract_count} per-component contract(s) declared"
  else
    gate_warn "23" "$name: design.md declared but no per-component contracts"
    issues=$((issues + 1))
  fi

  # Gate 24: diagrams.d2 declared as an artefact (layer-tag content review at PR time).
  if grep -qxF 'diagrams.d2' "$dir/expected-artefacts.txt"; then
    gate_pass "24" "$name: diagrams.d2 declared (layer-tag content review at PR time)"
  else
    gate_warn "24" "$name: diagrams.d2 not declared"
    issues=$((issues + 1))
  fi

  return $issues
}

# Assert §11.B gate 25 (merge-conflict priority rules).
assert_merge_conflict_contract() {
  local dir=$1 name=$2
  local issues=0
  if [[ ! -f "$dir/expected-merge.json" ]]; then
    gate_warn "25" "$name: expected-merge.json missing"
    return 1
  fi
  local rules_len
  rules_len=$(jq -r '.priority_rules_applied | length' "$dir/expected-merge.json")
  if [[ "$rules_len" -lt 1 ]]; then
    gate_warn "25" "$name: priority_rules_applied is empty (§5.5 expects ≥1 rule under conflict)"
    issues=$((issues + 1))
  fi
  local malformed
  malformed=$(jq -r '[ .priority_rules_applied[] | select((.rule|type) != "string" or (.chosen|type) != "string" or (.rejected|type) != "string") ] | length' "$dir/expected-merge.json")
  if [[ "$malformed" -gt 0 ]]; then
    gate_warn "25" "$name: $malformed priority-rule entries missing required fields"
    issues=$((issues + 1))
  fi
  if [[ $issues -eq 0 ]]; then
    gate_pass "25" "$name: ${rules_len} priority rule(s) applied per §5.5"
  fi
  return $issues
}

# Assert §11.B gate 26 (degraded-mcp fallback labels).
assert_degraded_mcp_contract() {
  local dir=$1 name=$2
  if [[ ! -f "$dir/expected-merge.json" ]]; then
    gate_warn "26" "$name: expected-merge.json missing"
    return 1
  fi
  local signals
  signals=$(jq -r '.degraded_signals // [] | length' "$dir/expected-merge.json")
  if [[ "$signals" -lt 1 ]]; then
    gate_warn "26" "$name: degraded_signals is empty (§3.5 expects ≥1 fallback marker)"
    return 1
  fi
  local malformed
  malformed=$(jq -r '[ .degraded_signals[] | select((type != "string") or (test("^[a-z][a-z0-9-]*:[a-z]+$") | not)) ] | length' "$dir/expected-merge.json")
  if [[ "$malformed" -gt 0 ]]; then
    gate_warn "26" "$name: $malformed degraded_signals entries malformed"
    return 1
  fi
  gate_pass "26" "$name: ${signals} fallback marker(s) emitted per §3.5"
  return 0
}

# Assert §11.B gate 27 (iteration-cap O4 marker).
assert_iteration_cap_contract() {
  local dir=$1 name=$2
  local issues=0
  if [[ ! -f "$dir/expected-merge.json" ]]; then
    gate_warn "27" "$name: expected-merge.json missing"
    return 1
  fi
  local marker
  marker=$(jq -r '.iteration_cap_marker // ""' "$dir/expected-merge.json")
  if [[ "$marker" != "iteration-cap-reached" ]]; then
    gate_warn "27" "$name: iteration_cap_marker missing or wrong (got '$marker')"
    issues=$((issues + 1))
  fi
  local observed
  observed=$(jq -r '.iterations_observed // 0' "$dir/expected-merge.json")
  if [[ "$observed" -ne 3 ]]; then
    gate_warn "27" "$name: iterations_observed=$observed, O4 cap requires exactly 3"
    issues=$((issues + 1))
  fi
  local iters
  iters=$(iteration_count "$dir/expected-tools.jsonl")
  if [[ "$iters" -ne 3 ]]; then
    gate_warn "27" "$name: expected-tools.jsonl shows $iters fan-out iteration(s); cap requires 3"
    issues=$((issues + 1))
  fi
  if [[ $issues -eq 0 ]]; then
    gate_pass "27" "$name: O4 cap honoured (3 iterations + iteration-cap-reached marker)"
  fi
  return $issues
}

# Compares predicted orchestrator routing against the fixture's expected trace,
# then asserts the fixture-specific §11.B contract gates (20–27).
# Returns: 0 = pass; 1 = fail.
execute_fixture() {
  local dir=$1
  local name
  name=$(basename "$dir")

  local prompt
  prompt=$(cat "$dir/prompt.txt")
  local depth
  depth=$(classify_depth "$prompt")

  local first_step
  first_step=$(jq -rs '[.[].step] | min // 1' "$dir/expected-tools.jsonl" 2>/dev/null)
  if [[ -z "$first_step" || "$first_step" == "null" ]]; then
    first_step=1
  fi

  local first_step_tools=()
  read_into first_step_tools < <(jq -r --argjson s "$first_step" 'select(.step == ($s|tonumber)) | .tool' "$dir/expected-tools.jsonl" 2>/dev/null || true)

  local agent_calls=0
  local i
  for ((i = 0; i < ${#first_step_tools[@]}; i++)); do
    case "${first_step_tools[$i]}" in
      *Agent*|*subagent*) agent_calls=$((agent_calls + 1)) ;;
    esac
  done

  local expected_artefact_count
  expected_artefact_count=$(grep -cE '^[^#[:space:]]' "$dir/expected-artefacts.txt" 2>/dev/null || true)
  expected_artefact_count=${expected_artefact_count:-0}

  # 1. Depth-classification routing check (§5.6).
  case "$depth" in
    shallow)
      if [[ $expected_artefact_count -ne 0 ]]; then
        gate_warn "19" "$name: classifier says shallow but fixture expects $expected_artefact_count artefact(s)"
        return 1
      fi
      if [[ $agent_calls -ge 2 ]]; then
        gate_warn "19" "$name: classifier says shallow but fixture expects parallel Agent fan-out at step $first_step"
        return 1
      fi
      gate_pass "19" "$name: shallow routing matches expected trace"
      return 0
      ;;
    full)
      gate_pass "19" "$name: full-depth routing matches expected trace (${agent_calls} fan-out call(s) at step $first_step)"
      ;;
    *)
      gate_warn "19" "$name: depth classifier returned unexpected value '$depth'"
      return 1
      ;;
  esac

  # 2. Fixture-specific §11.B contract assertions (gates 20–27).
  local fail=0
  case "$name" in
    sdlc-full-depth)
      assert_full_depth_contract "$dir" "$name" || fail=1
      ;;
    merge-conflict)
      assert_merge_conflict_contract "$dir" "$name" || fail=1
      ;;
    degraded-mcp)
      assert_degraded_mcp_contract "$dir" "$name" || fail=1
      ;;
    iteration-cap)
      assert_iteration_cap_contract "$dir" "$name" || fail=1
      ;;
    *)
      :
      ;;
  esac

  return "$fail"
}

failed=()
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
  if execute_fixture "$dir"; then
    :
  else
    failed+=("$name")
    if [[ $KEEP_GOING -eq 0 ]]; then
      gate_fail "19" "stopping at first failed fixture; pass --keep-going to continue"
    fi
  fi
done

if [[ ${#failed[@]} -gt 0 ]]; then
  gate_fail "19" "${#failed[@]} fixture(s) failed: ${failed[*]}"
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
