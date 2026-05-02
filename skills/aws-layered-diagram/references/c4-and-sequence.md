# C4 and sequence layers

Loaded on demand by the `aws-layered-diagram` skill. Defines what each C4 level and sequence layer represents at the level of "what belongs in this view, what does not".

## C4 model recap

The C4 model layers a software architecture into four nested zoom levels. This skill uses three of them; L4 (code) is intentionally out of scope.

| Level | Audience                          | Granularity                                                        | What is shown                                                                |
| ----- | --------------------------------- | ------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| L1    | Anyone (executive, end-user, dev) | One box for the whole system; surrounding actors/external systems. | "What is this system, and who/what touches it?"                              |
| L2    | Tech leads, architects            | Containers — independently runnable/deployable units.              | "What runtime processes make up the system, and how do they connect?"        |
| L3    | Developers on this container      | Components inside a single container.                              | "What are the major modules of this container, and how do they collaborate?" |
| L4    | (out of scope at v0.1.0)          | Code-level classes/functions.                                      | Not shown.                                                                   |

The temptation is to skip L1 ("everyone knows what the system does") or L3 ("the container is small"). Both lead to gaps: L1 makes external integrations explicit and forces naming the system's boundary; L3 forces module-level decisions to surface in the design rather than appear unannounced in code review.

## L1 — system context

Required nodes:

- One box: the system itself, named exactly as the feature is named.

Allowed nodes:

- External human actors (end users, operators, support agents).
- External systems (third-party APIs, partner SaaS, AWS services that sit _outside_ this system's boundary — e.g., a managed Cognito user pool that is not provisioned by this feature).

What does NOT belong in L1:

- Any container internal to the system. The internals are L2's job.
- Sequence-of-events arrows. L1 shows static relationships, not workflow.

## L2 — containers

Required nodes:

- One per container. A container is an independently runnable/deployable runtime: a Lambda function, an ECS service, a Fargate task, a Step Functions state machine, a DynamoDB table, an S3 bucket, a queue, a topic, an API Gateway, etc.

Allowed nodes:

- The boundary of the system (often shown as a containing group that frames all the containers).
- External systems re-shown from L1, when they participate as direct dependencies of a container.

Edge labels at L2:

- Protocol: `HTTP`, `gRPC`, `JDBC`, `SNS`, `SQS`, `EventBridge`, `Kinesis`, etc.
- Direction matters: `A → B` means A initiates the connection (or sends the message).

What does NOT belong in L2:

- Components inside any container. That is L3's job.
- Code-level entities (classes, functions).

## L3 — components within a container

Required:

- One `c4-l3-<container>` layer per container in L2.
- Inside each layer, the components of that container: handler, domain module, repository, adapter, mapper, etc.

Edge labels at L3:

- Direct call: function/method dispatch.
- Async event: emitted to an internal queue, channel, or in-process bus.

What does NOT belong in L3:

- Other containers. L3 zooms into one container; siblings are not redrawn.
- The container itself as a node. The layer _is_ the container.

A container's L3 layer can legitimately have a single placeholder node early in design ("Handler — TBD components"). The lint allows this at `draft` status; by `accepted`, the layer must be filled in.

## Sequence layers

Sequence diagrams answer "what happens, in what order, between which participants" — the dynamic behaviour that the static C4 layers cannot show.

### `seq-system` — happy path

Participants:

- External actor(s) from L1.
- The system as a single participant.

Story:

- One representative successful request, beginning at the actor and ending at the actor receiving the response (or the system completing the work and persisting the outcome, for fire-and-forget cases).

Length:

- Long enough to make the request/response/event flow legible. Not so long that error handling, retries, and edge cases creep in — those belong in `seq-error`.

### `seq-component` — inside one container

Participants:

- The components of one container (the same ones drawn in `c4-l3-<container>`).
- Optionally, one external dependency (e.g., a database or downstream service).

Story:

- One representative request handled by this container, internal to its components.

Choosing which container's `seq-component` to draw:

- Pick the container that carries the most non-trivial business logic — usually the API or workflow handler.
- A feature with multiple complex containers may warrant additional sequence layers; the lint requires only `seq-component` (singular). Additional sequences are encouraged but live as `seq-component-<container>` extensions and are not lint-required at v0.1.0.

### `seq-error` — dominant failure path

Participants:

- The same set as `seq-system` or `seq-component`, depending on where the dominant failure surfaces.

Story:

- The most common failure mode the design must handle: timeout, downstream 5xx, quota exceeded, auth failure, idempotency-key collision, etc.
- Includes the recovery path: retry, dead-letter, fallback response, alarm raised.

Why required, not optional:

- A design that omits its failure-mode story is a design that has not yet thought about reliability. The lint forces the conversation to surface; "we'll handle errors later" is precisely the design defect that bites at deployment.

## Notation conventions

- Default `d2` syntax. No theme directives, no custom shape libraries.
- Node identifiers are stable across layers when they refer to the same logical entity (e.g., `payments-api` is the same identifier in `c4-l2` and as the layer suffix `c4-l3-payments-api`).
- Node labels (the displayed text) may be more verbose than the identifier; identifiers stay machine-friendly.
- Edge labels carry the protocol or message type; absent labels are a lint warning at `c4-l2` (where protocol matters) and acceptable at L3 (where calls are usually unlabeled function dispatch).
