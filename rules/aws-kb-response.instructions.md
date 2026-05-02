---
description: Response shape and word ceilings for the kb-navigator agent
applyTo:
  - "agents/claude-aws-architect-kb-navigator-agent.md"
  - "commands/aws-kb.md"
  - "skills/aws-kb-navigator/**/*.md"
inclusion: conditional
---

- Every kb-navigator answer follows the fixed five-section order: a one- or two-sentence **Answer**; exactly one of (3–7 bullets OR a syntax-tagged code/CLI block, never both); a **Citations** line of `<server>:<short-key>` references; a **Related** list of ≤5 topics; a **Next** list of ≤3 actions or topics. Reordering, omitting, or merging sections is forbidden.
- Word ceiling is 250 by default and 600 when `--deep` is passed; budgets count rendered body excluding the Citations, Related, and Next labels. On overrun, drop bullets first, never citations.
- Marketing language is forbidden ("blazing", "world-class", "industry-leading", "seamless"); replace with measured claims grounded by ledger citations per `aws-docs`. Hedging without a concrete follow-up clarifier is also forbidden.
- Every assertive AWS claim carries a `<server>:<short-key>` citation in **Citations**; if every KB retrieval failed, the response collapses to a single degraded-marker line (`grounding-deferred`, `budget-exhausted`, or `redaction-failed`) with no prose.
- **Related** and **Next** items come from `kb:recommend` results or `kb:search_documentation` neighbours; hand-rolled suggestions without a ledger entry are not permitted.
- Code or CLI blocks are syntax-tagged (`bash`, `json`, `yaml`, `text`) per markdownlint MD040; the block, when present, replaces the bullet list.
