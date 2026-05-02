#!/usr/bin/env bash
# Gate 8: every rule file under rules/ matches §6.1 contract.
# Per SPEC §11.A gate 8 + §6.1.
# Required frontmatter: description, applyTo, inclusion (always|conditional|manual).
# Body: 2–6 self-contained bullets, total ≤200 words; no code blocks.

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=08

cd "$PLUGIN_ROOT" || exit 1

if [[ ! -d rules ]]; then
  gate_pass "$GATE" "rules/ does not exist yet (no-op)"
  exit 0
fi

rules=()
read_into rules < <(find rules -maxdepth 1 -type f -name '*.instructions.md')

if [[ ${#rules[@]} -eq 0 ]]; then
  gate_pass "$GATE" "no rules/*.instructions.md yet (no-op)"
  exit 0
fi

failed=0
for r in "${rules[@]}"; do
  fm=$(extract_frontmatter "$r")
  if [[ -z "$fm" ]]; then
    gate_warn "$GATE" "$r: missing YAML frontmatter"
    failed=$((failed + 1))
    continue
  fi
  if ! echo "$fm" | yaml_valid; then
    gate_warn "$GATE" "$r: frontmatter does not parse as YAML"
    failed=$((failed + 1))
    continue
  fi

  # Check required fields
  for field in description applyTo inclusion; do
    if ! echo "$fm" | python3 -c "
import sys, yaml
fm = yaml.safe_load(sys.stdin.read())
sys.exit(0 if fm and '$field' in fm and fm['$field'] not in (None, '') else 1)
" 2>/dev/null; then
      gate_warn "$GATE" "$r: missing required frontmatter field '$field'"
      failed=$((failed + 1))
    fi
  done

  # Validate inclusion enum
  inclusion=$(echo "$fm" | python3 -c "import sys, yaml; print(yaml.safe_load(sys.stdin.read()).get('inclusion', ''))" 2>/dev/null || echo "")
  if [[ "$inclusion" != "always" && "$inclusion" != "conditional" && "$inclusion" != "manual" ]]; then
    gate_warn "$GATE" "$r: inclusion must be one of always|conditional|manual, got '$inclusion'"
    failed=$((failed + 1))
  fi

  # Body checks: extract body (after second ---), count bullets and words
  body=$(awk '/^---$/{c++; next} c>=2{print}' "$r")
  bullet_count=$(echo "$body" | grep -c '^- ' || true)
  if [[ $bullet_count -lt 2 || $bullet_count -gt 6 ]]; then
    gate_warn "$GATE" "$r: must have 2–6 top-level bullets, got $bullet_count"
    failed=$((failed + 1))
  fi
  word_count=$(echo "$body" | wc -w | tr -d ' ')
  if [[ $word_count -gt 200 ]]; then
    gate_warn "$GATE" "$r: body exceeds 200 words ($word_count)"
    failed=$((failed + 1))
  fi
  if echo "$body" | grep -q '^```'; then
    gate_warn "$GATE" "$r: body must not contain code blocks"
    failed=$((failed + 1))
  fi
done

if [[ $failed -gt 0 ]]; then
  gate_fail "$GATE" "$failed contract violations across ${#rules[@]} rule files"
fi

gate_pass "$GATE" "${#rules[@]} rule files match §6.1 contract"
