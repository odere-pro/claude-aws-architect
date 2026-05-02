#!/usr/bin/env bash
# Gate 9: every agent file under agents/ matches §5.1 contract.
# Per SPEC §11.A gate 9 + §5.1.
# Required frontmatter: name (kebab-case ending -agent, matches filename),
# description, model, effort, user-invocable, tools.
# H2 sections in this exact order:
#   Role, Requirements, Dependencies, Operating Principles, Routing Map,
#   Workflow, Output Rules, Boundaries, Quality Checks.

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=09

cd "$PLUGIN_ROOT" || exit 1

if [[ ! -d agents ]]; then
  gate_pass "$GATE" "agents/ does not exist yet (no-op)"
  exit 0
fi

agents=()
read_into agents < <(find agents -maxdepth 1 -type f -name '*-agent.md')

if [[ ${#agents[@]} -eq 0 ]]; then
  gate_pass "$GATE" "no agents/*-agent.md yet (no-op)"
  exit 0
fi

REQUIRED_SECTIONS=(
  "Role"
  "Requirements"
  "Dependencies"
  "Operating Principles"
  "Routing Map"
  "Workflow"
  "Output Rules"
  "Boundaries"
  "Quality Checks"
)

failed=0
for a in "${agents[@]}"; do
  fm=$(extract_frontmatter "$a")
  if [[ -z "$fm" ]]; then
    gate_warn "$GATE" "$a: missing YAML frontmatter"
    failed=$((failed + 1))
    continue
  fi
  if ! echo "$fm" | yaml_valid; then
    gate_warn "$GATE" "$a: frontmatter does not parse as YAML"
    failed=$((failed + 1))
    continue
  fi

  # Required scalar fields
  for field in name description model effort user-invocable tools; do
    if ! echo "$fm" | python3 -c "
import sys, yaml
fm = yaml.safe_load(sys.stdin.read())
sys.exit(0 if fm and '$field' in fm else 1)
" 2>/dev/null; then
      gate_warn "$GATE" "$a: missing required frontmatter field '$field'"
      failed=$((failed + 1))
    fi
  done

  # Filename ↔ name consistency
  expected_name=$(basename "$a" .md)
  actual_name=$(echo "$fm" | python3 -c "import sys, yaml; print(yaml.safe_load(sys.stdin.read()).get('name', ''))" 2>/dev/null || echo "")
  if [[ "$expected_name" != "$actual_name" ]]; then
    gate_warn "$GATE" "$a: name '$actual_name' must match filename '$expected_name'"
    failed=$((failed + 1))
  fi
  if [[ "$actual_name" != *-agent ]]; then
    gate_warn "$GATE" "$a: name must end with -agent"
    failed=$((failed + 1))
  fi

  # Section ordering
  actual_sections=()
  read_into actual_sections < <(grep -E '^## ' "$a" | sed -E 's/^## //')
  expected_idx=0
  matched=0
  for section in "${actual_sections[@]}"; do
    if [[ $expected_idx -lt ${#REQUIRED_SECTIONS[@]} && "$section" == "${REQUIRED_SECTIONS[$expected_idx]}" ]]; then
      expected_idx=$((expected_idx + 1))
      matched=$((matched + 1))
    fi
  done
  if [[ $matched -lt ${#REQUIRED_SECTIONS[@]} ]]; then
    gate_warn "$GATE" "$a: missing or out-of-order H2 sections (matched $matched of ${#REQUIRED_SECTIONS[@]} required)"
    failed=$((failed + 1))
  fi
done

if [[ $failed -gt 0 ]]; then
  gate_fail "$GATE" "$failed contract violations across ${#agents[@]} agent files"
fi

gate_pass "$GATE" "${#agents[@]} agent files match §5.1 contract"
