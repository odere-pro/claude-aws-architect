#!/usr/bin/env bash
# on-iam-write — PostToolUse hook that lints IAM JSON written via
# Write/Edit/MultiEdit and surfaces least-privilege findings.
#
# Input (stdin, JSON, from Claude Code):
#   { "tool_name": "Write|Edit|MultiEdit",
#     "tool_input": { "file_path": "...", "content"|"new_string": "...", ... } }
#
# Output (stdout, JSON): hook decision via dispatcher (always "allow" —
# this is advisory; PostToolUse fires after the write has landed).
# Output (stderr): one human-readable line per finding (wildcard action,
# wildcard resource, missing condition, structurally invalid JSON).
#
# Exit codes:
#   0  always — advisory hook never blocks. Findings live on stderr.
#
# Scope: the file path looks like an IAM JSON document — basename matches
# `*policy*.json`, `*role*.json`, `*trust-policy*.json`, `iam-*.json`,
# or sits under a directory called `iam/` or `policies/` with `.json`.
#
# Findings are heuristic and intentionally name-based so the hook stays
# bash 3.2 + jq compatible without a real IAM evaluator. The rule of
# thumb: surface what an experienced reviewer would catch on first read.
# Anything deeper is delegated to the `iam` MCP server's
# `simulate_principal_policy` (called by the implementation agent, not
# here — this hook MUST NOT make MCP calls).

set -euo pipefail
IFS=$'\n\t'

export HOOK_NAME=on-iam-write

# shellcheck source=SCRIPTDIR/lib/dispatcher.sh disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib/dispatcher.sh"

hook_read_input

TOOL=$(hook_field '.tool_name')
case "$TOOL" in
  Write|Edit|MultiEdit) ;;
  *)
    hook_allow "tool $TOOL not in iam-write scope"
    ;;
esac

PATH_VAL=$(hook_field '.tool_input.file_path')
if [[ -z "$PATH_VAL" ]]; then
  hook_allow "no file path in tool input"
fi

# Identify IAM-shaped paths. Pattern matches must be deliberately conservative;
# false positives just emit a no-op finding pass.
is_iam=0
base=${PATH_VAL##*/}
case "$PATH_VAL" in
  */iam/*.json|*/policies/*.json) is_iam=1 ;;
esac
case "$base" in
  *policy*.json|*role*.json|iam-*.json) is_iam=1 ;;
esac

if [[ $is_iam -eq 0 ]]; then
  hook_allow "path $PATH_VAL not IAM-shaped"
fi

# Pull the freshest payload candidate the tool produced.
payload=""
case "$TOOL" in
  Write)
    payload=$(hook_field '.tool_input.content')
    ;;
  Edit)
    payload=$(hook_field '.tool_input.new_string')
    ;;
  MultiEdit)
    payload=$(hook_field '[.tool_input.edits[]?.new_string] | join("\n")')
    ;;
esac

if [[ -z "$payload" ]]; then
  hook_allow "no payload to inspect"
fi

findings=()

# Structural validity: if jq is available, parse-test the JSON.
if command -v jq >/dev/null 2>&1; then
  if ! printf '%s' "$payload" | jq -e . >/dev/null 2>&1; then
    findings+=("invalid-json: payload does not parse as JSON")
  fi
fi

# Wildcard action.
if printf '%s' "$payload" | grep -E -q '"Action"[[:space:]]*:[[:space:]]*(\[[[:space:]]*)?"\*"'; then
  findings+=("wildcard-action: 'Action: \"*\"' grants every API call — scope to required actions")
fi
# Service-wildcard action like "s3:*", "ec2:*".
if printf '%s' "$payload" | grep -E -q '"Action"[[:space:]]*:[[:space:]]*(\[[[:space:]]*)?"[a-z0-9-]+:\*"'; then
  findings+=("service-wildcard-action: '<service>:*' grants every action in that service — scope to specific verbs")
fi

# Wildcard resource.
if printf '%s' "$payload" | grep -E -q '"Resource"[[:space:]]*:[[:space:]]*(\[[[:space:]]*)?"\*"'; then
  findings+=("wildcard-resource: 'Resource: \"*\"' covers every ARN — pin to specific resources where possible")
fi

# Missing Condition. This is intentionally a soft hint — many legitimate
# inline policies have no Condition. Only mention when the document
# also has a wildcard somewhere (already flagged above).
if [[ ${#findings[@]} -gt 0 ]]; then
  if ! printf '%s' "$payload" | grep -q '"Condition"'; then
    findings+=("no-condition-block: paired with the wildcard(s) above, a Condition (e.g. aws:PrincipalOrgID, aws:SourceArn) is the usual scoping lever")
  fi
fi

# Trust-policy specifics.
case "$base" in
  *trust-policy*.json)
    if printf '%s' "$payload" | grep -E -q '"Principal"[[:space:]]*:[[:space:]]*\{[[:space:]]*"AWS"[[:space:]]*:[[:space:]]*"\*"'; then
      findings+=("trust-policy-principal-wildcard: 'Principal.AWS: \"*\"' allows assumption from any account — gate with aws:SourceAccount/aws:SourceArn at minimum")
    fi
    ;;
esac

if [[ ${#findings[@]} -eq 0 ]]; then
  hook_log "INFO" "IAM document at $PATH_VAL: no quick-look findings"
  hook_allow "no IAM least-privilege quick-look findings"
fi

hook_log "INFO" "IAM document at $PATH_VAL — quick-look findings:"
for f in "${findings[@]}"; do
  hook_log "INFO" "- $f"
done
hook_log "INFO" "deeper review: ask the implementation agent to run iam:simulate_principal_policy on this document"

hook_allow "advisory: ${#findings[@]} IAM quick-look finding(s) surfaced for $PATH_VAL"
