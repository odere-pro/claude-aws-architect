#!/usr/bin/env bash
# Gate 10: every skill under skills/ matches §4.3 contract.
# Per SPEC §11.A gate 10 + §4.3.
# Required frontmatter: name (matches dir), description, version. Optional: argument-hint, user-invocable.
# Required sibling: trigger-keywords.txt.
# Body H2 sections in order: When to Use, Procedure, Gotchas (mandatory), Boundaries, Quality Checks.
# Optional: How It Differs.

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=10

cd "$PLUGIN_ROOT" || exit 1

if [[ ! -d skills ]]; then
  gate_pass "$GATE" "skills/ does not exist yet (no-op)"
  exit 0
fi

skill_dirs=()
read_into skill_dirs < <(find skills -mindepth 1 -maxdepth 1 -type d)

if [[ ${#skill_dirs[@]} -eq 0 ]]; then
  gate_pass "$GATE" "no skills/<name>/ directories yet (no-op)"
  exit 0
fi

REQUIRED_SECTIONS=(
  "When to Use"
  "Procedure"
  "Gotchas"
  "Boundaries"
  "Quality Checks"
)

failed=0
for dir in "${skill_dirs[@]}"; do
  skill_name=$(basename "$dir")
  skill_md="$dir/SKILL.md"
  trigger_kw="$dir/trigger-keywords.txt"

  if [[ ! -f "$skill_md" ]]; then
    gate_warn "$GATE" "$dir: missing SKILL.md"
    failed=$((failed + 1))
    continue
  fi
  if [[ ! -f "$trigger_kw" ]]; then
    gate_warn "$GATE" "$dir: missing trigger-keywords.txt"
    failed=$((failed + 1))
  fi

  fm=$(extract_frontmatter "$skill_md")
  if [[ -z "$fm" ]]; then
    gate_warn "$GATE" "$skill_md: missing YAML frontmatter"
    failed=$((failed + 1))
    continue
  fi
  if ! echo "$fm" | yaml_valid; then
    gate_warn "$GATE" "$skill_md: frontmatter does not parse as YAML"
    failed=$((failed + 1))
    continue
  fi

  # Required fields
  for field in name description version; do
    if ! echo "$fm" | python3 -c "
import sys, yaml
fm = yaml.safe_load(sys.stdin.read())
sys.exit(0 if fm and '$field' in fm and fm['$field'] not in (None, '') else 1)
" 2>/dev/null; then
      gate_warn "$GATE" "$skill_md: missing required frontmatter field '$field'"
      failed=$((failed + 1))
    fi
  done

  # Name matches directory
  actual_name=$(echo "$fm" | python3 -c "import sys, yaml; print(yaml.safe_load(sys.stdin.read()).get('name', ''))" 2>/dev/null || echo "")
  if [[ "$actual_name" != "$skill_name" ]]; then
    gate_warn "$GATE" "$skill_md: name '$actual_name' must match directory '$skill_name'"
    failed=$((failed + 1))
  fi

  # Section ordering
  actual_sections=()
  read_into actual_sections < <(grep -E '^## ' "$skill_md" | sed -E 's/^## //')
  expected_idx=0
  matched=0
  for section in "${actual_sections[@]}"; do
    if [[ $expected_idx -lt ${#REQUIRED_SECTIONS[@]} && "$section" == "${REQUIRED_SECTIONS[$expected_idx]}" ]]; then
      expected_idx=$((expected_idx + 1))
      matched=$((matched + 1))
    fi
  done
  if [[ $matched -lt ${#REQUIRED_SECTIONS[@]} ]]; then
    gate_warn "$GATE" "$skill_md: missing or out-of-order H2 sections (matched $matched of ${#REQUIRED_SECTIONS[@]} required, including mandatory Gotchas)"
    failed=$((failed + 1))
  fi
done

if [[ $failed -gt 0 ]]; then
  gate_fail "$GATE" "$failed contract violations across ${#skill_dirs[@]} skills"
fi

gate_pass "$GATE" "${#skill_dirs[@]} skills match §4.3 contract"
