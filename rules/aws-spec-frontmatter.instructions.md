---
description: Spec-doc frontmatter, grounded-by minimums, status-transition discipline
applyTo:
  - "**/.claude/specs/**/requirements.md"
  - "**/.claude/specs/**/design.md"
  - "**/.claude/specs/**/tasks.md"
inclusion: conditional
---

- Frontmatter declares the required keys: `feature` (slug, lowercase-kebab-case), `created` (ISO-8601 date), `updated` (ISO-8601 date), `status` (one of `draft`, `review`, `accepted`, `implemented`), `grounded-by` (array). Missing or null values fail the lint.
- `requirements.md` carries at least one `grounded-by: <server>:<short-key>` entry; `design.md` carries at least one; `tasks.md` may have zero. Each entry matches the citation regex.
- `status` transitions follow `draft → review → accepted → implemented`. Backward transitions (e.g., `accepted → draft`) require a one-line rationale appended to the body and an updated `updated` date.
- `feature` matches the parent directory slug exactly; mismatches break the cross-feature grounding ledger and fail the lint.
- The three sibling files share the same `feature` slug and the same `created` date; `updated` may differ per file. Inconsistent values across siblings fail the cross-doc consistency check.
- Apply `aws-spec-grounding` for citation/rationale rules and `aws-grounding-cache` for the per-feature ledger schema.
