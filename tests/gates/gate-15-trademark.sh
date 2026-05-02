#!/usr/bin/env bash
# Gate 15: README.md contains a top-level `## Trademark notice` section
# with the four required declarative bullets.

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=15
FILE="$PLUGIN_ROOT/README.md"

[[ -f "$FILE" ]] || gate_fail "$GATE" "README.md missing"

# Check the heading exists
grep -q '^## Trademark notice$' "$FILE" || gate_fail "$GATE" "missing top-level '## Trademark notice' section"

# Extract the section body (lines after the heading until the next ## heading)
section=$(awk '/^## Trademark notice$/{flag=1; next} flag && /^## /{flag=0} flag' "$FILE")

bullet_count=$(echo "$section" | grep -c '^- ' || true)
if [[ $bullet_count -lt 4 ]]; then
  gate_fail "$GATE" "Trademark notice must contain ≥4 declarative bullets, found $bullet_count"
fi

# Spot-check that the four declarative themes are present
themes=(
  'not affiliated|endorsed|sponsored'
  'trademark'
  'trademark guidelines'
  'descriptive token|descriptive name|denoting'
)
missing_themes=0
for theme in "${themes[@]}"; do
  if ! echo "$section" | grep -qiE "$theme"; then
    gate_warn "$GATE" "Trademark notice missing theme: '$theme'"
    missing_themes=$((missing_themes + 1))
  fi
done
[[ $missing_themes -eq 0 ]] || gate_fail "$GATE" "$missing_themes required themes missing from Trademark notice"

gate_pass "$GATE" "Trademark notice present with $bullet_count bullets covering all 4 required themes"
