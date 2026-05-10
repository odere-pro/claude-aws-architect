# Usage patterns — invoking a recipe in a session

Recipes are static manifests at v0.1.0 — there is no runtime
activation. Using a recipe means picking one and following the
matching invocation pattern. Three patterns are supported.

## 1. Playbook-driven (recommended for first-time use)

Each recipe has a worked playbook under `docs/playbooks/`:

| Recipe                            | Playbook                                       |
| --------------------------------- | ---------------------------------------------- |
| `claude-aws-architect-cdk`        | `docs/playbooks/cdk-recipe-playbook.md`        |
| `claude-aws-architect-cost`       | `docs/playbooks/cost-recipe-playbook.md`       |
| `claude-aws-architect-security`   | `docs/playbooks/security-recipe-playbook.md`   |
| `claude-aws-architect-kb`         | `docs/playbooks/kb-recipe-playbook.md`         |
| `claude-aws-architect-bedrock-ai` | `docs/playbooks/bedrock-ai-recipe-playbook.md` |

Each playbook has three scenarios — AWS-200 (basic), AWS-300
(senior), AWS-500 (architect). Pick the one matching the task, copy
the trigger phrase, and run via `/aws`. The playbook tells you what
the orchestrator will do, which MCPs it will call, and which artefacts
it will write.

Example (CDK, AWS-200):

```text
/aws --quick scaffold a Node.js Lambda + API Gateway HTTP webhook
     with x-ray and CloudWatch logs
```

## 2. Direct `@`-reference

Paste the recipe JSON path as an `@`-reference and follow with the
request. Claude reads the bundle and steers toward the listed
skills and MCPs.

```text
@recipes/claude-aws-architect-cost.recipe.json
Give me a cost ROM for an order pipeline:
EventBridge bus, 100k events/day, SQS DLQ, Lambda processor,
DynamoDB idempotency table. Region us-east-1.
```

What happens:

- Claude reads `mcpServers`, `skills`, `hooks`, `commands` from the
  recipe.
- It treats them as a routing hint, not a gate.
- It prefers `cost:` and `kb:` MCP calls for grounding.
- It applies the `aws-waf-cost-optimization-skill` and the
  substrate routing/grounding skills.
- It records every cost lookup in the grounding ledger.

Use this pattern when you know which recipe applies and want to
skip the playbook ceremony.

## 3. Orchestrator-routed

Run `/aws <prompt>` without picking a recipe. The orchestrator
classifies the prompt by depth (`--quick`, `--standard`, `--deep`),
selects the matching specialist agents, and exercises the relevant
substrate skills. The recipe-as-contract is implicit: whichever
recipe matches the workflow profile is the one the orchestrator's
choices will resemble.

```text
/aws design an event-driven order-processing pipeline with
     idempotency, retry, and a $50/month cost ceiling
```

Use this pattern when the workflow spans more than one recipe's
focus, or when you do not want to pre-commit to a profile.

## Verifying a recipe fired

After a session, check three artefacts:

1. **The grounding ledger** (`.grounding-ledger.json` in the feature
   directory) should contain `<server>:<short-key>` entries for every
   MCP listed in the recipe that was actually relevant.
2. **The hook log** should show `aws-secret-scanner` ran on every
   write. If the recipe included `aws-api-write-guard`, it should
   appear for any AWS write verb.
3. **The output artefacts** (e.g. `design.md`, `tasks.md`) should cite
   the skills the recipe lists. WAF pillar skills surface as
   pillar-tagged findings; the `aws-component-contract` skill surfaces
   as one contract file per artefact.

If a recipe's listed capability did not fire, the cause is usually
that the prompt did not exercise it (e.g. a cost-only prompt does
not trigger the security pillar skills, even in the security recipe).
That is correct behaviour — recipes are scope, not force.

## Anti-patterns

- **Mixing two recipes in one prompt.** One workflow profile per
  session. If two recipes apply, the workflow is broader than either —
  use orchestrator-routed invocation (`/aws`) and let depth
  classification handle the spread.
- **`@`-referencing a recipe but writing a prompt that does not
  match its focus.** The recipe does not constrain Claude; a
  cost-recipe `@`-reference followed by a security question still
  gets answered, but the cost MCPs go unused. Pick the right recipe
  or use `/aws`.
- **Treating a recipe as installed software.** Recipes are JSON
  manifests, not packages. There is nothing to install. Every recipe
  is available the moment the plugin is installed.
