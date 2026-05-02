---
component: checkout-ingest-api
kind: apigw-rest
version: 0.1.0
status: review
talks-to:
  - order-validator
grounded-by:
  - kb:7a3c2f1d
  - iam:d4527901
  - cw:e1ff8b22
---

## Purpose

Public REST API that accepts checkout payloads from the storefront,
validates them at the edge with a JSON schema, and forwards every
accepted message directly to the SQS ingest queue. Stays Lambda-free
on the request path to keep p99 latency inside the AC-1 budget.

## Interface

### Inputs

- Channel: HTTPS `POST /checkout`, fronted by AWS WAF.
- Encoding: `application/json`.
- Schema reference: `infrastructure/api/checkout-request-schema.json`.
  Required fields: `orderId` (UUID v4), `customerId`, `items[]`,
  `paymentReference` (tokenised; PAN-shaped values rejected at the
  validator).

### Outputs

- Channel: SQS `SendMessage` to the ingest queue via API Gateway
  service integration.
- Encoding: JSON message body identical to the request payload, with
  the `correlationId` populated from the API Gateway request id.
- Synchronous response: HTTP 202 with body `{ "orderId": "<uuid>" }`.

### Errors

- `400 Bad Request` — schema validation failure at the request
  validator. The error body lists each violated path.
- `403 Forbidden` — AWS WAF block.
- `429 Too Many Requests` — WAF rate-based rule trigger.
- `503 Service Unavailable` — SQS unavailable; surfaces as a generic
  503 to the client without leaking AWS error detail.

## Sequence

See `seq-system` for the cross-boundary view and `seq-component` for
the internal sequence. Happy path: WAF → API Gateway → request
validator → SQS service integration → 202. No application code runs
on the ingest path at v0.1.0.

## Component view (C4 L3)

References `c4-l3-checkout-ingest-api` in `diagrams.d2`. Look for the
WAF → API Gateway → request-validator → SQS-integration chain; the
absence of a Lambda node on this layer is intentional and reflects the
"Lambda-free ingest path" decision in `design.md`.

## Acceptance criteria

- p99 ≤ 250 ms from request receipt to 202 response at 100 RPS
  sustained.
- 5xx rate ≤ 0.1% over a rolling 5-minute window.
- Sustained throughput floor of 100 RPS, peak 500 RPS for 60 seconds.
- IaC repo path: `infrastructure/cdk/lib/checkout-ingest-api-stack.ts`.
- Test coverage minimum: 90% on the request-mapping templates and the
  schema fixture.

## Observability

### Metric

- `AWS/ApiGateway` `Count`, `Latency`, `4XXError`, `5XXError` filtered
  by API name and stage; alarm on `Latency p99 > 250 ms` for 3 of 5
  consecutive 1-minute periods.

### Log

- API Gateway access logs to `/aws/apigateway/checkout-ingest-api`
  with structured JSON fields: `requestId`, `correlationId`,
  `sourceIp`, `status`, `integrationLatency`, `responseLatency`. Level
  discipline: access logs at `INFO`; integration errors at `ERROR`.

### Trace

- AWS X-Ray active tracing on the API Gateway stage; `correlationId`
  propagated as an X-Ray annotation so downstream traces stitch.

## Integration points

- **order-validator** — protocol: SQS standard queue, message body is
  the unmodified request payload plus the correlation id; retries are
  the SQS visibility timeout default; idempotency is enforced
  downstream by conditional `PutItem` on `orderId`.
