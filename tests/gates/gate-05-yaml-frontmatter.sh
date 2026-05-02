#!/usr/bin/env bash
# Gate 5: every Markdown with `---` frontmatter parses as YAML.
# Per SPEC §11.A gate 5 + N4.

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=05

command -v python3 >/dev/null 2>&1 || gate_fail "$GATE" "python3 not installed"
python3 -c 'import yaml' 2>/dev/null || gate_fail "$GATE" "PyYAML not installed (pip install pyyaml)"

cd "$PLUGIN_ROOT" || exit 1

mds=()
read_into mds < <(find . \
  -path ./.git -prune -o \
  -path ./node_modules -prune -o \
  -type f -name '*.md' -print)

checked=0
failed=0
for md in "${mds[@]}"; do
  # Skip files that don't start with `---`
  first_line=$(head -n 1 "$md" 2>/dev/null || true)
  [[ "$first_line" == "---" ]] || continue
  checked=$((checked + 1))

  fm=$(extract_frontmatter "$md")
  if [[ -z "$fm" ]]; then
    gate_warn "$GATE" "$md: opens with --- but has no frontmatter body"
    failed=$((failed + 1))
    continue
  fi

  if ! echo "$fm" | yaml_valid; then
    gate_warn "$GATE" "$md: YAML frontmatter does not parse"
    failed=$((failed + 1))
  fi
done

if [[ $failed -gt 0 ]]; then
  gate_fail "$GATE" "$failed of $checked frontmatter blocks failed to parse"
fi

if [[ $checked -eq 0 ]]; then
  gate_pass "$GATE" "no Markdown files with frontmatter yet (no-op)"
else
  gate_pass "$GATE" "$checked frontmatter blocks parse cleanly"
fi
