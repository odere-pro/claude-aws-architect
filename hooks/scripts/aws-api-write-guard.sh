#!/usr/bin/env bash
# aws-api-write-guard — PreToolUse hook that asks the user to confirm AWS MCP
# tool calls whose verb implies a state-changing AWS API operation.
#
# Input (stdin, JSON, from Claude Code):
#   { "tool_name": "mcp__plugin_<plugin>_<server>__<tool>",
#     "tool_input": { ... } }
#
# Output (stdout, JSON): hook permission decision per dispatcher.sh.
#   - "allow" when the tool name is non-MCP, an unknown server, or an
#     identified read verb.
#   - "ask"  when the tool name's leaf verb resolves to a write class.
#   - "deny" is not used here; destructive scope decisions belong to the
#     user, not to the hook.
#
# Exit codes:
#   0  decision emitted — runtime continues based on the JSON payload.
#  64  malformed input — surfaces as a hook error to the user.
#
# Verb classification is name-based: the suffix tool name (after the final
# `__`) is matched against a write-verb regex sourced from the AWS API
# style guide. References:
#   - https://docs.aws.amazon.com/IAM/latest/UserGuide/list_amazonec2.html
#   - https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
#
# The list is conservative: anything that LOOKS like a state change asks.
# False positives (asking on a read verb) are recoverable; false negatives
# (silently letting a write through) are the failure mode this hook prevents.

set -euo pipefail
IFS=$'\n\t'

export HOOK_NAME=aws-api-write-guard

# shellcheck source=SCRIPTDIR/lib/dispatcher.sh disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib/dispatcher.sh"

hook_read_input

TOOL=$(hook_field '.tool_name')

# Non-MCP tools are out of scope.
case "$TOOL" in
  mcp__*) ;;
  *)
    hook_allow "non-MCP tool"
    ;;
esac

# Extract the suffix verb after the final `__`.
verb_with_args=${TOOL##*__}
# Verb is the lowercase first underscore-prefix of the suffix (e.g.
# "create_stack" → "create"; "get_pricing_service_codes" → "get").
verb=${verb_with_args%%_*}
# Lowercase via tr (bash 3.2 has no `${var,,}`).
verb_lc=$(printf '%s' "$verb" | tr '[:upper:]' '[:lower:]')

# Classified write verbs. Any prefix of these on the leaf tool name implies
# an AWS API write/state-change.
WRITE_VERBS=(
  create
  put
  update
  modify
  delete
  remove
  add
  attach
  detach
  associate
  disassociate
  start
  stop
  reboot
  restart
  terminate
  cancel
  apply
  enable
  disable
  authorize
  revoke
  tag
  untag
  set
  publish
  invoke
  run
  register
  deregister
  import
  export
  promote
  demote
  rotate
  refresh
  reset
  send
  copy
  restore
  upgrade
  downgrade
  patch
  rollback
)

is_write=0
for w in "${WRITE_VERBS[@]}"; do
  if [[ "$verb_lc" == "$w" ]]; then
    is_write=1
    break
  fi
done

if [[ $is_write -eq 0 ]]; then
  hook_allow "verb '$verb_lc' classified as read"
fi

# Identify the server and tool for the prompt the user sees.
# Tool layout: mcp__plugin_<plugin>_<server>__<tool>
prefix=${TOOL%__*}
server=${prefix##*_}
leaf=$verb_with_args

reason="AWS write verb '${verb_lc}' on server '${server}' (tool ${leaf}); confirm before continuing"
hook_ask "$reason"
