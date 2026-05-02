---
feature: order-processing-pipeline
created: 2026-05-02
updated: 2026-05-02
status: review
grounded-by:
  - kb:7a3c2f1d
  - kb:9b2e0c14
  - iac:c021ee4a
  - cost:b89d401e
  - iam:d4527901
  - cw:e1ff8b22
---

# Design — order processing pipeline

The pipeline is event-driven. A REST API accepts checkout payloads
synchronously and hands them to an SQS queue; a validator Lambda
consumes the queue, enriches the payload with a customer-tier lookup,
and writes the order to an immutable DynamoDB table. The DynamoDB
stream drives a dispatcher Lambda that publishes one
`order.accepted` event per item to the existing fulfilment
EventBridge bus.

## Architecture overview

- **Pattern**: event-driven via queue + DynamoDB stream + EventBridge.
- **Boundary**: ingress is the API Gateway REST API behind the existing
  CloudFront distribution; egress is the fulfilment EventBridge bus
  owned by another team.
- **Region strategy**: single region `us-east-1`. Carbon tier T1 per the
  carbon-tier policy (default tier — no deviation rationale required).
- **Data classification**: internal. Order payloads contain customer
  identifiers and addresses but no payment data; PCI scope excluded by
  request-validator schema rejection of PAN-shaped fields.

Reference the layered diagram at `diagrams.d2`:

- `c4-l1` — system context: storefront → pipeline → fulfilment bus.
- `c4-l2` — runtime containers: ingest API, validator, history store,
  dispatcher.
- `c4-l3-checkout-ingest-api` — ingest API internals.
- `c4-l3-order-validator` — validator internals.
- `c4-l3-fulfilment-dispatcher` — dispatcher internals.
- `seq-system`, `seq-component`, `seq-error` — sequence views.

## Components

Every component named here has a matching contract under `contracts/`.

- **checkout-ingest-api** — public REST API receiving `POST /checkout`,
  fronted by AWS WAF, with API Gateway service integration to SQS so the
  ingest path stays Lambda-free at v0.1.0. See
  `contracts/checkout-ingest-api.md`.
- **order-validator** — Lambda consumer that validates the payload
  against a JSON schema, enriches with a customer-tier lookup, and
  writes the order to the history store. See
  `contracts/order-validator.md`.
- **order-history-store** — DynamoDB table holding the immutable order
  history with PITR and DynamoDB Streams enabled. See
  `contracts/order-history-store.md`.
- **fulfilment-dispatcher** — Lambda triggered by the DynamoDB stream
  that publishes one `order.accepted` event to the fulfilment
  EventBridge bus per item. See `contracts/fulfilment-dispatcher.md`.

## Design choices

- **Decision: Lambda-free ingest path**
  - Chosen: API Gateway service integration writes directly to SQS.
  - Alternatives: API Gateway → Lambda → SQS; API Gateway → Kinesis.
  - Rationale: the ingest path has no validation logic that needs to
    run synchronously; deferring validation to the consumer keeps the
    p99 latency budget achievable and removes a source of cold-start
    variance. Cost rule (cost over convergence) prefers the
    Lambda-free path because it removes a per-request Lambda invocation.
  - grounded-by: `kb:7a3c2f1d`

- **Decision: DynamoDB single-table, immutable append**
  - Chosen: one table keyed by `pk = ORDER#<orderId>` and
    `sk = METADATA` with PITR enabled, no item-level deletes at the
    application layer.
  - Alternatives: RDS append-only ledger; S3 + Glue; DynamoDB with
    deletes allowed and a separate audit table.
  - Rationale: DynamoDB matches the AC-1 latency budget at the
    validator stage and provides streams natively for the dispatcher
    fan-out. Item-level immutability is enforced via the validator IAM
    role granting only `dynamodb:PutItem` (no `UpdateItem`/`DeleteItem`).
  - grounded-by: `kb:9b2e0c14`

- **Decision: EventBridge for fan-out instead of SNS**
  - Chosen: publish `order.accepted` events to the fulfilment
    EventBridge bus with a content-based event filter on the consumer
    side.
  - Alternatives: SNS topic with subscriptions; direct invocation of
    fulfilment Lambdas.
  - Rationale: the fulfilment-system operator already consumes other
    `com.example.*` event sources from the same bus; reusing the bus
    avoids a parallel topology and matches the existing operational
    model.
  - grounded-by: `kb:7a3c2f1d`

- **Decision: SQS standard queue, not FIFO**
  - Chosen: SQS standard with idempotency enforced at the validator.
  - Alternatives: SQS FIFO with deduplication ID per orderId.
  - Rationale: standard queue throughput is unlimited where FIFO is
    capped at 300 TPS per group without high-throughput mode, and the
    AC-3 exactly-once requirement is satisfied at the DynamoDB layer
    via conditional `PutItem` on the orderId primary key — duplicate
    deliveries from the standard queue collapse to a no-op write.
  - grounded-by: `kb:9b2e0c14`

## Per-pillar review

### Operational excellence

- Status: PASS.
- Top finding: every component emits structured JSON logs to
  CloudWatch Logs with a shared correlation-id field; the dispatcher
  propagates the correlation id into the EventBridge event detail so
  downstream traces stitch end-to-end.

### Security

- Status: PASS.
- Top finding: every IAM role grants the minimum action set; the
  validator role's DynamoDB statement is restricted to `PutItem` on
  the table ARN, with no `*` actions and no cross-table access. The
  request-validator at API Gateway rejects PAN-shaped fields before
  any payload reaches application code.

### Reliability

- Status: PASS.
- Top finding: a dead-letter queue is attached to both Lambdas; the
  validator DLQ catches schema-rejection cases for forensic analysis,
  and the dispatcher DLQ catches EventBridge throttling. PITR is
  enabled on the history store with a 35-day window.

### Performance efficiency

- Status: PASS.
- Top finding: the validator Lambda is sized at 512 MB with arm64
  Graviton; cold-start p99 is within budget at the configured
  provisioned-concurrency floor of 5 instances.

### Cost optimization

- Status: PASS.
- Top finding: monthly ROM at the AC-1 throughput is USD 142,
  comfortably below the USD 200 ceiling; the dominant line items are
  DynamoDB on-demand writes (USD 58) and Lambda compute (USD 41).

### Sustainability

- Status: PASS.
- Top finding: arm64 Graviton on both Lambdas; no idle compute (all
  resources are pay-per-use); no scheduled batch warmers.

## Open questions

None at status `review`.

## Degraded signals

None at status `review`.
