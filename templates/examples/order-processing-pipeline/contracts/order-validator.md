---
component: order-validator
kind: lambda
version: 0.1.0
status: review
talks-to:
  - checkout-ingest-api
  - order-history-store
grounded-by:
  - kb:9b2e0c14
  - iam:d4527901
  - cw:e1ff8b22
  - cost:b89d401e
---

## Purpose

Consumes the SQS ingest queue, validates each message against the
canonical order JSON schema, enriches with a customer-tier lookup, and
persists the resulting order to the history store via a single
conditional `PutItem`. Acts as the system's authoritative validation
boundary — the API Gateway request validator is a fast filter, not a
substitute.

## Interface

### Inputs

- Channel: SQS `ReceiveMessage` event-source mapping (batch size 10,
  batch window 1 second).
- Encoding: JSON message body produced by `checkout-ingest-api`.
- Schema reference: `services/order-validator/schema.ts`.

### Outputs

- Channel: DynamoDB `PutItem` against `order-history-store`.
- Encoding: single-table item shaped as
  `{ pk: "ORDER#<orderId>", sk: "METADATA", ...payload, customerTier }`.
- Channel (failure): SQS `SendMessage` to the validator dead-letter
  queue carrying the original message plus a `rejectReason` field.

### Errors

- `SchemaRejection` — payload fails the JSON schema. Message is
  forwarded to the DLQ; no retry.
- `EnrichmentLookupFailed` — customer-tier lookup fails. Message is
  retried up to 3 times by SQS visibility-timeout, then DLQ'd.
- `DuplicateOrder` — conditional `PutItem` rejects a duplicate
  `orderId`. Message is acknowledged and dropped (idempotent no-op).
- `Throttle` — DynamoDB throttling. Surfaced as a Lambda failure so
  SQS retries via visibility timeout.

## Sequence

See `seq-component` in `diagrams.d2`. Happy path: receive → schema
check → enrich → conditional PutItem → ack the SQS message. On any
unexpected exception the handler returns a partial-batch failure item
so SQS only retries the failed records.

## Component view (C4 L3)

References `c4-l3-order-validator` in `diagrams.d2`. Look for the
five-block internal flow: SQS source → handler → schema check →
enricher → persister, with the DLQ branch off the schema check.

## Acceptance criteria

- p99 invocation duration ≤ 800 ms at 100 RPS sustained, including
  enrichment lookup.
- Error rate ≤ 0.5% over a rolling 5-minute window (excluding
  schema rejections, which are expected steady-state behaviour).
- Sustained throughput floor of 100 RPS; SQS event-source mapping
  scales the concurrent execution count automatically.
- IaC repo path: `infrastructure/cdk/lib/order-validator-stack.ts`.
- Test coverage minimum: 90% on `services/order-validator/handler.ts`
  and 100% on `services/order-validator/schema.ts`.

## Observability

### Metric

- `AWS/Lambda` `Duration`, `Errors`, `Throttles`, `ConcurrentExecutions`
  per function name; custom metric `validator.schemaRejection.count`
  emitted as an EMF metric per rejected message.

### Log

- Structured JSON to `/aws/lambda/order-validator` with fields
  `correlationId`, `orderId`, `customerTier`, `outcome`,
  `latencyMs`. Level discipline: per-message outcome at `INFO`,
  schema rejections at `WARN`, unexpected exceptions at `ERROR`.

### Trace

- AWS X-Ray active tracing; the `correlationId` from the SQS message
  body is added as an X-Ray annotation so the trace tree stitches
  back to the API Gateway request.

## Integration points

- **checkout-ingest-api** — protocol: SQS standard queue
  `ReceiveMessage` long-poll; messages are unmodified request payloads
  plus the correlation id; idempotency depends on the conditional
  `PutItem` rejecting duplicate `orderId` values.
- **order-history-store** — protocol: DynamoDB `PutItem` with a
  `ConditionExpression` of `attribute_not_exists(pk)`; retries on
  throttle by SQS visibility-timeout; idempotent by `orderId`.
