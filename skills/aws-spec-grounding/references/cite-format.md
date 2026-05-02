# Citation format

Loaded on demand by the `aws-spec-grounding` skill. Defines the exact format of `grounded-by` citations and where they appear in spec artefacts.

## Citation token

A citation is a string of the form:

```text
<server>:<short-key>
```

Where:

- `<server>` is one of the six known short server keys: `kb`, `iac`, `cost`, `sec`, `iam`, `cw`.
- `<short-key>` is the canonicalised cache key produced by `aws-grounding-cache` for the underlying MCP call. Short keys are lowercase, hyphen-separated, and globally unique within the ledger.

Examples:

- `kb:lambda-concurrency-quota`
- `cost:s3-standard-eu-west-1`
- `iam:simulate-s3-getobject-readonly-role`
- `cw:billing-alarm-history-30d`

## Where citations appear

### YAML frontmatter (preferred for spec docs)

In `requirements.md`, `design.md`, `tasks.md`, and component contracts, citations live in a `grounded-by` array in the YAML frontmatter:

```yaml
---
feature: payments-eu-region
created: 2026-05-02
updated: 2026-05-02
status: draft
grounded-by:
  - kb:lambda-concurrency-quota
  - kb:s3-eu-west-1-availability
  - cost:rds-aurora-eu-west-1
---
```

This format is required on `requirements.md` (≥1 entry), `design.md` (≥1 entry), and every component contract (≥1 entry). The authoritative per-artefact minimums live in `grounded-by-rules.md`; this file describes the citation token and where it appears, not the count rules.

### Inline (for individual claims inside the body)

Inside the body of a spec, an individual factual claim may carry an inline citation in parentheses immediately after the claim:

```text
The default unreserved-concurrency limit is 1000 per region (kb:lambda-concurrency-quota).
```

The inline form is for when a single claim is more specific than the document-level array. Both forms can coexist; the document-level array is the source of truth for gate validation.

## Format rules

1. Lowercase only. `kb:Lambda-Concurrency` is invalid.
2. Single colon between server and short-key. No second colon, no slashes, no spaces.
3. Short-key segments separated by `-`, never `_` or `.`.
4. Short-key length 3–60 characters. Beyond 60 the cache layer applies collision-extension and the citation becomes harder to read.
5. No URL. The citation is a pointer to a ledger entry; the URL lives in the ledger record, not the citation.
6. No version suffix. Pricing changes are tracked via the ledger TTL, not via citation versioning.

## What a citation is NOT

- It is not a URL.
- It is not a docstring or summary of the cited content.
- It is not a free-text label ("see AWS docs"); a citation that does not match the `<server>:<short-key>` pattern is invalid and gates fail.
- It is not a substitute for a rationale on a design opinion. Citations ground facts; rationales justify opinions.

## Validation

The per-instructions-file rules (`aws-component-contract`, `aws-spec-frontmatter`) and the agents gate check the _form_ of the citation:

1. Every entry in the `grounded-by` array matches the `<server>:<short-key>` regex.
2. Every short-key resolves to an existing ledger entry. The ledger layer (`aws-grounding-cache`) owns TTL and freshness; this skill checks only that the pointer resolves, not that the underlying fact is still current.
3. The minimum count per artefact type is met (requirements: ≥1, design: ≥1, contract: ≥1; full table in `grounded-by-rules.md`).

A citation whose form is invalid, or whose short-key resolves to nothing, is treated as un-grounded; the orchestrator surfaces the affected claim under `## Open Questions` or `## Degraded signals` rather than silently dropping it. A citation that resolves but whose ledger entry is past TTL is the cache layer's problem, not this skill's — it surfaces as a separate `grounding-deferred` marker emitted by `aws-grounding-cache`.
