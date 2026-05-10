# How to test the plugin

This guide explains what the plugin's tests actually exercise, what they
do **not** catch, and how to extend coverage when changing skills, agents,
commands, hooks, or prompts.

The plugin has no application runtime — it ships markdown + JSON + bash.
Testing is therefore split into three layers:

1. **Deterministic gates** — file-shape, schema, and install-safety checks.
2. **Transcript replay** — model-free routing assertions against frozen
   fixtures.
3. **CI workflows** — orchestrate (1) and (2) across bash 3.2 / 5+ and
   `ubuntu-latest` / `macos-latest`.

A separate, **not-yet-implemented** layer — live-model evals — is the only
thing that can detect behavioural drift in skill / agent / command
prompts. See [What the tests do _not_ catch](#what-the-tests-do-not-catch)
below.

---

## 1. Deterministic gates — `tests/gates/`

Numbered bash scripts under [`tests/gates/`](../tests/gates/), invoked by
[`tests/gates/run-all.sh`](../tests/gates/run-all.sh). Each gate asserts
one structural property and exits non-zero on violation.

| Gate group               | IDs            | What it asserts                                                                                  |
| ------------------------ | -------------- | ------------------------------------------------------------------------------------------------ |
| Doctor + plugin metadata | 01–02          | `scripts/doctor.sh` loads; `.claude-plugin/plugin.json` schema + version.                        |
| Path / shell hygiene     | 03–04          | No absolute paths committed; `shellcheck -x` clean.                                              |
| YAML / file shape        | 05, 09, 10     | Frontmatter parses; agents and skills have required keys + naming-policy prefixes.               |
| Recipes / hooks / MCP    | 06, 07, 11, 12 | `*.recipe.json`, `hooks/hooks.json`, hook scripts, `.mcp.json` validity + matching script names. |
| Init idempotency         | 13             | `init.sh` produces the same on-disk state on repeat runs.                                        |
| Markdown lint            | 14             | `prettier --check` + `markdownlint-cli2` over every `.md`.                                       |
| Trademark / wording      | 15             | No banned phrasing (e.g. unauthorized AWS endorsement).                                          |
| Skill budgets            | 16, 17, 18     | Skill description shape; skill line count; tool-name length budget.                              |
| Install safety           | 30–33          | Clean roundtrip, dirty roundtrip, install idempotency, `--dry-run` byte-equal to real install.   |

`tests/gates/lib/common.sh` holds shared helpers; `tests/gates/cache/`
holds frozen MCP tool inventories so gates do not need network. The
harness is portable across **bash 3.2 (macOS system) and bash 5+** — no
associative arrays, no `mapfile`.

### Run locally

```bash
bash tests/gates/run-all.sh                 # stop at first failure
bash tests/gates/run-all.sh --keep-going    # run all, fail at end
```

---

## 2. Transcript replay — `tests/transcripts/`

Hand-authored fixture directories under
[`tests/transcripts/`](../tests/transcripts/). Each fixture pins:

- `prompt.txt` — the frozen user prompt to `/aws`.
- `expected-tools.jsonl` — the tool-call trace the orchestrator must produce.
- `expected-artefacts.txt` — the spec files that must exist after the run.
- `expected-merge.json` — fan-out merge contract (fan-out fixtures only).

Five fixtures ship at v0.1.0:

| Fixture           | Asserts                                                            |
| ----------------- | ------------------------------------------------------------------ |
| `vibe-shallow`    | Shallow depth classification → direct answer, no fan-out.          |
| `sdlc-full-depth` | Full §5.6 depth, parallel L3 fan-out, contract one-to-one mapping. |
| `merge-conflict`  | Merge contract handles overlapping component edits.                |
| `degraded-mcp`    | Graceful fallback when an MCP server is unreachable.               |
| `iteration-cap`   | `max-iterations: 3` is enforced and surfaces a clear stop reason.  |

The runner [`tests/run-transcripts.sh`](../tests/run-transcripts.sh) has
three modes:

- `--validate-only` (default) — schema-validates every fixture against
  [`tests/transcripts/README.md`](../tests/transcripts/README.md).
  **No orchestrator execution.**
- `--execute` — deterministic, **model-free** executor. Replays the
  router's depth-classification + routing logic against `prompt.txt`,
  asserts the predicted trace matches `expected-tools.jsonl`, then
  enforces fixture-specific runtime contracts (gates 20–27).
- `--update-snapshots` — **not implemented at v0.1.0**. Expected files are
  hand-authored on purpose.

### Run locally

```bash
bash tests/run-transcripts.sh                     # validate every fixture
bash tests/run-transcripts.sh --fixture vibe-shallow
bash tests/run-transcripts.sh --execute           # routing + runtime gates
bash tests/run-transcripts.sh --execute --keep-going
```

---

## 3. CI workflows — `.github/workflows/`

| Workflow               | Trigger                                  | What it asserts                                                                                                                               |
| ---------------------- | ---------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `gates.yml`            | every push / PR                          | `run-all.sh --keep-going` on Ubuntu bash 5, macOS bash 3.2, macOS brew bash 5+. Plus `transcript-validate` job (currently `--validate-only`). |
| `install-matrix.yml`   | PRs touching `scripts/**` or gates 30–33 | Real `install.sh` / `doctor.sh --help` / `uninstall.sh` on `{ubuntu-bash5, macos-bash3, macos-bash5}`.                                        |
| `mcp-version-skew.yml` | nightly `17 4 * * *` UTC                 | jq scan of every pinned `awslabs.*` MCP server in `.mcp.json` against PyPI; idempotent issue lifecycle.                                       |

`actions/checkout` is SHA-pinned. The only side effect across all three
workflows is GitHub-issue lifecycle in `mcp-version-skew.yml`.

---

## What the tests _do not_ catch

The gates above are **structural, not semantic**. Editing a skill, agent,
command, or hook prompt will pass CI as long as the file stays
well-formed, under the budget caps, lint-clean, and free of banned
phrases. **The wording, instructions, tool selection logic, and
reasoning quality inside a prompt are never exercised.**

Concretely:

| Change you make to a prompt                                             |                                     Will CI fail today?                                      | Why                                                                       |
| ----------------------------------------------------------------------- | :------------------------------------------------------------------------------------------: | ------------------------------------------------------------------------- |
| Reword a skill instruction; keep tools / structure the same             |                                              No                                              | Gates 14, 16, 17 only check format and budgets.                           |
| Change an agent's persona or tone                                       |                                              No                                              | gate-09 only checks frontmatter + filename prefix.                        |
| Tighten or loosen a command's reasoning steps                           |                                              No                                              | Markdown body is not parsed for behaviour.                                |
| Add or remove a `SPEC-v4 §X` citation in a skill                        |                                             Yes                                              | Memory rule + gate-15 forbid SPEC citations outside `docs/` and `tests/`. |
| Exceed skill line / description / tool-name budgets                     |                                             Yes                                              | Gates 16, 17, 18.                                                         |
| Break frontmatter or markdown formatting                                |                                             Yes                                              | Gates 05, 14.                                                             |
| Change `commands/aws.md` so depth classification routes differently     | Yes — **only if** transcript executor runs (`--execute`) **and** a fixture covers that path. | `transcript-validate` currently runs in `--validate-only` mode in CI.     |
| Live-model regression (worse plan, hallucinated tool, weaker reasoning) |                                              No                                              | There is no live-model eval harness in this repo.                         |

### Implications

1. **Routing drift** — changing how the orchestrator classifies depth or
   chooses MCP servers — _can_ be caught by transcript replay, but only
   when the executor is run. CI runs `--validate-only` today, so routing
   drift slips through unless reviewers run `--execute` locally.
2. **Skill / agent / command prompt drift** — rewording instructions,
   changing reasoning steps, swapping tool guidance — is **not caught at
   all**. Two prompts that produce dramatically different model
   behaviour will look identical to CI.
3. **Model-version drift** — upgrading the underlying model, or a
   provider-side regression, has no signal in this repo.

These are gaps to plan around, not silent assumptions.

---

## How to extend coverage

If you change a skill / agent / command / hook, do at least one of:

### Routing or tool-selection changes

1. Add or update a fixture under `tests/transcripts/` that exercises the
   new path. The fixture must include `prompt.txt`,
   `expected-tools.jsonl`, and `expected-artefacts.txt`. See
   [`tests/transcripts/README.md`](../tests/transcripts/README.md) for the
   schema.
2. Run `bash tests/run-transcripts.sh --execute --fixture <name>` locally
   until it passes.
3. Open the PR with a note that the executor was run; reviewers should
   confirm.

### Prompt body changes (skill / agent / command)

There is no automatic gate today. Until a live-model eval harness lands,
the convention is:

1. **Document the intent** of the change in the PR description — what
   behaviour you expect to change, and what to verify by hand.
2. **Run the affected command end-to-end** in a real session against a
   small AWS account or mocked MCP setup. Capture before/after output.
3. **Update or add a transcript fixture** if the change affects routing
   or tool selection — see above.
4. **Bump the skill description** if behaviour materially changes, so
   the orchestrator's match logic re-evaluates which skill to load.

### Hook changes

Hook script changes go through gates 04 (`shellcheck`), 11
(frontmatter and filename match), and 30–33 (install/uninstall
roundtrip). For
behavioural assertions on a hook (e.g. "this hook blocks writes
containing AWS keys"), add a fixture under `tests/transcripts/` whose
`expected-tools.jsonl` shows the blocked write, plus a unit test under
`tests/gates/` that runs the script in isolation against a synthetic
input.

---

## Roadmap — closing the drift gap

The four work items below are the durable answer to skill / agent /
command drift. Order is from cheapest to most invasive.

1. **Flip CI to `--execute` mode.** Edit `.github/workflows/gates.yml` so
   the `transcript-validate` job runs `bash tests/run-transcripts.sh
--execute --keep-going`. The harness already supports this; only the
   workflow flag is missing. This makes routing drift a CI-blocking
   regression.
2. **Expand transcript fixtures.** Each new skill / agent / command
   ships with at least one fixture. Target ≥1 fixture per skill and ≥2
   per command; ensure every WAF pillar skill has a fixture asserting
   its expected MCP servers are called.
3. **Live-model eval harness** _(new)_. Record a small golden set of
   `(prompt → expected-trace, expected-artefact-shape, rubric-score)`
   tuples. Run them on a schedule (nightly or on `release`) against the
   live orchestrator. Score with the `gan-evaluator` agent or a
   dedicated Claude API job. Out of scope for v0.1.0; track under a
   separate `feat(eval)` PR.
4. **Prompt-content snapshot gate** _(new)_. Add a gate that hashes the
   body of each `skills/**/SKILL.md`, `agents/*.md`, and `commands/*.md`
   and compares against a checked-in `tests/snapshots/prompt-hashes.json`.
   Mismatch → fail with a message asking the PR author to update both
   the snapshot **and** the corresponding fixture. This forces drift to
   be acknowledged in review, not slipped in silently.

Until items 3 and 4 land, treat skill / agent / command edits the same
way you would treat a database migration: explicit pre-merge testing,
explicit reviewer sign-off, no automatic safety net.

---

## Quick reference

```bash
# Everything that runs in CI today
bash tests/gates/run-all.sh --keep-going
bash tests/run-transcripts.sh --keep-going          # validate-only

# What CI does not run yet, but you should run locally
bash tests/run-transcripts.sh --execute --keep-going

# Single-fixture iteration
bash tests/run-transcripts.sh --fixture sdlc-full-depth --execute
```

Related docs:

- [`docs/validation-gates-guide.md`](./validation-gates-guide.md) — gate
  author / maintainer reference (how to add, modify, retire gates; the
  §11 numbering policy; helper-function catalogue). Read **that** doc
  when you need to add or change a gate; read **this** doc when you
  need to run tests or reason about coverage.
- [`docs/install.md`](./install.md) — install paths and contracts.
- [`docs/scripts.md`](./scripts.md) — lifecycle script reference.
- [`tests/transcripts/README.md`](../tests/transcripts/README.md) —
  fixture schema reference.
- [`docs/plan/SPEC-v4.md`](./plan/SPEC-v4.md) §11 — the canonical gate
  catalogue (deterministic / runtime / cross-platform / install-safety /
  release).
