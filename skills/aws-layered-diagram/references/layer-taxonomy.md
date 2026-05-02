# Layer taxonomy

Loaded on demand by the `aws-layered-diagram` skill. Defines the set of required layer tags in `diagrams.d2`, what each layer represents, and the lint rules that apply to each.

## Required tags

A conformant `diagrams.d2` declares all of the following as `layer:` entries at the top level:

| Tag                 | Cardinality                  | Represents                                                           |
| ------------------- | ---------------------------- | -------------------------------------------------------------------- |
| `c4-l1`             | exactly one                  | C4 system context: the system as a single box, with external actors. |
| `c4-l2`             | exactly one                  | C4 containers: the major runtime/process boundaries inside.          |
| `c4-l3-<container>` | one per container in `c4-l2` | C4 components inside a single container.                             |
| `seq-system`        | exactly one                  | Happy-path sequence across the system boundary.                      |
| `seq-component`     | exactly one                  | Representative sequence inside a single container.                   |
| `seq-error`         | exactly one                  | Dominant failure mode and recovery sequence.                         |

A diagram missing any of these tags fails the lint.

## Tag-name rules

- `c4-l1`, `c4-l2`, `seq-system`, `seq-component`, `seq-error` are fixed strings; no variation.
- `c4-l3-<container>` substitutes the container's slug (lowercase-kebab-case, matching the container's identifier in the `c4-l2` layer). Examples: `c4-l3-payments-api`, `c4-l3-fulfilment-worker`, `c4-l3-event-bus`.
- A bare `c4-l3` (no suffix) is a lint failure.
- A `c4-l3-<container>` tag whose `<container>` does not match a container declared in `c4-l2` is an orphan layer and is flagged as a lint error.

## Per-layer content rules

### `c4-l1` (system context)

- Exactly one node represents the system itself.
- All other nodes are external actors (human users, external systems, AWS managed services that sit outside this system's boundary).
- Each external actor must have at least one edge to or from the system node. Floating actors are a lint warning; if intentional (e.g., a future actor not yet wired), document with a comment.

### `c4-l2` (containers)

- Each top-level node is a container: an independently runnable/deployable unit (an ECS service, a Lambda function, a DynamoDB table, an SQS queue, etc.).
- Containers are connected by edges labelled with the protocol or event type (HTTP, SNS, SQS, EventBridge).
- A container in `c4-l2` _requires_ a matching `c4-l3-<container>` layer. The lint enumerates `c4-l2` containers and asserts each has its L3 sibling.

### `c4-l3-<container>` (components)

- One layer per container in `c4-l2`.
- Each top-level node is a component within that container: a handler, a domain module, a repository, an adapter.
- The container itself is _not_ a node in this layer (it is the layer); only its internal components.
- An empty `c4-l3-<container>` layer is allowed at `draft` status but fails the lint at `accepted` — by acceptance time, every container's internals must be designed.

### `seq-system` (happy-path system sequence)

- Actors and the system are swimlanes.
- The diagram covers the canonical happy path: a representative request from an external actor, through the system, to a successful response.
- At least one actor and at least one message; an empty `seq-system` is a lint failure.

### `seq-component` (component-level sequence)

- A representative request inside a single container.
- The container's components are swimlanes.
- The same constraint: at least one actor (or external entry point) and at least one message.

### `seq-error` (failure-mode sequence)

- The dominant failure mode for the system. Examples: downstream timeout with retry-and-DLQ; auth failure with redirect; quota exceeded with backoff.
- Includes the recovery path or the dead-letter terminal state.
- At least one actor and at least one message.

### Placeholder discipline for sequence layers

The starter template under `assets/diagrams.d2.tmpl` populates the three sequence layers with `TODO:`-prefixed labels so the file ships in a structurally conformant state. At `accepted` status, no edge label or node label in any sequence layer may contain `TODO`, `TBD`, or an unfilled `<angle-bracket>` token. The lint matches all three patterns equally and fails any sequence layer that still carries them at acceptance time.

## Top-level node rule

Every node at the file's top level (outside any layer) must carry an explicit layer tag, or it must be inside a layer block. Files with floating top-level nodes fail the lint. Reasoning: a node with no layer is effectively un-classified design intent; it leaks into rendered diagrams as a stray box and confuses readers.

## Orphan-node rule

A node with zero incoming and zero outgoing edges, in any layer, is an orphan. **Orphans are a lint failure with no exceptions**:

- The central system node in `c4-l1` is required to connect to at least one external actor (otherwise the system has no documented entry point).
- External actors at `c4-l1` are required to connect to the system (otherwise the actor is noise or the diagram is incomplete).
- Containers at `c4-l2` are required to connect to at least one peer (otherwise the container is unreachable from the rest of the system).
- Components in `c4-l3-<container>` are required to connect to at least one sibling (a single-component container is acceptable as a placeholder, but only as a single node — once a second component appears, edges between them become mandatory).
- Every actor and message in `seq-system`, `seq-component`, `seq-error` is by construction connected — sequence diagrams without messages are a separate lint failure (empty sequence layer).

If a node legitimately has no relationships in this view (e.g., a future-state actor not yet wired), it does not belong in the diagram yet. Add it when it becomes connected.

## Cross-layer consistency (out of scope here)

Cross-file consistency — `c4-l3-<container>` component slugs matching the slugs in `contracts/<slug>.md` — is checked by a separate orchestrator-level lint at acceptance time. This skill validates the diagram in isolation; cross-file checks are layered on top.
