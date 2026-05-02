---
component: order-history-store
kind: dynamodb-table
version: 0.1.0
status: review
talks-to:
  - order-validator
  - fulfilment-dispatcher
grounded-by:
  - kb:9b2e0c14
  - cost:b89d401e
  - iam:d4527901
---

## Purpose

Single-table DynamoDB store holding the immutable history of every
accepted order. Provides exactly-once write semantics via conditional
`PutItem` and drives downstream fulfilment via DynamoDB Streams.
Application-layer immutability is enforced by IAM (no `UpdateItem`,
no `DeleteItem`) rather than by table-level configuration.

## Interface

### Inputs

- Channel: DynamoDB `PutItem` from the `order-validator` Lambda role.
- Encoding: single-table item with partition key `pk = ORDER#<orderId>`
  and sort key `sk = METADATA`.
- Schema reference: `infrastructure/cdk/lib/order-history-store-stack.ts`.

### Outputs

- Channel: DynamoDB Streams (view type `NEW_IMAGE`) consumed by the
  fulfilment-dispatcher Lambda event-source mapping.
- Encoding: stream record carrying the new item exactly as written.

### Errors

- `ConditionalCheckFailedException` — duplicate `orderId`. Surfaced to
  the validator, which acknowledges the SQS message as an idempotent
  no-op.
- `ProvisionedThroughputExceededException` — only relevant if the
  table is migrated from on-demand to provisioned in a future
  version; not reachable at v0.1.0.
- `ThrottlingException` — surfaced to the validator, which lets SQS
  retry via visibility timeout.

## Sequence

See `seq-component` in `diagrams.d2`. Happy path: validator submits a
conditional `PutItem` keyed by `orderId`; the table writes the item
and emits a stream record; the dispatcher's event-source mapping
consumes the record and publishes the event.

## Component view (C4 L3)

The table itself has no internal C4 L3 layer (it is a managed
service with no in-account internals). The two consumers'
internals live under `c4-l3-order-validator` and
`c4-l3-fulfilment-dispatcher` in `diagrams.d2`.

## Acceptance criteria

- p99 `PutItem` latency ≤ 25 ms at 100 RPS sustained.
- Read latency irrelevant at v0.1.0 — no synchronous reads against the
  table from inside the pipeline.
- Sustained write throughput floor of 100 WCU/s with on-demand
  capacity mode.
- IaC repo path: `infrastructure/cdk/lib/order-history-store-stack.ts`.
- Test coverage minimum: 100% on the schema validator that proves
  every accepted item satisfies the table's primary-key shape.

## Observability

### Metric

- `AWS/DynamoDB` `SuccessfulRequestLatency`, `UserErrors`,
  `SystemErrors`, `ConditionalCheckFailedRequests`, plus
  `ReturnedItemCount` on the stream consumer; alarm on
  `SystemErrors > 0` for 1 minute.

### Log

- DynamoDB does not produce native logs. Stream-consumer log entries
  for each propagated record are emitted by the
  fulfilment-dispatcher to `/aws/lambda/fulfilment-dispatcher` and
  carry the `correlationId`.

### Trace

- The DynamoDB API call is captured as an X-Ray segment by the
  upstream validator's tracer and as a downstream segment by the
  dispatcher's stream-source mapping.

## Integration points

- **order-validator** — protocol: DynamoDB `PutItem` with a
  `ConditionExpression`; payload is the validated and enriched order
  item; idempotency is provided by the condition.
- **fulfilment-dispatcher** — protocol: DynamoDB Streams
  `GetRecords`/`GetShardIterator` via the dispatcher's event-source
  mapping; payload is the new image only; retries are handled by the
  event-source mapping with a configured DLQ on the dispatcher side.
