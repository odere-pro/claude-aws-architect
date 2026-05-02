# Observability triple

Loaded on demand by the `aws-component-contract` skill. Defines the three-signal observability requirement for every component contract: a metric, a log, and a trace, each concrete and named.

## Why three signals

Observability lives on three legs: metrics tell you _what is happening at scale_, logs tell you _what happened in this specific request_, traces tell you _how a request crossed component boundaries_. A component instrumented for only one or two of these has known blind spots that surface as outages without diagnostics. The contract format makes the triple a hard requirement so the design conversation cannot defer observability to "later" — by definition there is no contract until the triple exists.

## Required subsections

The Observability section of a contract has exactly three subsections, in this order:

1. **Metric**
2. **Log**
3. **Trace**

Each subsection lists ≥1 concrete signal. "TBD", "to be defined", or an empty bullet list fails the lint. A placeholder defeats the purpose: a contract that says "metrics: TBD" passes the structural check while leaving the design defect (no metrics designed) invisible. The lint catches the placeholder explicitly.

## What counts as a "concrete signal"

### Metric

A named CloudWatch (or equivalent) metric with:

- **Name** — the metric identifier (e.g., `InvocationsCount`, `Errors`, `Duration.p99`).
- **Source** — the namespace or component that emits it (e.g., `AWS/Lambda`, `Custom/PaymentsAPI`).
- **Threshold/SLO** (recommended, not required) — the value at which alerting fires.

Examples:

- `Duration.p99` from `AWS/Lambda` for `payments-handler`, alerts at >800ms over 5 minutes.
- `Custom/PaymentsAPI/ChargeFailureRate` emitted by the handler, alerts at >0.5% over 10 minutes.
- `AWS/SQS/ApproximateAgeOfOldestMessage` for the dead-letter queue, alerts at >300s.

### Log

A log destination and a structured field that distinguishes meaningful events:

- **Destination** — log group or stream (e.g., `/aws/lambda/payments-handler`, `/ecs/payments-service`).
- **Structured field** — at minimum a correlation ID and an event-type discriminator (e.g., `event_type=charge_failed`, `event_type=charge_succeeded`).
- **Level discipline** — explicit statement that errors log at `ERROR`, warnings at `WARN`, no `INFO` for routine paths.

Examples:

- `/aws/lambda/payments-handler` with structured JSON, fields `correlation_id`, `event_type`, `error_code`, `latency_ms`.
- `/ecs/payments-service/access` with combined log format including request ID.

### Trace

A tracing strategy that crosses the component boundary:

- **Tracer** — X-Ray, OpenTelemetry, or equivalent (named).
- **Propagation** — how the trace ID enters and exits this component (header, attribute, message metadata).
- **Sampled vs always-on** — the sampling rule (e.g., 10% of healthy traffic, 100% of errors).

Examples:

- AWS X-Ray with active tracing on the Lambda; trace ID propagated via `X-Amzn-Trace-Id` header to downstream services.
- OpenTelemetry on the ECS service emitting OTLP to ADOT collector; sampling 5% of healthy + 100% of 5xx.

## What does NOT count

- **"We will use CloudWatch"** — name a metric, not a service.
- **"Logs go to CloudWatch Logs"** — name a log group or stream, plus the structured fields.
- **"Tracing is enabled"** — name the tracer and the propagation strategy.
- **"Default Lambda metrics are sufficient"** — even if true, name the specific default metrics being relied on (`Invocations`, `Errors`, `Duration`); the contract is a record of the _design choice_, not a wave-off.
- **A single metric with no log or trace** — partial triples are not allowed; the contract structurally requires three.
- **An unfilled template placeholder** — `TODO:`, `TBD`, `<metric-name>`, or any other unreplaced token is not a concrete signal. The lint matches `TODO`, `TBD`, and unfilled angle-bracket tokens equally.

## Why the lint refuses to auto-fill

The temptation is to insert "TBD" placeholders to pass the structural check. The lint refuses this for the same reason a draft requirements doc with "TBD acceptance criteria" is not actually accepted: the missing detail is the _real signal_ that the design is incomplete. Fill in real signals or leave the contract in `draft` status.

## Interaction with the cw MCP server

The `cw` (CloudWatch) MCP server provides post-deploy observability evidence — alarm history, log queries, metric data — and is consumed by post-deploy reviewers, not by this skill. This skill validates that the _design_ names the triple. Whether the deployed system actually emits those signals is a runtime question for the test-engineer agent (deferred to v0.2).

## When the cw server is degraded

If a contract reviewer wanted to verify against current alarms but the `cw` server is unreachable, the structural lint of the contract still passes — because this skill checks the _design_, not the runtime evidence. A separate marker (`observability-incomplete`) is emitted by the `cw`-consuming agent if the live evidence cannot be retrieved.
