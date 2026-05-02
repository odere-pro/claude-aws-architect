#!/usr/bin/env bash
# aws-secret-scanner — PreToolUse hook that blocks Write/Edit/MultiEdit/NotebookEdit
# operations whose payload contains AWS credentials, tokens, or private keys.
#
# Input (stdin, JSON, from Claude Code):
#   { "tool_name": "Write|Edit|MultiEdit|NotebookEdit",
#     "tool_input": { "file_path": "...", "content": "...", ...
#                     # MultiEdit:    "edits": [ { "old_string": "...", "new_string": "..." }, ... ]
#                     # Edit:         "old_string": "...", "new_string": "..."
#                     # NotebookEdit: "new_source": "..." } }
#
# Output (stdout, JSON): hook permission decision (allow|deny) per dispatcher.sh.
# Output (stderr): on deny, one human line per matched pattern.
#
# Exit codes:
#   0  no secret found — allow.
#   2  secret found — deny; message on stderr names the pattern (NOT the value).
#
# Pattern catalogue is intentionally conservative. False positives are
# acceptable; false negatives are not. The catalogue covers the AWS
# credential classes documented under
# https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html
# plus the universal SSH/PGP/PKCS private-key block markers.

set -euo pipefail
IFS=$'\n\t'

export HOOK_NAME=aws-secret-scanner

# shellcheck source=SCRIPTDIR/lib/dispatcher.sh disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib/dispatcher.sh"

hook_read_input

TOOL=$(hook_field '.tool_name')
case "$TOOL" in
  Write|Edit|MultiEdit|NotebookEdit) ;;
  *)
    hook_allow "tool $TOOL not in scanner scope"
    ;;
esac

# Concatenate every payload candidate the tool can carry. Empty fields collapse.
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
  NotebookEdit)
    payload=$(hook_field '.tool_input.new_source')
    ;;
esac

if [[ -z "$payload" ]]; then
  hook_allow "no payload to scan"
fi

# Pattern table. Each row is "label|extended-regex".
# Order matters only for the stderr messages; matching does not short-circuit.
PATTERNS=(
  "aws-access-key|(AKIA|ASIA|AROA|AIDA|AGPA|ANPA|ANVA|APKA|ASCA|AIPA)[0-9A-Z]{16}"
  "aws-secret-access-key|aws_secret_access_key[[:space:]]*=[[:space:]]*['\"]?[A-Za-z0-9/+=]{40}['\"]?"
  "aws-session-token|aws_session_token[[:space:]]*=[[:space:]]*['\"]?[A-Za-z0-9/+=]{100,}['\"]?"
  "private-key-block|-----BEGIN[[:space:]]+(RSA|EC|DSA|OPENSSH|PGP|ENCRYPTED|ANY)?[[:space:]]*PRIVATE[[:space:]]+KEY-----"
  "kms-cmk-arn|arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]{36}"
)

hits=()
for entry in "${PATTERNS[@]}"; do
  label=${entry%%|*}
  regex=${entry#*|}
  if printf '%s' "$payload" | grep -E -q -e "$regex"; then
    hits+=("$label")
  fi
done

if [[ ${#hits[@]} -gt 0 ]]; then
  reasons=$(printf '%s, ' "${hits[@]}")
  reasons=${reasons%, }
  hook_log "ERROR" "blocked write: matched $reasons"
  hook_log "ERROR" "if this is a false positive, redact the value or move it to an env var / Secrets Manager / SSM"
  hook_deny "secret pattern match: $reasons"
fi

hook_allow "no secret patterns matched"
