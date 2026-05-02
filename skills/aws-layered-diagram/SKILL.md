---
name: aws-layered-diagram
description: |
  **WORKFLOW SKILL** — Author and lint the per-feature `diagrams.d2`
  file. Enforce required layer tags (C4 L1, L2, L3-per-container,
  plus seq-system, seq-component, seq-error sequence layers); flag
  orphan nodes, untagged top-level shapes, and missing layers.
version: 0.1.0
---

## When to Use

Apply this skill any time an agent writes, edits, or reviews the per-feature `diagrams.d2` file. The solution-architect agent emits this file at design time alongside `design.md` and the per-component contracts. Reviewers lint it before the design transitions from `draft` to `accepted`.

Trigger conditions:

- The agent is creating a new `diagrams.d2` at the feature root.
- The agent is adding a new container to the design and needs to add a matching `c4-l3-<container>` layer.
- The agent is editing an existing diagram and needs to confirm no top-level node is untagged.
- The agent is checking that every component named in `design.md` appears in the `c4-l2` layer.
- The agent is performing a pre-acceptance review and needs to lint the diagram against all six required tags.

## Procedure

1. **Place the file at the canonical path.** `.claude/specs/<feature>/diagrams.d2`. One file per feature; multiple components share the same file via layer tags. If creating, use `assets/diagrams.d2.tmpl` as the starting structure.
2. **Declare every required layer.** The file must contain six layer tags: `c4-l1`, `c4-l2`, one `c4-l3-<container>` per L2 container, `seq-system`, `seq-component`, `seq-error`. Missing any of the six is a lint failure. Detail in `references/layer-taxonomy.md`.
3. **Tag every top-level node.** No node at the file's top level may be untagged. Each node belongs to at least one layer; the lint enumerates top-level shapes and asserts every one carries a layer tag. Untagged top-level nodes are a lint failure.
4. **Resolve C4 levels consistently.** L1 = system context (one box for the system, surrounding actors and external systems). L2 = containers (the major runtime/process boundaries inside the system). L3 = components within a single container (one diagram per L2 container). Detail in `references/c4-and-sequence.md`.
5. **Fill the three sequence layers.** `seq-system` shows the canonical happy-path interaction across the L1 boundary; `seq-component` shows a representative request handled inside a single L2 container; `seq-error` shows the dominant failure mode and the recovery path.
6. **Detect orphans.** A node with no edges in or out, in any layer, is an orphan and is a lint failure. There are no exceptions: the central system node at `c4-l1` must connect to its actors, every external actor must connect to the system, every container at `c4-l2` must connect to at least one peer, every component at L3 must connect to at least one sibling. Detail in `references/layer-taxonomy.md`.

## Gotchas

- **Do not collapse C4 levels.** L1, L2, and L3 are different views, not nested groups. Showing components inside a container at L2 defeats the purpose of having a separate L3 layer; the L2 view should stop at the container boundary.
- **Do not use `c4-l3` (no suffix).** L3 layers are per-container: `c4-l3-payments-api`, `c4-l3-fulfilment-worker`, etc. A bare `c4-l3` tag is ambiguous and the lint rejects it.
- **Do not omit a `c4-l3-<container>` for a container that has no components yet.** If the container is named at L2, it needs an L3 layer — even if that layer contains a single placeholder node. Empty containers in the design are a discovery signal worth surfacing, not hiding.
- **Do not embed sequence diagrams in the C4 layers.** Sequences live in `seq-system`, `seq-component`, `seq-error`. Putting a sequence inside a `c4-l2` layer collapses two distinct views and breaks the lint's per-tag enumeration.
- **Do not duplicate node identifiers across layers.** Each layer is a self-contained view; cross-layer references happen via the same logical name in different tags, but the same node identifier appearing twice at the same layer is a lint failure.
- **Do not write d2 syntax that requires a non-default theme to render.** The `d2` CLI in CI runs with default settings; theme-dependent visual conventions silently degrade. Use the default node and edge styles unless a styling decision is documented.

## Boundaries

- This skill MUST NOT generate the rendered diagram (PNG, SVG). Rendering is the consumer's responsibility; this skill works on the `.d2` source file.
- This skill MUST NOT execute the `d2` CLI to validate syntax. Syntax validation is the consumer's CI step using `d2 validate`. This skill validates layer-tag presence and structural rules at the source-text level.
- This skill MUST NOT apply to `*.d2` files outside `.claude/specs/<feature>/diagrams.d2`. Other `.d2` files (e.g., docs/, README diagrams) are not in scope.
- This skill MUST NOT auto-create missing layers. A missing layer is a real signal that the design has not yet covered that view; the lint surfaces the gap rather than papering over it.
- This skill MUST NOT enforce a specific node-naming convention beyond the lint rules in `references/layer-taxonomy.md`. Node names should match the corresponding component slug in `contracts/`, but enforcement of cross-file consistency is a separate downstream check.
- This skill MUST NOT enforce L3 component completeness against `contracts/`. Cross-file consistency between the L3 layers and the contract slugs is a separate lint that the orchestrator runs at acceptance time.

## Quality Checks

Before returning a diagram decision, confirm:

- The file is at `.claude/specs/<feature>/diagrams.d2`. One file per feature.
- The file contains layer tags `c4-l1`, `c4-l2`, `seq-system`, `seq-component`, `seq-error`. No missing.
- For every container named at `c4-l2`, there is exactly one corresponding `c4-l3-<container>` layer.
- No node at the file's top level is untagged.
- No two nodes at the same layer share an identifier.
- The three sequence layers are non-empty: each contains at least one actor and one message.
- At `accepted` status: no edge label or node label in any sequence layer contains `TODO`, `TBD`, or an unfilled `<angle-bracket>` placeholder. Sequence layers shipped from the template carry `TODO:` markers that must be replaced before acceptance.
- No orphan nodes anywhere — every node in every layer has at least one incoming or outgoing edge. No exceptions for the system node at L1, external actors at L1, containers at L2, or components at L3.
- The d2 source uses default styles; no theme-specific or visualisation-only directives.
