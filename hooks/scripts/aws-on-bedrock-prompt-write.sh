#!/usr/bin/env bash
# aws-on-bedrock-prompt-write — PostToolUse hook that checks Bedrock prompt /
# AgentCore artefact writes for the three v0.1.0 mandatory bindings:
# (1) model-id pinning, (2) guardrail binding, (3) evaluation-hook
# presence. Surfaces missing fields as advisory findings; never edits.
#
# Input (stdin, JSON, from Claude Code):
#   { "tool_name": "Write|Edit|MultiEdit",
#     "tool_input": { "file_path": "...", "content"|"new_string": "...", ... } }
#
# Output (stdout, JSON): hook decision via dispatcher (always "allow").
# Output (stderr): one human-readable line per missing binding.
#
# Exit codes:
#   0  always — advisory hook never blocks. Findings live on stderr.
#
# Scope: Bedrock prompt artefacts are detected by path. Three shapes
# qualify:
#   - any file whose path includes `/prompts/` or `/bedrock-prompts/`
#     and ends in `.json`, `.yaml`, `.yml`, or `.md`;
#   - any file whose basename starts with `prompt-` or `bedrock-` and
#     ends in those extensions;
#   - any file whose path includes `/agentcore/`.
#
# Required-binding heuristics are name-based and SDK-version-agnostic:
#
#   model-id pinning   — payload mentions `model_id` / `modelId` /
#                         `model-id` keyed against a value containing
#                         `:` (the canonical ARN/alias separator) or a
#                         pinned model name like `claude-3-...` / `claude-4-...`.
#   guardrail binding  — payload mentions `guardrail_identifier` /
#                         `guardrailIdentifier` / `guardrail_arn` /
#                         `guardrailArn` against a non-empty value.
#   evaluation hook    — payload mentions `evaluation` /
#                         `eval_hook` / `evaluationHook` /
#                         `evaluator_arn` against a non-empty value.
#
# Forbidden in this script: invoking `bedrock-runtime`, hitting AWS,
# auto-rewriting the prompt. The hook surfaces the gap; the user (or
# the agent on its next turn) closes it.

set -euo pipefail
IFS=$'\n\t'

export HOOK_NAME=aws-on-bedrock-prompt-write

# shellcheck source=SCRIPTDIR/lib/dispatcher.sh disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib/dispatcher.sh"

hook_read_input

TOOL=$(hook_field '.tool_name')
case "$TOOL" in
  Write|Edit|MultiEdit) ;;
  *)
    hook_allow "tool $TOOL not in bedrock-prompt scope"
    ;;
esac

PATH_VAL=$(hook_field '.tool_input.file_path')
if [[ -z "$PATH_VAL" ]]; then
  hook_allow "no file path in tool input"
fi

base=${PATH_VAL##*/}
ext=""
case "$base" in
  *.json) ext=json ;;
  *.yaml|*.yml) ext=yaml ;;
  *.md) ext=md ;;
esac

is_prompt=0
case "$PATH_VAL" in
  prompts/*|bedrock-prompts/*|agentcore/*) [[ -n "$ext" ]] && is_prompt=1 ;;
  */prompts/*|*/bedrock-prompts/*|*/agentcore/*) [[ -n "$ext" ]] && is_prompt=1 ;;
esac
case "$base" in
  prompt-*.json|prompt-*.yaml|prompt-*.yml|prompt-*.md) is_prompt=1 ;;
  bedrock-*.json|bedrock-*.yaml|bedrock-*.yml|bedrock-*.md) is_prompt=1 ;;
esac

if [[ $is_prompt -eq 0 ]]; then
  hook_allow "path $PATH_VAL not Bedrock-prompt-shaped"
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

missing=()

# model-id pinning.
if ! printf '%s' "$payload" | grep -E -q '("model_id"|"modelId"|"model-id"|model_id:|modelId:)[[:space:]]*[:=]?[[:space:]]*"?[^"[:space:]]+'; then
  missing+=("model-id-pinning: no model_id / modelId / model-id field found — pin to a specific model ARN or alias (e.g. anthropic.claude-sonnet-4-6-...) for reproducibility")
fi

# guardrail binding.
if ! printf '%s' "$payload" | grep -E -q '("guardrail_identifier"|"guardrailIdentifier"|"guardrail_arn"|"guardrailArn"|guardrail_identifier:|guardrailIdentifier:)[[:space:]]*[:=]?[[:space:]]*"?[^"[:space:]]+'; then
  missing+=("guardrail-binding: no guardrail_identifier / guardrailIdentifier / guardrail_arn field found — bind a Bedrock guardrail before production use")
fi

# evaluation hook.
if ! printf '%s' "$payload" | grep -E -q '("evaluation"|"eval_hook"|"evaluationHook"|"evaluator_arn"|evaluation:|eval_hook:|evaluationHook:)'; then
  missing+=("evaluation-hook: no evaluation / eval_hook / evaluationHook field found — declare the eval used to gate prompt regressions before merge")
fi

if [[ ${#missing[@]} -eq 0 ]]; then
  hook_log "INFO" "Bedrock prompt at $PATH_VAL: model-id, guardrail, and evaluation hook all present"
  hook_allow "all three Bedrock bindings present"
fi

hook_log "INFO" "Bedrock prompt at $PATH_VAL — missing required binding(s):"
for m in "${missing[@]}"; do
  hook_log "INFO" "- $m"
done
hook_log "INFO" "see aws-bedrock-prompt rule for the field-by-field contract"

hook_allow "advisory: ${#missing[@]} missing Bedrock binding(s) for $PATH_VAL"
