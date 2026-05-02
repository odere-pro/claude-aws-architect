---
name: aws-spec-grounding
description: |
  **WORKFLOW SKILL** — Enforce grounding discipline on AWS specs. Every
  factual claim (quota, API shape, pricing, region availability, ARN format)
  needs ≥1 grounded-by citation; every design opinion needs a rationale.
  Flag un-grounded claims and opinion-without-rationale.
version: 0.1.0
---

## When to Use

Apply this skill any time an agent writes, edits, or reviews an AWS spec artefact: `requirements.md`, `design.md`, `tasks.md`, component contracts, or ADRs. The orchestrator and discovery agent invoke it at draft time; reviewers invoke it before accepting. Do not apply this skill to non-AWS prose or to internal scratch notes that never reach a spec file.

Trigger conditions:

- The agent is about to assert a factual AWS detail (quota, API shape, pricing, region availability, service-to-service compatibility, ARN format).
- The agent is about to recommend a design (data store, async vs sync, region strategy, identity boundary, instance class).
- The agent is reviewing a draft spec and needs to find un-grounded claims.
- The agent is asked to explain why a recommendation was made and the spec's rationale section is empty.

## Procedure

1. **Classify the claim.** For each sentence the agent is about to write, decide: is it a _factual claim_ about AWS or a _design opinion_ about how to use AWS? Consult `references/opinion-vs-fact.md` for the boundary cases.
2. **For factual claims.** Attach at least one `grounded-by: <server>:<short-key>` citation. The citation must reference a ledger entry produced by a prior MCP call. Format rules in `references/cite-format.md`.
3. **For design opinions.** Attach a one-paragraph rationale that names a Well-Architected pillar, a documented principle, or a stated trade-off. A bare "this is best practice" is not a rationale. Rules in `references/grounded-by-rules.md`.
4. **Detect missing grounding.** A claim with no citation and no rationale is a violation. Emit it as a `grounding-deferred` marker so the orchestrator surfaces the gap; do not silently let it pass.
5. **Detect mismatched grounding.** A factual claim with only a rationale (no citation) is also a violation — facts need sources, not philosophy. A design opinion with only a citation (no rationale) is a violation — opinions need reasoning, not just a doc link.
6. **Record the audit.** Each violation is logged so reviewers can see which claims were flagged and which were resolved before the spec was accepted.

## Gotchas

- **Do not treat the AWS docs URL as a rationale.** A link to a documentation page is a citation (factual evidence). It does not justify a design choice; it only confirms a fact. The pattern "We chose Aurora because [docs link]" is wrong — the rationale must say _why_ Aurora, citing the WAF pillar or principle.
- **Do not let the model's pretrained knowledge stand in for grounding.** If a fact cannot be cited from a current MCP call (or a fresh ledger entry within TTL), it is un-grounded. Pretrained AWS facts are stale; the deferred marker is the truthful signal.
- **Do not over-cite.** A single grounded-by citation is sufficient when the cited source covers the claim. Stacking three citations on one fact is noise; reviewers stop reading.
- **Do not under-rationalise.** A rationale that says "best practice" or "industry standard" is not a rationale. Name the pillar, name the principle, name the trade-off; otherwise it is opinion-without-reasoning.
- **Do not move violations into footnotes.** A flagged claim must remain in the body of the spec with its marker visible. Hiding it in a footnote defeats reviewer attention.

## Boundaries

- This skill MUST NOT fetch from MCP servers itself. Grounding requires a citation that _already exists_ in the ledger; the citation comes from `aws-mcp-routing` and the cache from `aws-grounding-cache`.
- This skill MUST NOT auto-generate rationales. A missing rationale is a missing rationale; the agent or human must supply it.
- This skill MUST NOT downgrade a missing citation to a soft warning. Un-grounded factual claims are violations and surface as deferred markers.
- This skill MUST NOT validate the truth of a citation. The citation is a pointer to a ledger entry; whether the underlying fact is correct is the responsibility of the upstream MCP server and the ledger TTL policy.
- This skill MUST NOT apply to prose outside spec artefacts (e.g., commit messages, PR descriptions, casual chat). Spec discipline is for the spec.

## Quality Checks

Before returning a grounding decision, confirm:

- Every factual claim in the agent's draft has at least one `grounded-by: <server>:<short-key>` citation pointing to a ledger entry.
- Every design opinion has a rationale paragraph that names a pillar, principle, or trade-off — not "best practice".
- Citations follow the `<server>:<short-key>` format defined in `references/cite-format.md`.
- Servers referenced in citations are one of `kb`, `iac`, `cost`, `sec`, `iam`, `cw`.
- Each unresolved violation has a `grounding-deferred` marker visible in the spec body.
- The fact-vs-opinion classification has been applied per `references/opinion-vs-fact.md` and edge cases were resolved, not skipped.
