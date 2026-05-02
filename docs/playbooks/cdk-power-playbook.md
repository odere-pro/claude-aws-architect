# `claude-aws-architect-cdk` — playbook

Authoring power for IaC. Bundles `iac`, `cost`, `kb` MCP servers; the routing / grounding / cache / component-contract / layered-diagram skills; the Cost / Reliability / Operational-Excellence WAF pillar skills; both default PreToolUse hooks; and the full `/aws`, `/aws-spec`, `/aws-doctor` command set.

---

## AWS-200 — scaffold a single-Lambda service with a working CDK stack

**Persona:** A backend engineer prototyping an HTTP webhook handler.

**Trigger:** "Give me a Node.js Lambda behind API Gateway with sensible defaults and a cost ROM."

**Invocation:**

```text
/aws --quick scaffold a Node.js Lambda + API Gateway HTTP webhook with x-ray and CloudWatch logs
```

**What happens:**

- The orchestrator sees a verb-of-creation, escalates to full depth, and fans out the L3 specialists.
- `discovery` calls `kb:search_documentation` for the Lambda + APIGW capability matrix, seeds `requirements.md` at `draft`.
- `solution-architect` writes `design.md` + one component contract per artefact (Lambda function, API Gateway HTTP API, log group), with the `aws-component-contract` skill enforcing the closed `kind` vocabulary and the observability triple (metric / log / trace).
- `implementation` writes `tasks.md` with a CDK skeleton, plus a cost ROM via the `cost` MCP server.
- The `aws-layered-diagram` skill produces `diagrams.d2` with `c4-l1`, `c4-l2`, `c4-l3-<container>` layer tags.

**Why this is production-ready:**

- The component contract is not free-form prose: it is bound to a 21-kind closed vocabulary so a downstream automation can parse it.
- The cost ROM is grounded against `cost:` MCP calls, not invented.
- The `aws-secret-scanner` and `aws-api-write-guard` PreToolUse hooks are loaded by the Power, so the iteration loop is safe even when the engineer pastes credentials by mistake or runs an `aws` write verb.

---

## AWS-300 — design an event-driven order-processing pipeline with full WAF review

**Persona:** A senior engineer owning the order pipeline in a multi-tenant SaaS.

**Trigger:** "Design an event-driven order-processing pipeline. Idempotent, retry-safe, observable, and cost-aware. Cost ceiling $50/month at the current load."

**Invocation:**

```text
/aws --deep design an event-driven order-processing pipeline with idempotency, retry, and a $50/month cost ceiling
```

**What happens:**

- The orchestrator forces full depth via `--deep` and fans out three L3 specialists in a single message (parallel `Agent` calls per the SDLC workflow skill).
- `discovery` populates `requirements.md` and the grounding ledger.
- `solution-architect` produces `design.md` with component contracts for the four pipeline pieces (e.g., EventBridge bus, SQS DLQ, Lambda processor, DynamoDB idempotency table) and runs the `aws-waf-cost-optimization-skill`, `aws-waf-reliability-skill`, and `aws-waf-operational-excellence-skill` reviews against the design.
- `implementation` writes `tasks.md` with a CDK plan, a cost ROM grounded against `cost:` (S3, Lambda, EventBridge, SQS, DynamoDB pricing), and the IaC-validation hooks via `iac:validate_cloudformation_template`.
- The merge contract resolves any specialist disagreements in priority order: security → facts → cost → convergence → recency.
- A canonical reference run already lives at `templates/examples/order-processing-pipeline/` — the Power produces the same shape.

**Why this is production-ready:**

- The merge contract is not aspirational; it is asserted by the orchestrator on every full-depth turn, and any unresolved disagreement surfaces under `## Open Questions` instead of being silently picked.
- WAF pillar skills are not advisory checklists — each pillar's "anti-patterns" list (22–25 items per pillar) is asserted against the design and surfaced as findings.
- Every `<server>:<short-key>` citation in the design is recorded in `.grounding-ledger.json`, and a downstream review (or a tagging audit two quarters later) can re-trace any factual claim.
- A consumer can run `/aws-spec` to validate the produced spec directory against the §11 gates before merging the PR.

---

## AWS-500 — multi-region active-active with quota, cost, and reliability trade-offs

**Persona:** A staff architect under SLA pressure. Existing service runs single-region in `us-east-1`; the business now requires active-active across `us-east-1` and `eu-west-1` with a 99.95% availability target and a $4k/month variance budget.

**Trigger:** "Move the order pipeline to active-active across us-east-1 and eu-west-1. 99.95% target. $4k/month total budget. DynamoDB Global Tables or self-managed cross-region replication, but justify the choice. Surface every quota I will hit."

**Invocation:**

```text
/aws --deep promote the order-processing pipeline to active-active across us-east-1 and eu-west-1, target 99.95%, $4k/month, justify DynamoDB Global Tables vs self-managed replication, surface every account-level quota
```

**What happens:**

- The orchestrator enters full depth at the Design phase (a prior `requirements.md` exists).
- `solution-architect` runs the WAF Reliability and Operational-Excellence pillar skills end-to-end, surfacing the 25 reliability anti-patterns and the 29 ops checklist items as findings against the new topology.
- `implementation` calls `cost:get_pricing` for both regions, sums the ROM, and flags the variance against the $4k/month budget. If the ROM exceeds budget, the cost-pillar skill surfaces the gap as an Open Question rather than silently picking a smaller instance.
- `iac:check_cloudformation_template_compliance` runs on the proposed CDK output via cfn-guard rules; any policy violation is a `## Degraded signals` entry, not a silent fail.
- Quota surfacing comes from `kb:search_documentation` against quota pages — the discovery agent records each ceiling in the ledger, and the design's "Open Questions" lists the ones that need a Service Quotas request.
- A merge conflict (e.g., reliability says "use Global Tables for RPO=0", cost says "self-managed replication is $1.8k cheaper") is resolved by the merge contract priority: security → **facts** → cost → convergence → recency. Facts win against cost when both are grounded; the architect sees the rationale paragraph, not just the verdict.

**Why this is production-ready:**

- **Findings are anti-pattern-cited, not vibes.** Each WAF pillar skill ships with a closed list of anti-patterns; the design either satisfies them or carries an explicit Open Question.
- **Quota gaps surface, not hide.** The discovery ledger entry for a 1k-WCU DynamoDB ceiling is part of the spec, not buried in chat history. CI will catch a spec without it via gate-08 (rules) and gate-09 (agents).
- **Cost ROM is auditable.** Every line item in the ROM is a `cost:<short-key>` citation; the FinOps reviewer can re-derive it.
- **Degraded markers are first-class.** A timeout on `cost:` does not produce an unsigned ROM — it produces a `grounding-deferred` marker the architect must clear before proceeding.
- **Per-environment isolation.** `aws-api-write-guard` blocks any `aws` CLI write verb the implementation specialist might emit by accident; iteration on the design stays purely advisory until the engineer explicitly approves a write.
