# Hooks

PreToolUse and PostToolUse hooks that ship with `claude-aws-architect`. The registry is `hooks/hooks.json`; per-hook scripts live under `hooks/scripts/`.

## v0.1.0 hooks

| Name                      | Event       | Matcher                                | Default | Purpose                                                                                                          |
| ------------------------- | ----------- | -------------------------------------- | :-----: | ---------------------------------------------------------------------------------------------------------------- |
| `secret-scanner`          | PreToolUse  | `Write\|Edit\|MultiEdit\|NotebookEdit` |   ON    | Block writes containing AWS access keys, session tokens, or private keys.                                        |
| `aws-api-write-guard`     | PreToolUse  | `mcp__.*`                              |   ON    | Ask before AWS write-verb MCP tool calls (Create/Put/Update/Delete/...).                                         |
| `on-cdk-write`            | PostToolUse | `Write\|Edit\|MultiEdit\|NotebookEdit` |   off   | Surface a `cdk synth` + `cdk-nag` nudge when a write lands in CDK source roots.                                  |
| `on-iam-write`            | PostToolUse | `Write\|Edit\|MultiEdit`               |   off   | Quick-look IAM JSON: invalid JSON, wildcard action / resource, missing condition, trust-policy `Principal: "*"`. |
| `on-bedrock-prompt-write` | PostToolUse | `Write\|Edit\|MultiEdit`               |   off   | Check Bedrock prompt artefacts for the three v0.1.0 mandatory bindings: model-id, guardrail, evaluation hook.    |
| `aws-test-coverage`       | PostToolUse | `Write\|Edit\|MultiEdit`               |   off   | Surface sibling test paths for AWS-touching writes; flag missing test, flag stale test by mtime.                 |

The four PostToolUse hooks ship default-disabled because they are advisory: they emit `allow` and write findings to stderr. Consumers opt in by flipping `enabledByDefault: true` in `hooks/hooks.json` (or, once PR 27 lands, via the consumer settings overlay).

## Contract

Each hook script reads a JSON payload from stdin, emits a permission decision (allow / ask / deny) as JSON on stdout, and writes diagnostics to stderr.

| Decision  | Stdout JSON                                                                                                           | Stderr     | Exit |
| --------- | --------------------------------------------------------------------------------------------------------------------- | ---------- | :--: |
| allow     | `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"..."}}` | optional   |  0   |
| ask       | `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"..."}}`   | optional   |  0   |
| deny      | `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"..."}}`  | required   |  2   |
| bad input | (no stdout)                                                                                                           | error line |  64  |

Hooks share input parsing, decision emission, and logging via `hooks/scripts/lib/dispatcher.sh`. Every per-hook script sources the dispatcher; raw stdin/stdout handling is the dispatcher's responsibility.

## Disabling a hook

Hooks are opt-out. To disable a single hook locally, add a project-level override in `.claude/claude-aws-architect.local.md` (UX lands with PR 27 / scripts). Until then, edit `hooks/hooks.json#enabledByDefault` to `false` for the hook in question.

## Testing locally

The hook scripts run against Claude Code's PreToolUse JSON schema. To exercise one manually:

```bash
echo '{"tool_name":"Write","tool_input":{"file_path":"foo.txt","content":"AKIAIOSFODNN7EXAMPLE"}}' \
  | bash hooks/scripts/secret-scanner.sh
```

Expected: stdout JSON `permissionDecision: "deny"`, stderr names `aws-access-key`, exit 2.

```bash
echo '{"tool_name":"mcp__plugin_claude_aws_architect_iac__create_stack","tool_input":{}}' \
  | bash hooks/scripts/aws-api-write-guard.sh
```

Expected: stdout JSON `permissionDecision: "ask"`, stderr describes the verb/server, exit 0.

```bash
echo '{"tool_name":"Write","tool_input":{"file_path":"app/lib/api-stack.ts","content":""}}' \
  | bash hooks/scripts/on-cdk-write.sh
```

Expected: stdout JSON `permissionDecision: "allow"` with a CDK-synth + cdk-nag advisory; stderr names the path; exit 0.

```bash
echo '{"tool_name":"Write","tool_input":{"file_path":"infra/iam/admin-policy.json","content":"{\"Statement\":[{\"Action\":\"*\",\"Resource\":\"*\"}]}"}}' \
  | bash hooks/scripts/on-iam-write.sh
```

Expected: stdout JSON `allow`; stderr lists `wildcard-action`, `wildcard-resource`, `no-condition-block`; exit 0.

```bash
echo '{"tool_name":"Write","tool_input":{"file_path":"prompts/router.json","content":"{}"}}' \
  | bash hooks/scripts/on-bedrock-prompt-write.sh
```

Expected: stdout JSON `allow`; stderr lists `model-id-pinning`, `guardrail-binding`, `evaluation-hook` as missing; exit 0.

```bash
echo '{"tool_name":"Write","tool_input":{"file_path":"src/uploader.ts","content":"import { S3Client } from \"@aws-sdk/client-s3\";"}}' \
  | bash hooks/scripts/aws-test-coverage.sh
```

Expected: stdout JSON `allow`; stderr lists candidate test paths and an "advisory: missing test" finding; exit 0.
