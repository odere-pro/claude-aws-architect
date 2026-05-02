---
description: Component-contract frontmatter, sections, observability triple, integration links
applyTo:
  - "**/.claude/specs/**/contracts/*.md"
inclusion: conditional
---

- Frontmatter declares exactly the six required keys: `component`, `kind`, `version`, `status`, `talks-to`, `grounded-by`. Unknown keys, missing keys, or `null` values fail the lint.
- `kind` is one of the closed vocabulary (`lambda`, `ecs-service`, `dynamodb-table`, etc.); inventing values is forbidden — components outside the vocabulary live as informal notes in `design.md`.
- Body has the seven canonical sections in exact order: Purpose, Interface, Sequence, Component view (C4 L3), Acceptance criteria, Observability, Integration points. Missing, reordered, renamed, or extra top-level sections fail the lint.
- Observability section has all three subsections (Metric, Log, Trace), each with a real signal name, source, and sampling/threshold; `TODO`, `TBD`, and unfilled `<angle-bracket>` placeholders fail the lint.
- Every slug in `talks-to` resolves to an existing sibling contract under the same feature; dangling references fail the lint. The Integration points section narrates the protocol per slug.
- `grounded-by` array has at least one valid `<server>:<short-key>` citation. Apply `aws-component-contract` and `aws-spec-grounding`.
