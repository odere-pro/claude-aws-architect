# ADR-0004: Merge contract — conflict-resolution priority order and surfacing format

- **Status:** Accepted
- **Date:** 2026-05-02
- **Tier:** v0.1.0
- **SPEC anchor:** §5.5

## Context

The orchestrator (§5.2 #0) fans out L3 specialists in parallel (per §F2 and §1.6). Specialists frequently disagree:

- Solution-architect proposes Aurora; implementation specialist proposes DynamoDB on cost grounds.
- Discovery cites a docs claim from yesterday; implementation re-fetched the same surface today and got a different answer.
- One specialist's design assumes a public S3 bucket; another (security-pillar-aware) flags it as a violation.

In a sequential single-agent pipeline, the latest agent's view wins by default. Parallel fan-out breaks that resolution: the orchestrator receives N partial answers and must produce one. Three failure modes appear if the merge is unprincipled:

1. **Silent loss.** The orchestrator picks one specialist's view and drops the others' conflicts without trace, hiding security-blocking findings.
2. **Wishful synthesis.** The orchestrator pretends specialists agreed when they didn't, producing a smoothed-over response that no specialist actually endorses.
3. **Forced user arbitration.** The orchestrator dumps every disagreement on the user, regardless of whether a deterministic rule could have resolved it. The user becomes a tiebreaker for trivia.

The merge contract has to prevent all three: deterministic where possible, transparently human-arbitrated where not, fully logged either way.

## Decision

The orchestrator merges parallel L3 specialist outputs per a **fixed conflict-resolution priority order** (high → low):

1. **Security correctness.** Any specialist's security-blocking finding (IAM violation, exposed secret, public-access default, missing encryption) wins regardless of other specialists' designs.
2. **Factual correctness.** A specialist's grounded-by citation (per §F4) wins over an un-grounded claim from another specialist.
3. **Cost ceiling.** If the user named a budget in the prompt, the cost-engineer's output (v0.2) constrains downstream choices.
4. **Convergence on architecture.** When specialists agree on a service or pattern, that's locked; further proposals are flagged.
5. **Recency.** When two specialists fetch the same fact at different times, the most recent grounded-by citation wins.

**Non-trivial design disagreements** (data store, async vs sync, region strategy) are **not** silently picked. The merged response includes a `## Open Questions` section listing each disagreement: which specialists, the competing options, the priority-rule outcome (or "raised to user" if no rule applies), and the citations or rationales on each side.

**Every conflict** resolved by the priority rules is logged in the grounding ledger as a `conflict-resolution` entry with: timestamp, specialists involved, options considered, rule applied, chosen option. Conflicts raised to the user are logged as `unresolved`.

The orchestrator's Quality Checks (§5.1 H2.9) include the post-condition: _every specialist disagreement appears either in `## Open Questions` or in the conflict-resolution log; none are silently dropped._

## Alternatives considered

- **Last-writer-wins.** Rejected: discards security findings raised by an early-returning specialist if a later specialist's response overlaps. Reproduces the silent-loss failure mode.
- **Majority vote.** Rejected: with a parallel cap of 3 (N13), majority is meaningless when only two specialists weigh in on a given question. Also dilutes security findings (single dissenting voice may hold the only correct answer).
- **Always raise to user.** Rejected: the §5.6 verb-of-inquiry case (shallow answers) would flood the user with arbitration prompts on every minor disagreement, defeating the vibe-first promise.
- **LLM-judged merge.** Rejected for v0.1.0: introduces an additional opaque arbitration step whose failure modes are harder to test than a rule table. Could be considered as a tiebreaker layer at v0.2+ if the priority order leaves consistent gaps.
- **Severity-graded merge** (CRITICAL/HIGH/etc. levels per finding). Rejected as orthogonal to priority rules. The security-finding rule already encodes the only severity the merge contract needs at v0.1.0; specialists may still emit severity inside their own outputs.
- **Merge by phase** (resolve all security first, then all factual, then all design). Considered and partially adopted: the priority order is _evaluated_ in that sequence per disagreement, but the merged output is composed once at the end rather than emitted in waves.

## Consequences

**Positive.**

- Security findings are **structurally privileged**. A specialist that flags a public S3 default cannot be silently overruled by a specialist that didn't notice.
- Factual claims with citations beat opinions without them. The grounding-by surface (§F4) gains operational teeth — un-grounded claims lose conflicts even when they sound confident.
- The user sees disagreements only when no rule resolves them. Vibe prompts stay vibe-shaped; SDLC prompts get full transparency.
- The conflict log is auditable. Reviewers can answer "why did this design land here?" by reading the ledger, not by replaying the model.

**Negative.**

- **The cost-ceiling rule is dormant at v0.1.0** because the cost-engineer specialist is deferred to v0.2 (§5.2). The rule is recorded now to avoid renumbering the priority list when it activates; this is documented in §5.2 itself.
- **Recency is the weakest signal** and can be wrong (a specialist may have hit a stale cache). Mitigated by §N15's TTL policy and the grounding cache's `retrieved-date` field — recency only fires when both fetches are within their TTL window.
- **`## Open Questions` may grow long** on very contested designs. Acceptable: it's better than silent picks, and it's the user's authoritative arbitration surface.
- **Specialist authors must declare findings clearly enough for rule 1 to fire.** "Public bucket" must be declared as a security-blocking finding, not buried in narrative. Enforced by the security-pillar skill (§4.2 #8).

## Revisit when

- The cost-engineer specialist (v0.2) ships. Outcome: confirm rule 3 fires correctly under the new specialist set; update the gate-3 fixture.
- A new specialist class arrives that the priority list doesn't address (e.g. a reliability-engineer with availability-blocking findings analogous to security). Outcome: a new ADR superseding this one, extending the priority list rather than reordering it.
- Real-user data shows `## Open Questions` regularly contains items the priority rules _should_ have resolved. Outcome: tighten the rule definitions (e.g. clarify what counts as a "grounded-by citation" beating an un-grounded claim).
- Transcript-replay regressions (§10) show silent drops slipping past the quality check. Outcome: add a deterministic gate beyond the Quality Checks self-assertion.
