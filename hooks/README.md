# Hooks

PreToolUse and PostToolUse hooks that ship with `claude-aws-architect`. The registry is `hooks/hooks.json`; per-hook scripts live under `hooks/scripts/`.

## v0.1.0 hooks (this PR)

| Name                  | Event      | Matcher                                | Default | Purpose                                                                   |
| --------------------- | ---------- | -------------------------------------- | :-----: | ------------------------------------------------------------------------- |
| `secret-scanner`      | PreToolUse | `Write\|Edit\|MultiEdit\|NotebookEdit` |   ON    | Block writes containing AWS access keys, session tokens, or private keys. |
| `aws-api-write-guard` | PreToolUse | `mcp__.*`                              |   ON    | Ask before AWS write-verb MCP tool calls (Create/Put/Update/Delete/...).  |

Secondary hooks (`on-cdk-write`, `on-iam-write`, `on-bedrock-prompt-write`, `aws-test-coverage`) land in PR 26.

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
