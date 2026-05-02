# ADR-0001: AWS plugin architecture — 4 layers, vibe-first, AWS-knowledge-grounded

- **Status:** Accepted
- **Date:** 2026-05-02
- **Tier:** v0.1.0
- **SPEC anchor:** §1 (requirements), §2 (folder layout), §5 (agents)

## Context

`claude-aws-architect` is a greenfield Claude Code plugin that exists to drive an end-to-end AWS Well-Architected SDLC workflow from a single user prompt. Two tensions shaped the architecture:

1. **Vibe-first vs SDLC rigour.** Users land on the plugin from informal prompts ("how should I host this?"). They should not have to declare upfront whether they want a five-minute answer or a full design package. But the plugin's value proposition is the rigorous artefact set (requirements, design, contracts, diagrams, IaC, costs) — so the path from vibe → artefacts must be cheap and obvious, not a separate mode the user has to opt into.
2. **AWS knowledge currency.** AWS service shapes, quotas, pricing, and best practice change continuously. Hard-coding facts into agent prompts or skill bodies is the dominant failure mode of similar plugins: instructions silently rot, then mislead. Authoritative knowledge has to be **fetched at the time of the answer**, not baked in.

Past attempts to address either tension separately produced one of two failure shapes:

- **Mode-toggle plugins** (vibe vs deep) overflow with configuration and confuse users who don't know which mode to pick.
- **Knowledge-baked plugins** answer fast but drift; their authority erodes within a release cycle.

The plugin needed an architecture that resolves both at once.

## Decision

Adopt a **four-layer architecture** with strict layer responsibilities and a single entry point.

| Layer | Role                                                                                                                                       | Currency                     |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------- |
| L1    | **MCP servers** — authoritative AWS facts (docs, IaC validation, pricing, security, IAM, CW)                                               | Always-fresh; fetched at use |
| L2    | **Skills** — procedural know-how the orchestrator and L3 agents share (workflow, grounding, contracts, diagrams, MCP routing, WAF pillars) | Versioned with plugin        |
| L3    | **Specialist agents** — discovery, solution-architect, implementation; each owns a slice of SDLC artefacts                                 | Versioned with plugin        |
| L4    | **Orchestrator agent** — single entry point (`/aws`); fans L3 specialists out in parallel and merges results                               | Versioned with plugin        |

The orchestrator is **vibe-first**: it accepts any prompt, classifies depth via the §5.6 escalation heuristic, and either answers shallowly or fans out to L3 specialists. Depth selection happens behind the scenes; the user never has to choose a mode.

Every factual AWS claim that appears in a generated artefact carries a grounded-by citation pointing at L1 (per §F4). Design opinions carry a rationale paragraph pointing at a WAF pillar or named principle, not a citation. This split is enforced by the `aws-spec-grounding` skill (§4.2).

## Alternatives considered

- **Three-layer (no L4 orchestrator).** Each L3 specialist would be user-invocable directly. Rejected: the plugin's user-facing promise is "one prompt, full SDLC". Forcing the user to pick a specialist exports the routing problem to them and fragments the artefact set across uncoordinated agent runs.
- **Single agent with embedded knowledge.** Rejected: the AWS-knowledge-currency problem dominates. Even with monthly releases, embedded knowledge drifts faster than the release cadence. The MCP layer is non-negotiable.
- **Mode-toggle plugin (vibe / deep / SDLC modes).** Rejected: empirically high abandonment when users land in the wrong mode. The §5.6 escalation heuristic produces the same depth without the cognitive tax.
- **L4 + L3 with no L2 skills.** Rejected: each L3 agent would re-implement merge rules, citation policy, and contract authoring. Skills (§4.2) exist precisely to share procedural know-how across agents without copy-paste drift.
- **Marketplace listing of multiple smaller plugins** (one per pillar). Rejected: install-time UX of six related plugins is worse than one plugin shipping six pillar skills under a shared orchestrator. Deferred indefinitely; revisited only if pillar-specific deployment becomes a real need.

## Consequences

**Positive.**

- A single `/aws` entry point is easy to teach, easy to demo, easy to dogfood (§13.G).
- Knowledge currency is a property of L1 — fixing a stale answer means upgrading an MCP server pin (§16.2), not rewriting agent prompts.
- Layer separation creates clean test surfaces: §10 transcript fixtures exercise L4+L3 routing without depending on real MCP responses; §3.5 degraded-mode fixtures exercise L1 failure modes without exercising L4 routing.
- The escalation heuristic (§5.6) is the only depth control the user sees. Mode toggles are explicitly out of scope.

**Negative.**

- **Latency**: shallow answers pay the cost of L4 → L3 routing even when L4 could answer alone. Mitigated by §5.6 rule 4 (verb-of-inquiry → shallow without fan-out) and N13's parallel cap of 3.
- **Iteration cap pressure**: L4 → L3 → potential re-call sequences must respect O4 (default 3 iterations) to bound cost. Documented as an explicit budget in §1.6 and surfaced in `## Open Questions` if exhausted.
- **Substrate-iceberg risk**: it is tempting to add L2 skills indefinitely. §13's authoring backlog and §S2's promotion gates exist to constrain this.

## Revisit when

- Real-user data shows depth misclassification rate >5% across one release cycle. Outcome: tune §5.6 rules or add `--deep` / `--quick` flag UX prominence.
- A second L4 surface emerges (e.g. a cost-only or IAM-only entry point) — at which point the layering generalises to "1 or more L4s, each fronting a specialist set" rather than "single L4".
- The Powers mechanism (§9.1) reaches v0.2 maturity and a new pillar arrives that's better authored as an external Power than as an in-tree skill. Revisits the boundary between L2 (skills) and Powers.
