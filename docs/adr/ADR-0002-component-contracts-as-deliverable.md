# ADR-0002: Component contracts as a first-class deliverable

- **Status:** Accepted
- **Date:** 2026-05-02
- **Tier:** v0.1.0
- **SPEC anchor:** §1.1 F5, §4.2 (`aws-component-contract` skill), §5.2 (agent outputs)

## Context

LLM-generated AWS designs commonly land as a single `design.md` describing the system at a high level — a paragraph per component, a service list, perhaps a Mermaid diagram. Two failure shapes follow:

1. **Implementation drift.** The narrative `design.md` is too coarse to drive code or IaC. The implementation phase silently invents interfaces, IAM permissions, and event shapes that no other artefact references. By the time review catches the drift, the design and the code disagree.
2. **Review opacity.** A reviewer reading `design.md` cannot answer "what exactly does Component X expose to Component Y, with which IAM grants, against which observability triple?". The information is implied, not stated, so security and reliability review degenerates into a guessing exercise.

The plugin's promise is end-to-end SDLC rigour, not narrative design. The deliverable shape has to make implementation drift and review opacity structurally impossible.

## Decision

Every generated component ships with a **component contract** at `.claude/specs/<feature>/contracts/<slug>.md`. Each contract declares, in a fixed section order:

1. **Frontmatter** — component name, owning specialist, related component slugs.
2. **Interface** — inbound calls, outbound calls, sync vs async, payload shape (declared, not exemplified).
3. **Sequence** — a sequence-diagram fragment scoped to this component (a slice of `diagrams.d2`).
4. **C4 L3 fragment** — internal structure of the component, deployable units, their boundaries.
5. **Acceptance criteria** — testable post-conditions the implementation must satisfy.
6. **Observability triple** — metric, log, trace shape declared per component (not after the fact).
7. **Integration links** — which other contracts this component reads from or writes to.

The `aws-component-contract` skill (§4.2 #4) is the authoring and lint surface; both the solution-architect and implementation agents (§5.2) consume and emit contracts. The implementation agent additionally fills in IaC, cost ROM, IAM, acceptance, and observability sections of each contract per its dependency contract (§5.4).

Every component named in `design.md` must have a contract file; gate 8 in §11.A enforces the cross-reference.

## Alternatives considered

- **Narrative `design.md` only.** Rejected — produces the implementation-drift and review-opacity failure shapes the plugin exists to prevent.
- **OpenAPI / JSON Schema-only contracts.** Rejected for v0.1.0: AWS components include async event flows, IAM policies, and observability surfaces that don't fit cleanly into OpenAPI. A markdown contract with declared sections covers the full surface; OpenAPI schemas can be embedded as references inside the contract when an HTTP API is part of the component.
- **One large contract per feature (single file).** Rejected: contracts must be navigable by component slug for cross-linking and per-component review. A 12-component feature in a single file becomes unscannable.
- **Optional contracts (only for "important" components).** Rejected: importance is decided after the fact. Mandating contracts for every component is the only rule that survives contact with real designs. The cost is bounded by the standard section template — adding a component is cheap when the template is fixed.
- **Contracts as JSON with a generated Markdown view.** Rejected for v0.1.0 (per N2: markdown + JSON + bash, no TS build). Could be revisited at v0.2+ if validation tooling demands it.

## Consequences

**Positive.**

- Implementation phase has a per-component target. The implementation agent (§5.2) writes IaC and tasks against named contracts; drift becomes a structural impossibility rather than a vigilance task.
- Review surface is per-component and uniform. Security review reads each contract's IAM section; reliability review reads each contract's acceptance + observability triple. No cross-document hunting.
- Diagrams gain a natural decomposition target — the contract's sequence fragment is one source for the layered `diagrams.d2` (§9.6).
- Contracts compose: integration links between contracts make the dependency graph explicit, which in turn powers gate 8 (cross-reference check) and the merge contract (§5.5).

**Negative.**

- **Authoring overhead.** A 10-component feature produces 10 contract files. Mitigated by `aws-component-contract`'s template (§4.2 #4) and by the fact that contracts replace narrative prose in `design.md`, not add to it.
- **Skill surface to maintain.** The lint logic in `aws-component-contract` is non-trivial. Mitigated by §4.3's strict body section budget and §11.A's gate 17 (SKILL.md line cap) — contract-authoring rules cannot silently inflate.
- **Slug stability.** Component slugs in the URL of a contract file are load-bearing for cross-references. Renames are breaking changes; documented in the skill's Gotchas.

## Revisit when

- Three or more real-user features hit ≥30 components and contract authoring becomes the latency bottleneck. Outcome: consider per-component templates or partial contract generation.
- OpenAPI / AsyncAPI tooling matures enough to drive contract sections from machine-readable schemas. Outcome: add an optional generated contract path while keeping the markdown contract as the canonical artefact.
- The Powers mechanism (§9.1) introduces a different deliverable shape that competes with contracts. Outcome: explicitly choose one or document the boundary.
