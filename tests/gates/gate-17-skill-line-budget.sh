#!/usr/bin/env bash
# Gate 17: every skills/<name>/SKILL.md body (excluding frontmatter) is ≤500 lines.
# Per Anthropic authoring guidance for skills.
# Skills exceeding the budget must split into references/<topic>.md files.

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=17

cd "$PLUGIN_ROOT" || exit 1

if [[ ! -d skills ]]; then
  gate_pass "$GATE" "skills/ does not exist yet (no-op)"
  exit 0
fi

skill_mds=()
read_into skill_mds < <(find skills -maxdepth 2 -type f -name 'SKILL.md')

if [[ ${#skill_mds[@]} -eq 0 ]]; then
  gate_pass "$GATE" "no SKILL.md files yet (no-op)"
  exit 0
fi

failed=0
for md in "${skill_mds[@]}"; do
  # Body = lines after the closing --- of the frontmatter
  body_lines=$(awk '/^---$/{c++; next} c>=2{print}' "$md" | wc -l | tr -d ' ')
  if [[ $body_lines -gt 500 ]]; then
    gate_warn "$GATE" "$md: body $body_lines lines > 500 (split into references/<topic>.md)"
    failed=$((failed + 1))
  fi
done

if [[ $failed -gt 0 ]]; then
  gate_fail "$GATE" "$failed SKILL.md files exceed 500-line budget"
fi

gate_pass "$GATE" "${#skill_mds[@]} SKILL.md files within 500-line budget"
