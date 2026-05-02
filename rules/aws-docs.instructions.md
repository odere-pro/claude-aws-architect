---
description: Plugin docs and consumer-spec prose discipline
applyTo:
  - "docs/**/*.md"
  - "**/.claude/specs/**/*.md"
  - "**/README.md"
  - "**/SPEC.md"
inclusion: conditional
---

- Headings are audience-first: the first sentence under each heading names who reads it (operator, architect, end-user) so readers self-route; abstract-then-detail prose without a named audience is forbidden.
- Every `design.md` references a `c4-l1`, `c4-l2`, and at least one `c4-l3-<container>` tag in `diagrams.d2`; missing references break the design-to-diagram cross-walk and are flagged at lint time.
- Every assertive AWS claim carries a `grounded-by: <server>:<short-key>` citation in the document frontmatter or inline; ungrounded factual claims are deferred markers, not soft warnings. Apply `aws-spec-grounding`.
- Cross-document links use repo-relative paths and the lint resolves every link; broken cross-links are a lint failure, not a documentation rough edge.
- Marketing language is forbidden: no "blazing fast", "world-class", "industry-leading", "seamless"; replace with measurable claims (latency budget, throughput floor) cited via the grounding ledger.
- Code blocks in docs are syntax-tagged with the language; bare triple-backtick fences fail the markdownlint MD040 check.
