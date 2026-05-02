---
description: Bedrock prompt and AgentCore artefact discipline
applyTo:
  - "**/prompts/**/*.md"
  - "**/prompts/**/*.txt"
  - "**/agents/**/*.json"
  - "**/agentcore/**/*.json"
  - "**/*.prompt.md"
inclusion: manual
---

- Prompt body opens with a single `Role` line naming the agent's persona, scope, and refusal posture; ambiguous opening prose is forbidden because it leaks across turns.
- The model identifier is pinned to a specific Bedrock-published version (`anthropic.claude-3-5-sonnet-20241022-v2:0`-style strings); floating aliases without a version suffix are forbidden in production prompts.
- Each prompt declares its guardrail binding by name (`bedrock-guardrails-config:<id>`) or explicitly states `no-guardrail` with a documented rationale in the matching component contract.
- Response shape is contractual: the prompt names the expected output format (JSON schema reference, fenced text, tool-use schema) and the failure-mode wording the agent emits when the contract cannot be met.
- Tool-use definitions follow the JSON-schema-of-arguments convention; descriptions are imperative and ≤200 chars; ambiguous parameter types (`object`, `any`) are forbidden.
- An evaluation hook is named per prompt (golden-set fixture, eval suite, or transcript-replay path), and no secrets, account IDs, region literals, or customer identifiers appear inline in prompt text. Apply `aws-waf-security-skill`.
