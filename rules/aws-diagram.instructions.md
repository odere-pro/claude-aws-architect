---
description: d2 diagram layer-tag, naming, and orphan discipline
applyTo:
  - "**/*.d2"
inclusion: conditional
---

- Every `diagrams.d2` declares all six required layer tags: `c4-l1`, `c4-l2`, one `c4-l3-<container>` per L2 container, `seq-system`, `seq-component`, `seq-error`. Missing any layer is a lint failure.
- Node identifiers are stable kebab-case slugs; the same logical component shares the same identifier across `c4-l2` and its `c4-l3-<container>` layer so cross-layer references resolve.
- Edge labels at `c4-l2` carry the protocol or message type (`HTTP`, `SQS`, `EventBridge`, `gRPC`); unlabelled L2 edges are a lint warning because protocol affects review surface.
- Sequence layers (`seq-system`, `seq-component`, `seq-error`) declare `shape: sequence_diagram` and contain at least one actor and one message; empty sequence layers are a lint failure.
- No node at the file's top level is untagged: every shape lives inside a layer block. Untagged top-level nodes leak into rendered output as stray boxes and confuse readers.
- No orphan nodes: every node in every layer has at least one incoming or outgoing edge. There are no exceptions, including the central system node at L1. Apply `aws-layered-diagram`.
