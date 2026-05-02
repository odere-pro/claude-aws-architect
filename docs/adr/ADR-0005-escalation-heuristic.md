# ADR-0005: Escalation heuristic — content-classified depth selection

- **Status:** Accepted
- **Date:** 2026-05-02
- **Tier:** v0.1.0
- **SPEC anchor:** §5.6

## Context

The plugin's architecture (ADR-0001) is vibe-first: a single `/aws` entry point accepts any prompt and decides whether to answer shallowly or fan out to L3 specialists. That decision is the **depth-escalation heuristic**.

The naive options all fail in characteristic ways:

- **Always shallow.** Plugin can't honour its SDLC artefact promise (§F5, §F6). Defeats the reason it exists.
- **Always full depth.** Trivial questions ("what region is us-east-1?") trigger parallel fan-out, burn iteration budget (O4), and produce contracts and diagrams the user didn't ask for. High latency, high cost, low signal.
- **Token-length classifier.** Long prompts are not necessarily SDLC prompts; short prompts can be deeply technical. Length is uncorrelated with depth.
- **LLM-judged depth.** A separate model call to classify intent burns cost on every prompt and adds an opaque failure mode that can't be tested deterministically.
- **User-facing mode toggle.** Re-introduces the configuration surface ADR-0001 explicitly rejected.

What's needed is a heuristic that:

- Classifies intent from prompt **content**, not length or model judgement.
- Is deterministic enough to test with §10 fixtures.
- Honours an explicit user override when the user knows what they want (`--deep`, `--quick`).
- Fails toward "answer the question" rather than "force escalation".

## Decision

The orchestrator selects depth using a **content-classified**, ordered rule list:

1. **Explicit override.** Prompt contains `--deep` or `--quick` → use that depth, skip remaining rules.
2. **SDLC-artefact intent.** Prompt names any of `design`, `architecture`, `IaC`, `CDK`, `threat model`, `cost estimate`, `security review`, `runbook`, `spec`, `requirements`, `contract`, `RFC`, `ADR` → full depth (parallel fan-out, all eligible specialists).
3. **Verb-of-creation.** Prompt opens with `build`, `design`, `architect`, `propose`, `draft`, `spec`, `plan` and names an AWS service or noun → full depth.
4. **Verb-of-inquiry.** Prompt opens with `what`, `how`, `which`, `is`, `does` → shallow depth (orchestrator answers from grounded knowledge; no fan-out unless follow-up matches rule 2 or 3).
5. **Default.** Shallow.

**Mid-turn upgrade is allowed.** Shallow → full escalation can happen mid-turn if the orchestrator detects an SDLC-artefact intent in the user's clarification. Full → shallow downgrade does **not** happen automatically — once specialists have been fanned out, their output is merged.

The heuristic is intentionally **content-classified, not token-length-classified**. It is implemented in the `aws-sdlc-workflow` skill and exercised by §10's `vibe-shallow` and `sdlc-full-depth` transcript fixtures.

## Alternatives considered

- **LLM intent classifier.** Rejected: cost per prompt + non-determinism + harder to test. The keyword-based classifier produces equivalent quality at zero extra model cost on the cases the fixtures exercise.
- **Token-length threshold (e.g. ≥30 tokens → full depth).** Rejected: empirically uncorrelated with intent. Several short SDLC prompts and several long inquiry prompts are documented in the fixtures.
- **Verbosity dial set in `claude-aws-architect.local.md`.** Considered and rejected for v0.1.0: re-introduces user configuration. Could be added as an opt-in advanced setting at v0.2+ if real users ask for it.
- **Always full depth, with shallow as `--quick` opt-in.** Rejected: most user prompts are vibe-shaped; defaulting to full depth burns budget on the common case.
- **Two-pass classifier** (cheap heuristic first, escalate to LLM judgement on tie). Considered: a v0.2+ refinement if the keyword list shows persistent edge cases, but premature for v0.1.0.
- **Always escalate on second-turn follow-up.** Rejected: too eager. Users frequently ask multiple shallow questions before deciding to commission a design.

## Consequences

**Positive.**

- Depth selection is deterministic and unit-testable. Fixtures pin the classification result for canonical prompts.
- The user has an explicit override (`--deep`, `--quick`) without a persistent mode toggle.
- Mid-turn upgrade preserves the "vibe first, deepen on signal" UX; users can land informally and the plugin notices when the conversation turns into design work.
- Verb-of-inquiry → shallow keeps the latency and cost of trivial questions low, which is essential for adoption — users who pay full-fanout cost on "what is us-east-1" abandon.

**Negative.**

- **Keyword list rot.** New AWS terms or new SDLC verbs may slip past the rules. Mitigated by §10 fixtures and by the explicit override (`--deep`) — when the heuristic misclassifies, the user can correct it immediately.
- **English-centric.** The keyword list assumes English prompts. Non-English prompts default to shallow unless they contain an English keyword. Acceptable for v0.1.0; revisit when localisation becomes a real-user demand.
- **No automatic full → shallow downgrade.** Once fan-out has happened, its output is merged. Users who change their mind mid-turn must start a new conversation to roll back to shallow. Documented in §5.6 and called out in the orchestrator agent's Boundaries.
- **Some prompts legitimately ambiguous.** "tell me about Aurora" matches no rule strongly; it lands shallow by default. The verb-of-inquiry branch covers this and lets users escalate with `--deep` if they wanted a full design.

## Revisit when

- §10 transcript fixtures show ≥10% misclassification across one release cycle. Outcome: extend the keyword list or add a tie-breaker rule.
- Real-user data shows users routinely typing `--deep` on the same prompt shapes. Outcome: promote those shapes into rule 2.
- Localisation is added as a goal. Outcome: a per-locale keyword list, structured so rules 2–4 generalise without changing the rule order.
- An LLM-judged classifier becomes cheap enough that two-pass classification (rule list first, LLM tiebreaker) becomes economical. Outcome: a v0.2+ revision adding the second pass without removing the rule list.
