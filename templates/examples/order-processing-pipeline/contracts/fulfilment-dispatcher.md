---
component: fulfilment-dispatcher
kind: lambda
version: 0.1.0
status: review
talks-to:
  - order-history-store
grounded-by:
  - kb:7a3c2f1d
  - iam:d4527901
  - cw:e1ff8b22
---

## Purpose

Consumes the DynamoDB stream from `order-history-store` and publishes
exactly one `order.accepted` event per item to the existing fulfilment
EventBridge bus. The pipeline's egress boundary; no application logic
reads from this component, only the downstream fulfilment system.

## Interface

### Inputs

- Channel: DynamoDB Streams event-source mapping (view type
  `NEW_IMAGE`, batch size 100, batch window 1 second).
- Encoding: stream records carrying the new item exactly as the
  validator wrote it.

### Outputs

- Channel: EventBridge `PutEvents` against the existing fulfilment
  bus.
- Encoding: `{ "Source": "com.example.orders", "DetailType":
"order.accepted", "Detail": "<JSON-stringified order>" }`.

### Errors

- `EventBridge.ThrottlingException` — surfaced as a partial-batch
  failure so the event-source mapping retries; persistent throttling
  flows to the dispatcher DLQ.
- `EventBridge.InternalFailure` — same handling as throttling; logged
  at `ERROR`.
- `RecordDeserializationFailed` — unrecoverable; record is forwarded
  to the dispatcher DLQ for forensic analysis with no retry.

## Sequence

See `seq-system` for the L1 view of the egress and `seq-component`
for the upstream validator path. Dispatcher path: stream record →
deserialize → build event → batched `PutEvents` (up to 10 entries
per call to amortise the per-call cost).

## Component view (C4 L3)

References `c4-l3-fulfilment-dispatcher` in `diagrams.d2`. Look for
the stream-source → handler → event-builder → bus-publisher chain
with the DLQ branch on the publisher edge.

## Acceptance criteria

- p99 invocation duration ≤ 400 ms per stream-shard batch.
- Error rate ≤ 0.1% over a rolling 5-minute window.
- End-to-end pipeline latency from `PutItem` to `PutEvents` success
  ≤ 5 s p99 (combined with the validator path satisfies AC-3 in
  `requirements.md`).
- IaC repo path: `infrastructure/cdk/lib/fulfilment-dispatcher-stack.ts`.
- Test coverage minimum: 90% on
  `services/fulfilment-dispatcher/handler.ts`.

## Observability

### Metric

- `AWS/Lambda` `Duration`, `Errors`, `Throttles`,
  `IteratorAge` (critical — alarms on `IteratorAge > 60_000` for 3
  consecutive 1-minute periods); custom metric
  `dispatcher.eventbridge.throttle.count` emitted as an EMF metric.

### Log

- Structured JSON to `/aws/lambda/fulfilment-dispatcher` with fields
  `correlationId`, `orderId`, `recordCount`, `outcome`,
  `latencyMs`. Level discipline: per-batch outcome at `INFO`,
  per-record EventBridge throttles at `WARN`, deserialisation
  failures at `ERROR`.

### Trace

- AWS X-Ray active tracing; the `correlationId` from the stream
  record is added as an X-Ray annotation on every span so traces
  stitch from API Gateway through to EventBridge.

## Integration points

- **order-history-store** — protocol: DynamoDB Streams
  `GetRecords`/`GetShardIterator`/`ListStreams` consumed via the
  Lambda event-source mapping; idempotency relies on the upstream
  conditional `PutItem` ensuring each `orderId` appears in the stream
  exactly once.
