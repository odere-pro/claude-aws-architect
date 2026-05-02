#!/usr/bin/env bash
# Gate 16: skill description quality.
# Per SPEC §11.A gate 16 + §4.3.
# Each skills/<name>/SKILL.md frontmatter `description`:
#   - ≤300 chars
#   - contains ≥3 distinct keywords from sibling trigger-keywords.txt
#   - does not begin with "This skill" or "A skill that"

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=16

cd "$PLUGIN_ROOT" || exit 1

if [[ ! -d skills ]]; then
  gate_pass "$GATE" "skills/ does not exist yet (no-op)"
  exit 0
fi

skill_dirs=()
read_into skill_dirs < <(find skills -mindepth 1 -maxdepth 1 -type d)

if [[ ${#skill_dirs[@]} -eq 0 ]]; then
  gate_pass "$GATE" "no skills yet (no-op)"
  exit 0
fi

failed=0
for dir in "${skill_dirs[@]}"; do
  skill_md="$dir/SKILL.md"
  trigger_kw="$dir/trigger-keywords.txt"
  [[ -f "$skill_md" && -f "$trigger_kw" ]] || continue

  fm=$(extract_frontmatter "$skill_md")
  description=$(echo "$fm" | python3 -c "import sys, yaml; d=yaml.safe_load(sys.stdin.read()); print(d.get('description', '') if d else '')" 2>/dev/null || echo "")

  if [[ -z "$description" ]]; then
    gate_warn "$GATE" "$skill_md: empty description"
    failed=$((failed + 1))
    continue
  fi

  # Length budget
  if [[ ${#description} -gt 300 ]]; then
    gate_warn "$GATE" "$skill_md: description ${#description} chars > 300"
    failed=$((failed + 1))
  fi

  # Forbidden prefixes
  if [[ "$description" == "This skill"* || "$description" == "A skill that"* ]]; then
    gate_warn "$GATE" "$skill_md: description must not begin with 'This skill' or 'A skill that'"
    failed=$((failed + 1))
  fi

  # Mandatory prefix per §4.3 ("Block scalar prefixed `**WORKFLOW SKILL** —`")
  if [[ "$description" != "**WORKFLOW SKILL** —"* ]]; then
    gate_warn "$GATE" "$skill_md: description must begin with '**WORKFLOW SKILL** —' (per §4.3)"
    failed=$((failed + 1))
  fi

  # Keyword coverage: ≥3 distinct keywords from trigger-keywords.txt
  desc_lower=$(echo "$description" | tr '[:upper:]' '[:lower:]')
  matches=0
  while IFS= read -r keyword; do
    [[ -z "$keyword" || "$keyword" =~ ^# ]] && continue
    kw_lower=$(echo "$keyword" | tr '[:upper:]' '[:lower:]')
    if [[ "$desc_lower" == *"$kw_lower"* ]]; then
      matches=$((matches + 1))
    fi
  done < "$trigger_kw"

  if [[ $matches -lt 3 ]]; then
    gate_warn "$GATE" "$skill_md: description matches only $matches trigger keywords (need ≥3)"
    failed=$((failed + 1))
  fi
done

if [[ $failed -gt 0 ]]; then
  gate_fail "$GATE" "$failed description-quality violations across ${#skill_dirs[@]} skills"
fi

gate_pass "$GATE" "${#skill_dirs[@]} skill descriptions match §4.3 quality bar"
