#!/usr/bin/env bash
# doctor.sh — verify the local environment can run claude-aws-architect.
#
# Checks:
#   1. Required CLIs present: uvx, jq, aws.
#   2. Required env vars set: AWS_PROFILE, AWS_REGION.
#   3. Every stdio MCP server in .mcp.json resolves via `uvx --from <pkg> --help`.
#   4. `aws sts get-caller-identity` succeeds.
#   5. Minimum-IAM policy reference file is present (per N12).
#   6. Every MCP server declared in .mcp.json is enabled (or approval-pending)
#      per the consumer's .claude/settings*.json — flags servers explicitly
#      disabled in settings.
#
# Flags:
#   --json    Emit a single JSON object on stdout (no colour, no human lines).
#   --help    Print this header and exit 0.
#
# Exit codes (per SPEC §8.1):
#   0  OK
#   1  missing tool
#   2  missing env
#   3  MCP package failed to resolve
#   4  STS get-caller-identity failed
#   5  minimum-IAM policy file absent (N12)
#   6  MCP server declared in .mcp.json is disabled in consumer settings

# shellcheck source=SCRIPTDIR/lib/common.sh disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

JSON_MODE=0
for arg in "$@"; do
  case "$arg" in
    --json) JSON_MODE=1 ;;
    --help|-h)
      sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      log_err "unknown arg: $arg"
      exit 64
      ;;
  esac
done

findings_kind=()
findings_msg=()
record() {
  findings_kind+=("$1")
  findings_msg+=("$2")
}

# 1. CLIs
for tool in uvx jq aws; do
  if command -v "$tool" >/dev/null 2>&1; then
    record "tool:$tool" "found"
  else
    record "tool:$tool" "MISSING"
  fi
done

# 2. Env
for var in AWS_PROFILE AWS_REGION; do
  if [[ -n "${!var:-}" ]]; then
    record "env:$var" "set"
  else
    record "env:$var" "MISSING"
  fi
done

# 3. MCP packages — resolve every stdio server in .mcp.json.
mcp_file="$PLUGIN_ROOT/.mcp.json"
mcp_failed=0
if command -v jq >/dev/null 2>&1 && [[ -f "$mcp_file" ]]; then
  while IFS= read -r line; do
    name=${line%%$'\t'*}
    pkg=${line#*$'\t'}
    if uvx --from "$pkg" --help >/dev/null 2>&1; then
      record "mcp:$name" "resolved $pkg"
    else
      record "mcp:$name" "UNRESOLVED $pkg"
      mcp_failed=1
    fi
  done < <(jq -r '
    .mcpServers | to_entries[]
    | select(.value.command == "uvx")
    | .key as $k
    | (.value.args | map(select(. != "--from")) | .[0]) as $pkg
    | "\($k)\t\($pkg)"
  ' "$mcp_file")
fi

# 3b. MCP enablement — for each declared server, check consumer's
#     .claude/settings*.json (project then user-global) to determine if it
#     is enabled, disabled, or approval-pending.
mcp_disabled_count=0
mcp_settings_lookup() {
  # Args: $1 = server name. Echoes one of: enabled | disabled | pending.
  local server="$1"
  local files=(
    "${CONSUMER_ROOT:-$PWD}/.claude/settings.local.json"
    "${CONSUMER_ROOT:-$PWD}/.claude/settings.json"
    "${HOME}/.claude/settings.json"
  )
  local enable_all=0 in_enabled=0 in_disabled=0 verdict
  local f
  for f in "${files[@]}"; do
    [[ -f "$f" ]] || continue
    verdict=$(jq -r --arg s "$server" '
      [
        (if (.enableAllProjectMcpServers // false) then "all" else empty end),
        (if ((.disabledMcpjsonServers // []) | index($s)) != null then "dis" else empty end),
        (if ((.enabledMcpjsonServers  // []) | index($s)) != null then "en"  else empty end)
      ] | join(",")
    ' "$f" 2>/dev/null) || verdict=""
    [[ "$verdict" == *"all"* ]] && enable_all=1
    [[ "$verdict" == *"dis"* ]] && in_disabled=1
    [[ "$verdict" == *"en"*  ]] && in_enabled=1
  done
  if [[ $in_disabled -eq 1 ]]; then
    echo "disabled"
  elif [[ $in_enabled -eq 1 || $enable_all -eq 1 ]]; then
    echo "enabled"
  else
    echo "pending"
  fi
}

if command -v jq >/dev/null 2>&1 && [[ -f "$mcp_file" ]]; then
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    state=$(mcp_settings_lookup "$name")
    case "$state" in
      enabled)  record "mcp-enabled:$name" "enabled in settings" ;;
      disabled) record "mcp-enabled:$name" "DISABLED in settings"; mcp_disabled_count=$((mcp_disabled_count + 1)) ;;
      pending)  record "mcp-enabled:$name" "not in settings — may be approved via /mcp UI; run /mcp to verify" ;;
    esac
  done < <(jq -r '.mcpServers | keys[]' "$mcp_file" 2>/dev/null)
fi

# 4. STS
sts_ok=1
if command -v aws >/dev/null 2>&1; then
  if aws sts get-caller-identity >/dev/null 2>&1; then
    record "sts" "ok"
  else
    record "sts" "FAILED"
    sts_ok=0
  fi
fi

# 5. Minimum-IAM policy reference (N12). Skill may not exist yet pre-PR-N;
# treat absence as a soft-fail (warning) when the skill dir itself is missing,
# hard-fail (exit 5) when the skill exists but the policy file is gone.
iam_skill_dir="$PLUGIN_ROOT/skills/aws-iam-skill"
iam_policy_file="$iam_skill_dir/references/minimum-iam-policy.json"
iam_status="present"
if [[ -d "$iam_skill_dir" ]]; then
  if [[ -f "$iam_policy_file" ]]; then
    record "iam-policy" "present"
  else
    record "iam-policy" "MISSING"
    iam_status="missing"
  fi
else
  record "iam-policy" "skill-not-installed"
  iam_status="skill-absent"
fi

emit_json() {
  printf '{"checks":['
  local i first=1 kind msg
  for i in "${!findings_kind[@]}"; do
    kind=${findings_kind[$i]}
    msg=${findings_msg[$i]}
    if [[ $first -eq 1 ]]; then first=0; else printf ','; fi
    printf '{"kind":"%s","status":"%s"}' "$kind" "$msg"
  done
  printf ']}\n'
}

emit_human() {
  local i kind msg
  for i in "${!findings_kind[@]}"; do
    kind=${findings_kind[$i]}
    msg=${findings_msg[$i]}
    case "$msg" in
      MISSING|UNRESOLVED*|FAILED|"DISABLED in settings") log_err "$kind: $msg" ;;
      "pending approval"*) log_warn "$kind: $msg" ;;
      *) log_ok "$kind: $msg" ;;
    esac
  done
}

if [[ $JSON_MODE -eq 1 ]]; then
  emit_json
else
  emit_human
fi

# Decide exit code by precedence (lowest wins).
for i in "${!findings_kind[@]}"; do
  k=${findings_kind[$i]}
  m=${findings_msg[$i]}
  case "$k" in
    tool:*) [[ "$m" = "MISSING" ]] && exit 1 ;;
  esac
done
for i in "${!findings_kind[@]}"; do
  k=${findings_kind[$i]}
  m=${findings_msg[$i]}
  case "$k" in
    env:*) [[ "$m" = "MISSING" ]] && exit 2 ;;
  esac
done
[[ $mcp_failed -eq 1 ]] && exit 3
[[ $sts_ok -eq 0 ]] && exit 4
[[ "$iam_status" = "missing" ]] && exit 5
[[ $mcp_disabled_count -gt 0 ]] && exit 6
exit 0
