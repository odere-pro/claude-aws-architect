---
feature: order-processing-pipeline
created: 2026-05-02
updated: 2026-05-02
status: review
grounded-by:
  - iac:c021ee4a
  - iam:d4527901
  - cw:e1ff8b22
---

# Tasks — order processing pipeline

Implementation backlog for the design in `design.md`. Every task traces
back to one or more acceptance criteria (`AC-N`) and to the relevant
component contracts.

## Conventions

- Task IDs are stable: `T-<NN>` ordered by intended sequence.
- Status values: `todo`, `in-progress`, `blocked`, `done`.
- Each task names the AC(s) and contract(s) it advances. Tasks without
  a traceability target are rejected by the implementation agent.

## Tasks

### T-01 — Provision the API Gateway REST API with SQS service integration

- Status: `todo`.
- Traces to: AC-1, AC-2, `contracts/checkout-ingest-api.md`.
- Outputs: `infrastructure/cdk/lib/checkout-ingest-api-stack.ts`,
  request-validator JSON schema under
  `infrastructure/api/checkout-request-schema.json`.
- Risks: API Gateway request-mapping templates can silently truncate
  payload fields if the integration request template is wrong; the
  cost pillar flagged a soft monthly-cost cap that requires a Budgets
  alarm at USD 160 (80% of the AC-5 envelope).
- Notes: WAF rate-based rule defaults to 2,000 requests per 5 minutes
  per source IP at v0.1.0; tune in v0.2 once production traffic shapes
  are known.

### T-02 — Provision the SQS ingest queue and dead-letter queue

- Status: `todo`.
- Traces to: AC-2, AC-3, `contracts/checkout-ingest-api.md`,
  `contracts/order-validator.md`.
- Outputs: `infrastructure/cdk/lib/ingest-queue-stack.ts`.
- Risks: standard queue duplicate deliveries depend on idempotent
  DynamoDB writes downstream — verified by V-01.
- Notes: visibility timeout set to 30 s, matching the validator Lambda
  timeout plus margin.

### T-03 — Provision the order-validator Lambda with arm64 Graviton

- Status: `todo`.
- Traces to: AC-3, AC-6, `contracts/order-validator.md`.
- Outputs: `infrastructure/cdk/lib/order-validator-stack.ts`,
  `services/order-validator/handler.ts`,
  `services/order-validator/schema.ts`,
  `services/order-validator/__tests__/handler.test.ts`.
- Risks: cold-start p99 on Graviton arm64 with 512 MB and a TypeScript
  bundle is at the upper edge of the latency budget; provisioned
  concurrency floor of 5 instances offsets this and is included in the
  cost ROM.
- Notes: validator role is scoped to `dynamodb:PutItem` on the
  history-store ARN only — no `UpdateItem`, no `DeleteItem`, no `*`.

### T-04 — Provision the order-history-store DynamoDB table

- Status: `todo`.
- Traces to: AC-4, `contracts/order-history-store.md`.
- Outputs: `infrastructure/cdk/lib/order-history-store-stack.ts`.
- Risks: PITR adds a recurring cost line; included in the cost ROM at
  USD 8 / month.
- Notes: streams enabled with `NEW_IMAGE` view type — the dispatcher
  only needs the new item to publish the event.

### T-05 — Provision the fulfilment-dispatcher Lambda

- Status: `todo`.
- Traces to: AC-3, AC-6, `contracts/fulfilment-dispatcher.md`.
- Outputs: `infrastructure/cdk/lib/fulfilment-dispatcher-stack.ts`,
  `services/fulfilment-dispatcher/handler.ts`,
  `services/fulfilment-dispatcher/__tests__/handler.test.ts`.
- Risks: EventBridge `PutEvents` is capped at 240 events per second
  per region by default; well within AC-1 throughput but the dispatcher
  batches DynamoDB stream records to amortise the call.
- Notes: dispatcher role is scoped to `events:PutEvents` on the
  fulfilment bus ARN only and `dynamodb:GetRecords`/`GetShardIterator`
  /`ListStreams` on the history-store stream ARN.

### T-06 — Wire CloudWatch alarms and the operational dashboard

- Status: `todo`.
- Traces to: AC-1, AC-3, AC-5,
  `contracts/checkout-ingest-api.md`,
  `contracts/order-validator.md`,
  `contracts/fulfilment-dispatcher.md`.
- Outputs: `infrastructure/cdk/lib/observability-stack.ts`.
- Risks: log volume at 100 RPS sustained sits inside the CloudWatch
  Logs free tier monthly only with the 30-day retention default; the
  cost ROM assumes 90-day retention on a separate analysis log group.
- Notes: alarms set per the per-component Observability sections in
  the contracts.

## Validation tasks

- **V-01** — Idempotency proof: a duplicated SQS delivery (same
  `orderId`) results in a single DynamoDB item and a single
  EventBridge event. Asserted by an integration test that injects a
  duplicate message into a local LocalStack queue.
- **V-02** — IAM minimum-actions proof: every role's policy is
  asserted against `iam:simulate_principal_policy` for both an
  expected-allow action and an expected-deny action; the simulation
  fixtures live under `services/<component>/__tests__/iam-sim.json`.
- **V-03** — Acceptance trace: every `AC-<N>` row in
  `requirements.md` resolves to at least one task above; CI script
  emits the trace report on every PR touching `requirements.md` or
  this file.
