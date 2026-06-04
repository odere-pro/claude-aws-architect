# AWS knowledge-base navigator — user guide

A read-only lookup surface for AWS docs, CLI reference, recipe-style SOPs, comparisons, onboarding pointers, and "what should I learn next" recommendations. Stateless per turn; never writes spec artefacts.

> **Audience:** plugin users running `/aws-kb` in any Claude Code session that has the `claude-aws-architect-kb` Recipe loaded (or any session that loads the plugin's full Recipe set).

---

## What it is

`/aws-kb` is a thin command that delegates to the `claude-aws-architect-kb-navigator-agent`. The agent classifies your query into one of six intents, routes the narrowest possible tool on the `kb` MCP server, and returns a compact citation-backed answer under a fixed five-section template:

1. **Answer** — one or two sentences.
2. **Bullets** (3–7) **or a syntax-tagged code/CLI block** — pick one, never both.
3. **Citations** — `<server>:<short-key>` references for every factual claim.
4. **Related** — up to 5 short topics drawn from `kb:recommend` or `kb:search_documentation` neighbours.
5. **Next** — up to 3 concrete actions or topics drawn from the same sources.

Default word ceiling: **250 words**. Pass `--deep` to lift to **600 words**.

---

## What it does NOT do

- Does not write spec artefacts (`requirements.md`, `design.md`, `tasks.md`, `contracts/*.md`, `diagrams.d2`).
- Does not call IaC, cost, security, IAM, or CloudWatch MCP servers — it is `kb`-only.
- Does not invoke other agents (no fan-out to discovery, solution-architect, or implementation specialists).
- Does not create a feature directory under `.claude/specs/`.
- Does not invent recommendations — `Related` and `Next` are sourced from KB results, not hand-rolled.

If your prompt names an SDLC artefact (`requirements`, `design`, `tasks`, `runbook`, `threat-model`, `ROM`) or a verb-of-creation (`design`, `architect`, `build`, `plan`), the agent will short-circuit and tell you to use `/aws` instead.

---

## Quick start

Three concrete invocations:

```text
/aws-kb what is AWS Step Functions Express vs Standard?
```

```text
/aws-kb --cli s3 sync
```

```text
/aws-kb --onboard EventBridge
```

Each returns the five-section response described above. The first picks the `lookup` intent. The second picks `cli` and surfaces both the CLI reference and an optional SOP recipe. The third picks `onboard` and returns a "what it is → primary primitives → first-task pointer" pass with at least one `kb:recommend` follow-up topic in `Next`.

---

## Intents and flags

| Intent     | Flag                   | When it fires                                                                                               | Tool sequence                                                                                                                  |
| ---------- | ---------------------- | ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `lookup`   | (none — default)       | Default for a verb-of-inquiry prompt with no flag (e.g., "what is Step Functions?").                        | `kb:search_documentation` → `kb:read_documentation` (top hit only)                                                             |
| `cli`      | `--cli <service>`      | CLI reference query, or the prompt opens with `aws <service>`.                                              | `kb:search_documentation` (filter on `aws <service>`) → `kb:read_documentation` → optional `kb:retrieve_agent_sop` for recipes |
| `compare`  | `--compare <a> vs <b>` | Two services or two configurations of the same service on a stated dimension.                               | `kb:search_documentation` × 2 → `kb:read_documentation` × 2                                                                    |
| `onboard`  | `--onboard <topic>`    | Onboarding pointer for a service or learning track around a topic.                                          | `kb:search_documentation` → `kb:read_documentation` → `kb:recommend`                                                           |
| `next`     | `--next`               | Recommendations tied to the most recent grounding-ledger entry.                                             | `kb:recommend` against the most recent ledger entry; no other call                                                             |
| `region-q` | (auto)                 | Region question ("is X available in eu-central-2?", "list regions for service Y", "regional availability"). | `kb:list_regions` and/or `kb:get_regional_availability`                                                                        |

Cross-cutting flag: `--deep` lifts the 250-word ceiling to 600 words for any intent.

---

## Response shape — annotated example

Input:

```text
/aws-kb --cli s3 sync
```

Expected output (illustrative — exact wording depends on the live KB response):

```text
**Answer**: `aws s3 sync` recursively copies new and updated files between an S3 bucket and a local directory or another bucket; it does not delete by default.

- Source and destination are positional; either can be `s3://...` or a local path.
- Default behaviour copies new and updated files only; pass `--delete` to mirror deletions.
- Use `--exclude` / `--include` patterns to filter; later patterns override earlier ones.
- Multipart upload happens automatically for files above the 8 MB threshold (configurable).
- The CLI uses the credentials and region from the active profile; pass `--profile` and `--region` to override.

**Citations**: kb:aws-cli-s3-sync, kb:aws-cli-s3-sync-options
**Related**: aws s3 cp, aws s3 mb, aws s3api put-object, S3 lifecycle rules, S3 Transfer Acceleration
**Next**: read the SOP for cross-account `s3 sync`; compare `s3 sync` vs `s3 cp --recursive`; review S3 Transfer Acceleration pricing
```

The `Citations` line is mandatory whenever any KB retrieval succeeded. If every retrieval failed, the response collapses to a single degraded-marker line — see [Troubleshooting](#troubleshooting).

---

## Loading the Recipe

The `claude-aws-architect-kb` Recipe bundles the `kb` MCP server, the `aws-kb-navigator` skill, the supporting `aws-mcp-routing` / `aws-spec-grounding` / `aws-grounding-cache` skills, the two default PreToolUse hooks (`aws-secret-scanner`, `aws-api-write-guard`), and the `/aws-kb` command into one opt-in unit.

On a host that uses per-Recipe loading, add `claude-aws-architect-kb` to the loaded Recipe list. The full inventory of Recipes shipped by this plugin lives in `docs/recipes-guide.md`. The Recipe deliberately does NOT include `/aws`, `/aws-spec`, `/aws-doctor`, or the IaC / cost / security / IAM / CloudWatch MCP servers — it is a focused lookup bundle, not a full SDLC bundle.

---

## Boundaries

- **Read-only.** No prose-artefact writes. Grounding-ledger append is the only durable side effect, and only when a feature directory already exists.
- **Stateless.** Each turn classifies its own intent. The agent never tracks "learner progress" or accumulates state across turns beyond the grounding ledger's TTL-bounded cache.
- **`kb`-only MCP.** Calling any other MCP server is a contract violation; the routing skill catches it.
- **6 KB calls per turn cap.** The seventh required call triggers `budget-exhausted` and returns the marker in place of the Answer.
- **Five-section template is non-negotiable.** Reordering, omitting, or merging sections trips the `aws-kb-response` rule.
- **No SDLC mode.** Prompts that name an SDLC artefact or verb-of-creation are short-circuited to `/aws`.

---

## Troubleshooting

| Symptom                                                         | Likely cause                                                                                      | Resolution                                                                                              |
| --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Response is a single `grounding-deferred` line.                 | `kb` MCP server timed out or returned 5xx for every retrieval this turn.                          | Re-run the query later; check `/aws-doctor` to confirm `.mcp.json` resolves.                            |
| Response is a single `budget-exhausted` line.                   | The chosen intent needed more than 6 `kb` calls (most often `compare` on three or more subjects). | Narrow the query: split the comparison, or ask one subject at a time.                                   |
| Response is a single `redaction-failed` line.                   | The grounding-cache redaction policy aborted a ledger insert.                                     | Re-run the query on a session where the ledger is writable; if it persists, file an issue in this repo. |
| Response is rerouted to `/aws`.                                 | The query named an SDLC artefact or a verb-of-creation.                                           | Use `/aws` for SDLC work; use `/aws-kb` only for read-only lookups.                                     |
| Wrong intent picked (e.g., got `lookup` when you wanted `cli`). | The default classifier did not detect the intent verb in the query.                               | Pass the explicit flag: `--cli`, `--compare`, `--onboard`, or `--next`.                                 |
| Word ceiling truncated useful detail.                           | 250-word default ceiling.                                                                         | Add `--deep` to lift to 600.                                                                            |

---

## See also

- [`docs/recipes-guide.md`](./recipes-guide.md) — Recipes inventory, schema, gate, and load mechanism.
- [`docs/mcp-servers-guide.md`](./mcp-servers-guide.md) — `kb` server reference and timeout policy.
- [`docs/validation-gates-guide.md`](./validation-gates-guide.md) — gates that validate the kb-navigator artefacts.
- [`SPEC.md`](../SPEC.md) and [`docs/plan/SPEC-v4.md`](./plan/SPEC-v4.md) — full plugin spec, including depth classification and merge contract for `/aws`.
