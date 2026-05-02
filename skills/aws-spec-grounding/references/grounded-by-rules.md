# grounded-by rules

Loaded on demand by the `aws-spec-grounding` skill. Defines the minimum-citation rules per artefact type and the rationale-paragraph requirements for design opinions.

## Per-artefact minimums

| Artefact                                  | Minimum citations | Rationale required for opinions | Notes                                                                                            |
| ----------------------------------------- | ----------------- | ------------------------------- | ------------------------------------------------------------------------------------------------ |
| `.claude/specs/<feature>/requirements.md` | ≥1                | Yes                             | Each acceptance criterion that asserts an AWS fact must cite ≥1 source.                          |
| `.claude/specs/<feature>/design.md`       | ≥1                | Yes                             | Architecture choices need rationale; quantitative claims (latency, cost ceiling) need citations. |
| `.claude/specs/<feature>/tasks.md`        | 0                 | No                              | Tasks are work items, not claims. Citations on tasks are allowed but not required.               |
| `.claude/specs/<feature>/contracts/*.md`  | ≥1                | Yes                             | Component contracts need at least one citation for the service quotas/limits they depend on.     |
| `docs/adr/ADR-NNNN-*.md`                  | 0                 | Yes (entire doc is rationale)   | An ADR is a rationale document; citations are useful but not required.                           |

## Rationale paragraph rules

A design opinion needs more than a citation. It needs a **rationale** — a one-paragraph justification linking the choice to a Well-Architected pillar, a documented principle, or an explicit trade-off the author accepted.

### What counts as a rationale

A valid rationale paragraph names at least one of:

- **A Well-Architected pillar**: Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimisation, Sustainability.
- **A named principle** from AWS or a recognised body: "least privilege", "defence in depth", "single source of truth", "fail-fast", "graceful degradation", "twelve-factor app", etc.
- **An explicit trade-off**: "we chose X over Y because we accepted higher cost in exchange for lower operational burden".
- **A constraint from the requirements**: "the requirements pin this to eu-west-1 due to data-residency, so we route via Aurora regional endpoints".

### What does NOT count as a rationale

- "Best practice" — too vague; which practice, named where?
- "Industry standard" — which standard, applied to which decision?
- "AWS recommends" — recommends in which doc, for which trade-off, against which alternative?
- A bare citation to a documentation page — that grounds a fact, it does not justify an opinion.
- "We're already using it elsewhere" — consistency is a real reason, but it must be stated as a trade-off (rolled-up operational simplicity vs. local fit), not asserted.

### Example

Wrong (citation only, no rationale):

```text
We will use Aurora Serverless v2 for the payments database (kb:aurora-serverless-v2).
```

Right (citation grounds the fact, rationale justifies the choice):

```text
We will use Aurora Serverless v2 for the payments database (kb:aurora-serverless-v2).
Rationale: Cost Optimisation pillar — payments traffic is bursty (10x diurnal swing per
the discovery report), and Serverless v2's per-second billing aligns capacity to demand
without manual scaling. We accept ~15% per-request cost premium versus a provisioned
cluster in exchange for eliminating capacity-planning toil. (Trade-off explicitly accepted.)
```

## Detection rules

When reviewing a draft:

1. **Walk every assertive sentence.** A sentence is assertive if it states a property of AWS or a property of the proposed system.
2. **Classify**: factual or opinion (use `references/opinion-vs-fact.md`).
3. **Check the artefact's frontmatter or inline citations**:
   - Factual + has citation → OK.
   - Factual + no citation → emit `grounding-deferred` marker; flag the sentence in the audit log.
   - Opinion + has rationale → OK.
   - Opinion + no rationale → emit `grounding-deferred` marker labelled "opinion-without-rationale"; flag the sentence in the audit log.
   - Opinion + only a citation, no rationale → still a violation; citations don't substitute.
4. **Check the document minimum**: if the artefact requires ≥1 citation in frontmatter and the array is empty or absent, the entire document fails the gate.

## Surfacing violations

Violations are not corrected silently. They appear in the spec body with the marker so the reviewer sees them, and they propagate into the orchestrator's merged output under `## Degraded signals` or `## Open Questions`. A spec with unresolved `grounding-deferred` markers cannot transition from `draft` to `accepted`.
