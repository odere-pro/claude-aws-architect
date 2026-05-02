#!/usr/bin/env bash
# aws-on-cdk-write — PostToolUse hook that surfaces a CDK-synth + cdk-nag nudge
# after a Write/Edit/MultiEdit lands inside a CDK source root.
#
# Input (stdin, JSON, from Claude Code):
#   { "tool_name": "Write|Edit|MultiEdit|NotebookEdit",
#     "tool_input": { "file_path": "...", ... } }
#
# Output (stdout, JSON): hook decision via dispatcher (always "allow" — this
# is advisory; the write has already happened by the time PostToolUse fires).
# Output (stderr): one human-readable line with the suggested CDK command(s)
# and a pointer to the cdk-nag pack the project already declares.
#
# Exit codes:
#   0  always — advisory hook never blocks. The reason is conveyed via stderr.
#
# Scope: a file is "CDK source" when its path matches a CDK-conventional
# directory (`bin/`, `lib/`, `cdk/`, `infrastructure/`, `iac/`) AND its
# basename is `cdk.json`, `cdk.context.json`, ends in `-stack.ts`,
# `-stack.js`, `-stack.py`, `-construct.ts`, `-construct.py`, or sits
# beneath one of those directories with a `.ts|.js|.py` extension. The
# rule deliberately under-matches: false positives waste a console line;
# false negatives just miss a nudge.
#
# Forbidden in this script: running cdk synth, cdk deploy, npm install,
# pip install, or any network call. The hook surfaces a recommendation;
# execution is the user's decision.

set -euo pipefail
IFS=$'\n\t'

export HOOK_NAME=aws-on-cdk-write

# shellcheck source=SCRIPTDIR/lib/dispatcher.sh disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib/dispatcher.sh"

hook_read_input

TOOL=$(hook_field '.tool_name')
case "$TOOL" in
  Write|Edit|MultiEdit|NotebookEdit) ;;
  *)
    hook_allow "tool $TOOL not in cdk-write scope"
    ;;
esac

PATH_VAL=$(hook_field '.tool_input.file_path')
if [[ -z "$PATH_VAL" ]]; then
  PATH_VAL=$(hook_field '.tool_input.notebook_path')
fi
if [[ -z "$PATH_VAL" ]]; then
  hook_allow "no file path in tool input"
fi

# CDK indicators on the path.
match=0
case "$PATH_VAL" in
  *cdk.json|*cdk.context.json) match=1 ;;
  */bin/*.ts|*/bin/*.js|*/bin/*.py) match=1 ;;
  */lib/*-stack.ts|*/lib/*-stack.js|*/lib/*-stack.py) match=1 ;;
  */lib/*-construct.ts|*/lib/*-construct.py) match=1 ;;
  */cdk/*.ts|*/cdk/*.js|*/cdk/*.py) match=1 ;;
  */infrastructure/*.ts|*/infrastructure/*.py) match=1 ;;
  */iac/*.ts|*/iac/*.py) match=1 ;;
esac

if [[ $match -eq 0 ]]; then
  hook_allow "path $PATH_VAL outside CDK source roots"
fi

hook_log "INFO" "CDK source touched: $PATH_VAL"
hook_log "INFO" "suggested next steps: 'cdk synth' to render CloudFormation; 'cdk diff' to compare against the deployed stack"
hook_log "INFO" "if cdk-nag is wired into the app, the synth output will surface security/best-practice findings"

hook_allow "advisory: cdk synth + cdk-nag nudge surfaced for $PATH_VAL"
