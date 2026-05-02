#!/usr/bin/env bash
# init.sh — first-run bootstrap for the consumer environment.
#
# Detects host tooling, pre-fetches every stdio MCP package declared in
# .mcp.json (so the first /aws invocation does not pay download latency),
# writes a settings template into .claude/settings.json if absent, and then
# execs doctor.sh so the user gets a unified status report.
#
# Idempotent: re-running the script with the same inputs writes nothing new
# (verified by gate-13 with a tempdir snapshot diff).
#
# Flags:
#   --profile <name>   Pre-set AWS_PROFILE in the settings template.
#   --region <name>    Pre-set AWS_REGION in the settings template.
#   --force            Overwrite .claude/settings.json if it already exists.
#   --help             Print this header and exit 0.
#
# Exit codes: inherits from doctor.sh (see SPEC §8.1).

# shellcheck source=SCRIPTDIR/lib/common.sh disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

FORCE=0
PROFILE=""
REGION=""
while (( $# > 0 )); do
  case "$1" in
    --profile) PROFILE=${2:-}; shift 2 ;;
    --region)  REGION=${2:-}; shift 2 ;;
    --force)   FORCE=1; shift ;;
    --help|-h)
      sed -n '2,21p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      log_err "unknown arg: $1"
      exit 64
      ;;
  esac
done

tmpdir=$(mktempdir)
# shellcheck disable=SC2064
trap "rm -rf '$tmpdir'" EXIT INT TERM

# 1. Detect required CLIs. We do not auto-install — uvx/jq/d2/shellcheck are
# managed by the host package manager. We only report what is missing so the
# user can act.
for tool in uvx jq d2 shellcheck aws; do
  if command -v "$tool" >/dev/null 2>&1; then
    log_ok "tool present: $tool"
  else
    log_warn "tool missing: $tool (install via your platform package manager)"
  fi
done

# 2. Pre-fetch every stdio MCP package declared in .mcp.json. `uvx --from <pkg>
# --help` is a no-op invocation that triggers download + cache without running
# the server. Skipped silently if uvx or jq is absent.
mcp_file="$PLUGIN_ROOT/.mcp.json"
if command -v uvx >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 && [[ -f "$mcp_file" ]]; then
  while IFS= read -r line; do
    name=${line%%$'\t'*}
    pkg=${line#*$'\t'}
    if uvx --from "$pkg" --help >/dev/null 2>&1; then
      log_ok "mcp pre-fetched: $name ($pkg)"
    else
      log_warn "mcp pre-fetch failed: $name ($pkg) — doctor.sh will re-check"
    fi
  done < <(jq -r '
    .mcpServers | to_entries[]
    | select(.value.command == "uvx")
    | .key as $k
    | (.value.args | map(select(. != "--from")) | .[0]) as $pkg
    | "\($k)\t\($pkg)"
  ' "$mcp_file")
else
  log_info "skipping MCP pre-fetch (uvx or jq missing, or .mcp.json absent)"
fi

# 3. Write a settings template if absent. We never silently overwrite a
# consumer-authored file: --force is required.
settings_path="$CONSUMER_ROOT/.claude/settings.json"
mkdir -p "$(dirname "$settings_path")"
if [[ -f "$settings_path" && $FORCE -eq 0 ]]; then
  log_info "settings.json present — leaving consumer file untouched (use --force to overwrite)"
else
  template_tmp="$tmpdir/settings.json"
  cat > "$template_tmp" <<EOF
{
  "env": {
    "AWS_PROFILE": "${PROFILE:-default}",
    "AWS_REGION": "${REGION:-us-east-1}"
  }
}
EOF
  # Write only if the rendered content differs from what's on disk (idempotency).
  if [[ -f "$settings_path" ]] && cmp -s "$template_tmp" "$settings_path"; then
    log_info "settings.json already up-to-date"
  else
    cp "$template_tmp" "$settings_path"
    log_ok "wrote .claude/settings.json (profile=${PROFILE:-default}, region=${REGION:-us-east-1})"
  fi
fi

# 4. Hand off to doctor.sh for a verified report.
log_info "running doctor.sh"
exec "$(dirname "${BASH_SOURCE[0]}")/doctor.sh"
