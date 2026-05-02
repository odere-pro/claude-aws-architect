---
name: aws-component-contract
description: |
  **WORKFLOW SKILL** — Author and lint per-component contract files
  under `.claude/specs/<feature>/contracts/<slug>.md`. Enforces
  required frontmatter, body section ordering, integration-link
  validity, and the metric/log/trace observability triple.
version: 0.1.0
---

## When to Use

Apply this skill any time an agent writes, edits, or reviews a component contract — the per-component design artefact that ships with every generated AWS component. The solution-architect agent emits these at design time; the implementation agent fills in the IaC, cost, security, and observability sections; reviewers lint them before status transitions to `accepted` or `implemented`.

Trigger conditions:

- The agent is creating a new file under `.claude/specs/<feature>/contracts/<slug>.md`.
- The agent is editing an existing contract and needs to confirm the section order is preserved.
- The agent is filling in the `talks-to` array and needs to verify the named slugs resolve to sibling contracts in the same feature.
- The agent is filling in the Observability section and needs to confirm the metric/log/trace triple is complete.
- The agent is performing a pre-acceptance review and needs to lint every contract under the feature.

## Procedure

1. **Place the file at the canonical path.** `.claude/specs/<feature>/contracts/<component-slug>.md`. The component slug is lowercase-kebab-case, ≤50 chars, matches `^[a-z][a-z0-9-]*[a-z0-9]$`. If creating, use `assets/contract.md.tmpl` as the starting structure.
2. **Populate the frontmatter.** Required keys per `references/contract-schema.md`: `component`, `kind`, `version`, `status`, `talks-to` (array, may be empty if no siblings), `grounded-by` (array, ≥1 entries in `<server>:<short-key>` format).
3. **Maintain section order.** The body has seven sections in this exact order: Purpose, Interface, Sequence, Component view (C4 L3), Acceptance criteria, Observability, Integration points. No reorder, no merge, no rename.
4. **Resolve `talks-to` integration links.** Every slug in `talks-to` must reference an existing contract file under the same feature's `contracts/` directory. Dangling references are a lint failure.
5. **Complete the observability triple.** The Observability section requires three subsections — Metric, Log, Trace — each populated with at least one concrete signal name and source. Empty triples are a lint failure; "TBD" is not a valid signal. Detail in `references/observability-triple.md`.
6. **Cite the grounding.** The `grounded-by` array must contain at least one valid `<server>:<short-key>` citation pointing to a ledger entry that justifies the component's choice of service, quota assumption, or pricing assumption.

## Gotchas

- **Do not invent a `kind` value.** The `kind` field is closed: one of `lambda`, `ecs-service`, `ecs-task`, `fargate-service`, `step-function`, `dynamodb-table`, `s3-bucket`, `rds-instance`, `aurora-cluster`, `sqs-queue`, `sns-topic`, `eventbridge-rule`, `apigw-rest`, `apigw-http`, `cloudfront-distribution`, `vpc`, `subnet`, `security-group`, `iam-role`, `kms-key`, `secrets-manager-secret`. Other AWS resources at v0.1.0 are out of scope and the contract format does not yet describe them. Components that do not fit any kind (e.g., Kinesis streams, ElastiCache, Cognito, AppSync, CodePipeline) belong as informal notes in `design.md` at the feature root, not as a contract file.
- **Do not embed diagrams in the contract.** Diagrams live in `diagrams.d2` at the feature root with their layer tags. The contract's "Component view (C4 L3)" section references the diagram's `c4-l3-<container>` tag; the diagram itself is not duplicated inside the contract.
- **Do not skip Acceptance criteria for read-only components.** Even a read-only component has acceptance criteria (latency budget, error rate, throughput floor); skipping the section is a lint failure.
- **Do not write sections out of order, even if a section is empty-but-present.** A contract with the seven section headings in the right order, with one or two sections containing only a placeholder, lints further than a contract that re-orders sections to omit empties.
- **Do not bypass the `grounded-by` minimum.** A contract with an empty `grounded-by` array fails the lint. If no MCP citation grounds the component yet, the contract is not ready to ship — it is still in discovery.
- **Do not mix integration-point prose with the `talks-to` array.** The Integration points section describes _how_ this component talks to its siblings (event shape, retry semantics, idempotency); the `talks-to` frontmatter array names _which_ siblings. Both are required and they answer different questions.

## Boundaries

- This skill MUST NOT generate the IaC (CloudFormation, CDK) for the component. IaC is the implementation agent's responsibility, written into the contract's Acceptance criteria section as references to repo paths.
- This skill MUST NOT compute pricing or cost ranges. Cost figures cite the `cost` MCP server via `grounded-by` entries; this skill verifies citations exist, not their numeric content.
- This skill MUST NOT validate the truth of `grounded-by` entries; pointer resolution is `aws-grounding-cache`'s job and TTL is the cache's job.
- This skill MUST NOT auto-fix a missing observability triple. A missing triple is a real signal that the design has not yet considered observability; auto-filling with placeholders defeats the lint.
- This skill MUST NOT apply to contracts outside the canonical path. Files at `.claude/specs/<feature>/contracts/*.md` are in scope; everything else is out of scope, including doc/ examples and templates.
- This skill MUST NOT introduce new top-level body sections. The seven canonical sections are exhaustive at v0.1.0; additions require a documented schema change.

## Quality Checks

Before returning a contract decision, confirm:

- The file path matches `.claude/specs/<feature>/contracts/<slug>.md` and the slug matches the regex.
- The frontmatter contains `component`, `kind`, `version`, `status`, `talks-to`, `grounded-by`. No additional top-level keys.
- `kind` is one of the closed-vocabulary values.
- `status` is one of `draft`, `review`, `accepted`, `implemented`.
- `grounded-by` has ≥1 entry and each entry matches the `<server>:<short-key>` regex with `<server>` in `kb`, `iac`, `cost`, `sec`, `iam`, `cw`.
- The body has the seven sections in canonical order, no extras, no missing.
- The Observability section has populated Metric, Log, and Trace subsections — each with a real signal name, not `TBD`, `TODO:`, or any unfilled `<angle-bracket>` template token.
- Every slug in `talks-to` resolves to an existing sibling contract file in the same feature.
- The Integration points section narrates the protocol/event-shape for each `talks-to` slug, not just listing them.
- If `status` is `implemented`: Acceptance criteria contains ≥1 IaC repo path that is not a placeholder.
- If `status` is `implemented`: every slug in `talks-to` has been re-confirmed to resolve at this transition (since dangling references can be introduced by sibling contracts moving or being deleted between `accepted` and `implemented`).
