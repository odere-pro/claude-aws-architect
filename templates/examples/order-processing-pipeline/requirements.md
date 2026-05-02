---
feature: order-processing-pipeline
created: 2026-05-02
updated: 2026-05-02
status: review
grounded-by:
  - kb:7a3c2f1d
  - kb:9b2e0c14
  - cost:b89d401e
  - iam:d4527901
---

# Requirements — order processing pipeline

A merchant-facing checkout API ingests order events from the storefront,
validates and enriches them, persists an immutable history, and triggers
fulfilment downstream. Today the storefront writes directly to a single
RDS instance with no audit trail and no decoupling between checkout
and fulfilment; that coupling is the failure mode this feature replaces.

## Context

- The pipeline serves a single storefront in a single AWS account, region
  `us-east-1`. Multi-region is out of scope at v0.1.0 and is called out
  under "Out of scope" below.
- The downstream fulfilment system is an existing internal service that
  already consumes EventBridge events; this feature's responsibility ends
  at the EventBridge bus boundary.
- The feature lives behind the existing public CloudFront distribution;
  no new edge surface is introduced.

## User stories

- As a checkout client, I want to submit a checkout payload over HTTPS
  and receive a synchronous acknowledgement that the order has been
  accepted, so that the storefront can show the customer a confirmation
  page without waiting for fulfilment.
- As an operations engineer, I want an immutable, queryable history of
  every order accepted by the pipeline, so that I can reconstruct the
  state of any order without replaying upstream traffic.
- As a fulfilment-system operator, I want each accepted order to surface
  exactly once on the fulfilment EventBridge bus, so that I can drive
  downstream workflows without de-duplication logic of my own.

## Acceptance criteria

Each criterion is testable, traceable, and grounded.

- **AC-1** — `POST /checkout` returns HTTP 202 within p99 ≤ 250 ms under
  100 sustained requests per second.
  - grounded-by: `kb:7a3c2f1d`
- **AC-2** — Every accepted request is durably enqueued before the 202
  response is returned; no in-memory-only acknowledgement path exists.
  - grounded-by: `kb:9b2e0c14`
- **AC-3** — Each accepted order produces exactly one `order.accepted`
  event on the fulfilment EventBridge bus within 5 seconds of the
  client receiving the 202.
  - grounded-by: `kb:7a3c2f1d`
- **AC-4** — The order history store retains every accepted order with
  point-in-time recovery enabled and item-level deletes disabled
  (immutable append-only at the application layer).
  - grounded-by: `kb:9b2e0c14`
- **AC-5** — End-to-end pipeline cost stays under USD 200 per month at
  the AC-1 throughput level (Lambda + SQS + DynamoDB + API Gateway +
  EventBridge + CloudWatch combined).
  - grounded-by: `cost:b89d401e`
- **AC-6** — Every IAM role in the pipeline grants the minimum action
  set needed for its function; no `Action: "*"` and no
  `Resource: "*"` outside the read-only carve-out for CloudWatch Logs.
  - grounded-by: `iam:d4527901`

## Non-functional requirements

- **Availability**: 99.9% monthly availability for the public ingestion
  surface measured at the API Gateway boundary.
- **Latency**: p99 ≤ 250 ms for `POST /checkout` end-to-end at 100 RPS
  sustained, p99 ≤ 5 s end-to-end pipeline (ingest → EventBridge).
- **Throughput**: 100 RPS sustained, 500 RPS peak for 60 seconds.
- **Cost envelope**: USD 200 per month at sustained throughput per AC-5.
- **Compliance**: PCI-DSS scope is excluded — the feature accepts a
  pre-tokenised payment reference only, never raw card data, and the
  order payload schema rejects PAN-shaped fields at the API Gateway
  request validator.

## Constraints and assumptions

- **Constraint**: Region is `us-east-1`. Multi-region failover is
  deferred; carbon tier T1 per the carbon-tier policy.
- **Constraint**: All resources tagged with the four mandatory cost
  allocation keys: `cost-center`, `service`, `environment`, `owner`.
- **Assumption**: The fulfilment EventBridge bus already exists in the
  same account and accepts events from the source `com.example.orders`.
- **Assumption**: Upstream traffic is well-behaved at v0.1.0; rate
  limiting is the AWS WAF default rate-based rule, not a tuned policy.

## Out of scope

- Multi-region active-active. Deferred until DR objectives drive a
  recovery-region requirement.
- Synchronous order enrichment from third-party catalog services.
  Enrichment at v0.1.0 is limited to fields already in the request
  payload plus a customer-tier lookup against an existing DynamoDB
  table owned by another team.
- Refund and cancellation flows. The pipeline accepts new orders only;
  amendments are a separate feature.

## Open questions

None at status `review`. Any new question raised after this point must
be recorded here with a citation on each side and resolved before status
advances to `accepted`.
