# Merge rules

Loaded on demand by the `aws-sdlc-workflow` skill. Defines the conflict-resolution priority order, the conflict-surfacing format, and the logging discipline for the orchestrator's merge contract.

## Conflict-resolution priority order

When two or more specialists return outputs that disagree on the same point, apply these rules in order. The first matching rule resolves the conflict; later rules do not run.

| Priority | Rule                     | What it means                                                                                                                                                                         |
| -------- | ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1        | Security correctness     | Any specialist's security-blocking finding wins regardless of other specialists' designs. Examples: IAM violation, exposed secret, public-access default, missing encryption at rest. |
| 2        | Factual correctness      | A specialist's `grounded-by` citation (per the grounding rules) wins over an un-grounded claim from another specialist.                                                               |
| 3        | Cost ceiling             | If the user named a budget in the prompt, the cost-engineer's output (v0.2) constrains downstream choices.                                                                            |
| 4        | Architecture convergence | When specialists agree on a service or pattern, that choice is locked; further proposals against it are flagged as regressions.                                                       |
| 5        | Recency                  | When two specialists fetch the same fact at different times, the most recent `grounded-by` citation wins.                                                                             |

If no rule resolves the conflict, surface it under `## Open Questions` (see below). The orchestrator does **not** invent a sixth rule, does **not** vote, does **not** average, does **not** silently pick. The user resolves.

## What counts as a "conflict"

A conflict is a non-trivial disagreement on a load-bearing claim. Examples:

- One specialist names DynamoDB; another names Aurora Serverless v2.
- One specialist requires synchronous request/response; another proposes async event-driven.
- One specialist proposes eu-west-1; another proposes us-east-1.
- One specialist declares a quota of 1000; another declares 5000.

What is _not_ a conflict:

- Trivial wording differences (one specialist calls a queue "queue", another calls it "buffer"). The merge picks the more specific name; no log entry needed.
- One specialist returning more detail than another on the same topic. Detail is additive; no rule needed.
- A specialist returning a degraded marker. That is a degraded signal, not a conflict; it surfaces under `## Degraded signals`, not `## Open Questions`.

## Conflict-surfacing format

When the priority rules cannot resolve a conflict, the merged response includes:

```markdown
## Open Questions

### <one-line description of the disagreement>

- **Specialists involved**: <agent names>
- **Options**:
  - Option A: <description> — proposed by <specialist>; <citation or rationale>
  - Option B: <description> — proposed by <specialist>; <citation or rationale>
- **Priority rule outcome**: <which rule fired, or "no rule applied — raised to user">
- **What the user should decide**: <one-line guidance on what choosing each option implies>
```

Each unresolved conflict is its own subsection. Reviewers see the full disagreement and can resolve it by editing the spec or by re-prompting with the chosen option.

## Logging

Every conflict — resolved by a priority rule or raised to the user — produces a `conflict_resolution` entry in the per-feature grounding ledger. The schema (owned by `aws-grounding-cache`) requires:

| Key           | Type     | Required | Description                                                             |
| ------------- | -------- | -------- | ----------------------------------------------------------------------- |
| `timestamp`   | string   | yes      | ISO-8601 UTC.                                                           |
| `specialists` | string[] | yes      | Names of the specialists involved.                                      |
| `options`     | string[] | yes      | The competing options.                                                  |
| `rule`        | string   | no       | Priority-rule name that resolved the conflict, omitted if `unresolved`. |
| `chosen`      | string   | no       | Selected option, omitted if `unresolved`.                               |
| `status`      | string   | yes      | `resolved` or `unresolved`.                                             |

The orchestrator queues the entry; the cache layer writes it to the ledger. Logs are append-only.

## Why the priority rules are in this order

1. **Security first** — security findings cannot be overridden by faster, cheaper, or more elegant alternatives. A design with an IAM violation is not a viable design, regardless of other merits.
2. **Facts beat opinions** — a grounded citation outranks an opinion. This prevents one specialist's pretrained-knowledge guess from contaminating the merge.
3. **Budget is a stated constraint** — if the user told us a budget, that is a constraint we accepted, not a soft suggestion. Cost-engineer's veto is structural.
4. **Convergence over re-litigation** — if specialists agree, that agreement is signal. Re-opening it for a single dissenter wastes the user's attention.
5. **Recency** — when nothing else applies, the more recent fact wins. A 90-day-old quota differs from a 1-day-old quota; trust the newer one.

## What the merge contract DOES NOT do

- It does not auto-correct a specialist's output. The orchestrator surfaces conflicts; specialists do their own internal corrections.
- It does not weight specialists. Each specialist's claims are evaluated equally; the priority rules differentiate by _type_ of claim, not by _who said it_.
- It does not retry. A timed-out or budget-exhausted specialist returns a marker; no in-turn re-invocation.
- It does not gate the response on conflict resolution. The merged response ships with the unresolved conflict surfaced; the user is the resolver.

## Quality check the orchestrator must run

Before returning the merged response:

> Every specialist disagreement appears either in `## Open Questions` or in the conflict-resolution log; none are silently dropped.

The check is a structural property of the merge: count specialist outputs, count conflicts, count log entries + Open Questions entries; the latter must equal the former.
