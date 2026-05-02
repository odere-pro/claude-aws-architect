# `claude-aws-architect-kb` — playbook

Read-only knowledge surface. Bundles the `kb` MCP server, the `aws-kb-navigator` skill, the routing / grounding / cache skills, the two default PreToolUse hooks, and `/aws-kb`. Stateless per turn; never writes spec artefacts.

> See [`docs/aws-kb-guide.md`](../aws-kb-guide.md) for the full surface reference.

---

## AWS-200 — onboard a developer to a service in under a minute

**Persona:** A backend developer joining a team that uses AWS Step Functions for the first time.

**Trigger:** "I just got assigned a workflow ticket and I have no idea what Express vs Standard means."

**Invocation:**

```text
/aws-kb --onboard Step Functions
```

**What happens:**

- The kb-navigator agent classifies the intent as `onboard`.
- It runs the tool sequence `kb:search_documentation` → `kb:read_documentation` → `kb:recommend` (3 calls of the 6-call budget).
- The five-section response template returns: a one-paragraph **Answer**, 3–7 bullets covering core primitives (state machines, tasks, catch/retry, integration patterns), `Citations`, a `Related` list (Express vs Standard, error handling, integration patterns, IAM for SFN, observability), and a `Next` list (e.g. "read the SOP for invoking Lambda from a state machine").

**Why this is production-ready:**

- Word ceiling 250 (or 600 with `--deep`) means the developer is not buried in marketing copy.
- Every claim is grounded with `kb:<short-key>` citations they can paste into a PR description.
- No artefacts are written — the developer's repo stays clean.
- Reusable: a follow-up `/aws-kb --next` returns recommendations seeded from the prior turn's grounding ledger.

---

## AWS-300 — pick the right CLI flag set for an operational job

**Persona:** A platform engineer writing a runbook for a cross-account S3 sync.

**Trigger:** "I need `aws s3 sync` to mirror deletions, exclude a folder, and run from a non-default profile."

**Invocation:**

```text
/aws-kb --cli s3 sync
```

then

```text
/aws-kb --compare s3 sync vs s3 cp --recursive
```

**What happens:**

- First turn: intent `cli`. Tool sequence `kb:search_documentation (filter: aws s3 sync)` → `kb:read_documentation` → optional `kb:retrieve_agent_sop` for a recipe-style example. Response includes a syntax-tagged code block (replacing the bullets — never both).
- Second turn: intent `compare`. Two parallel `kb:search_documentation` calls + two `kb:read_documentation` calls (4 calls total).
- The runbook author copies the **Answer**, the code block, and the **Citations** line directly into the runbook. The `Related` list points to S3 lifecycle rules and S3 Transfer Acceleration; `Next` suggests reading the cross-account SOP.

**Why this is production-ready:**

- The `aws-kb-response` rule enforces "code block OR bullets, never both," so the runbook gets a clean, copy-pasteable command shape.
- The `aws-grounding-cache` skill TTL-classifies CLI reference results as `immutable`, so a second engineer running the same query reuses the cache and burns no extra MCP calls.
- The `aws-secret-scanner` hook is loaded by the Power, so any accidental paste of `aws_access_key_id=...` while iterating is blocked at PreToolUse.

---

## AWS-500 — drive a multi-region availability decision under regulatory constraint

**Persona:** A staff architect designing a data-residency-constrained service that must run in `eu-central-2` (Zurich) and serve a fall-back region.

**Trigger:** "Marketing wants Bedrock features X and Y in Zurich. Compliance forbids EU data leaving the region. Which Bedrock models and which managed runtimes are actually GA in `eu-central-2` today, and what falls back to `eu-west-1` cleanly if not?"

**Invocation:**

```text
/aws-kb --deep is Amazon Bedrock available in eu-central-2 and which models are GA there
```

then

```text
/aws-kb --compare bedrock model availability eu-central-2 vs eu-west-1
```

then

```text
/aws-kb --next
```

**What happens:**

- Turn 1: intent `region-q`. `kb:list_regions` and `kb:get_regional_availability` (2 calls). The cache ledger writes under the `region` TTL class — short-lived for region availability, exactly because regulatory answers cannot be served stale.
- Turn 2: intent `compare`. Two-subject parallel search + read (4 calls). The response surfaces capability gaps with citations; the `aws-spec-grounding` skill asserts every fact has a `<server>:<short-key>` citation, every gap is named.
- Turn 3: intent `next`. `kb:recommend` against the most recent ledger entry returns related topics (e.g., Bedrock guardrails, cross-region inference, AWS PrivateLink for Bedrock).
- If a `kb` call times out, the response surfaces a `grounding-deferred` marker rather than fabricating an answer — exactly the contract a regulated decision needs.

**Why this is production-ready:**

- **Region-TTL discipline.** The `aws-grounding-cache` skill refuses to serve a stale region-availability answer past the `region` TTL window, which is the only sane behaviour when GA status is the question.
- **Degraded-mode honesty.** A failed retrieval becomes an explicit `grounding-deferred` marker. The decision-maker sees the gap; the system does not paper over it.
- **No silent fan-out.** The kb-navigator agent never invokes design or implementation specialists. The architect drives the next step (e.g., open a `/aws --deep design ...` turn) with a clean, cited region picture in hand.
- **Multi-turn recommendation.** `--next` gives the architect the related-topic graph the kb ledger already knows about, instead of asking them to invent the search themselves.
