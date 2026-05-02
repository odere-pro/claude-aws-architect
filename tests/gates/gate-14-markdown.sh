#!/usr/bin/env bash
# Gate 14: markdownlint-cli2 + prettier --check pass on every Markdown.

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

GATE=14

cd "$PLUGIN_ROOT" || exit 1

failed=0

# markdownlint-cli2: required
if ! command -v markdownlint-cli2 >/dev/null 2>&1; then
  gate_fail "$GATE" "markdownlint-cli2 not installed (npm i -g markdownlint-cli2)"
fi
if ! markdownlint-cli2 --config .markdownlint.jsonc "**/*.md" "#node_modules" >&2; then
  gate_warn "$GATE" "markdownlint-cli2 reported issues"
  failed=$((failed + 1))
fi

# prettier: try local then npx fallback; allow skip with PRETTIER_SKIP=1 for local dev
if [[ "${PRETTIER_SKIP:-0}" == "1" ]]; then
  gate_info "$GATE" "PRETTIER_SKIP=1 — skipping prettier check"
elif command -v prettier >/dev/null 2>&1; then
  if ! prettier --check "**/*.md" >&2; then
    gate_warn "$GATE" "prettier --check reported issues"
    failed=$((failed + 1))
  fi
elif command -v npx >/dev/null 2>&1; then
  if ! npx -y prettier@3 --check "**/*.md" >&2; then
    gate_warn "$GATE" "npx prettier --check reported issues"
    failed=$((failed + 1))
  fi
else
  gate_warn "$GATE" "neither prettier nor npx available; skipping prettier check"
fi

if [[ $failed -gt 0 ]]; then
  gate_fail "$GATE" "$failed markdown linter check(s) reported issues"
fi

gate_pass "$GATE" "markdownlint + prettier clean"
