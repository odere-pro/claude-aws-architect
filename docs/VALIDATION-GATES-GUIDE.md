# Validation gates — author & maintenance guide

This guide documents how the `claude-aws-architect` validation gates
work, how to run them locally, how to add a new gate, and how to
update or retire an existing one.

> Authoritative gate roster: [SPEC-v4 §11](./plan/SPEC-v4.md#11).
> Gate scripts: [`tests/gates/`](../tests/gates/). Shared helpers:
> [`tests/gates/lib/common.sh`](../tests/gates/lib/common.sh). Runner:
> [`tests/gates/run-all.sh`](../tests/gates/run-all.sh).

---

## 1. What a validation gate is

A **gate** is a single deterministic shell script that asserts one
spec rule and exits non-zero when the rule fails. Gates are the
machine-readable enforcement layer for SPEC-v4 — every numbered
gate in §11 maps to one script under `tests/gates/`.

Design contract:

- One file per gate: `tests/gates/gate-NN-<slug>.sh`.
- One assertion per gate. If a gate fails, the failure points at
  exactly one rule.
- Pure bash, no live network, no live AWS calls (those belong to
  §11.B runtime gates and `scripts/doctor.sh`).
- Cross-platform: macOS bash 3.2 + Ubuntu bash 5+. No GNU-isms
  without feature detection.
- Idempotent and side-effect-free on the working tree (gates that
  exercise install/uninstall do their work in tempdirs).

---

## 2. Gate categories (SPEC-v4 §11)

| Category                  | Range  | What they assert                                                                |
| ------------------------- | ------ | ------------------------------------------------------------------------------- |
| §11.A Deterministic       | 1–18   | Schema, layout, contract conformance — runnable offline.                        |
| §11.B Runtime (replay)    | 19–27  | Transcript-replay assertions about orchestrator behaviour. Live model required. |
| §11.C Cross-platform      | 28–29  | §11.A passes on `ubuntu-latest` and `macos-latest`.                             |
| §11.D Install-safety      | 30–33  | install/uninstall/dry-run roundtrips on clean and dirty trees.                  |
| §11.E Release             | 34     | Dogfood meta-spec passes every §11.A and §11.B gate before tagging v0.1.0.      |

The scripts under `tests/gates/` cover §11.A and §11.D today.
§11.B lives under `tests/run-transcripts.sh` and §11.E is asserted
by the release runbook.

---

## 3. Current gate inventory

### 3.1 §11.A — Deterministic

| #  | File                                                                                        | Asserts                                                                                                          |
| -- | ------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| 1  | [`gate-01-doctor.sh`](../tests/gates/gate-01-doctor.sh)                                     | `scripts/doctor.sh` exits 0.                                                                                     |
| 2  | [`gate-02-plugin-json.sh`](../tests/gates/gate-02-plugin-json.sh)                           | `.claude-plugin/plugin.json` parses; `name` + `engines.claude-code` present.                                     |
| 3  | [`gate-03-no-absolute-paths.sh`](../tests/gates/gate-03-no-absolute-paths.sh)               | No absolute paths anywhere in the plugin tree.                                                                   |
| 4  | [`gate-04-shellcheck.sh`](../tests/gates/gate-04-shellcheck.sh)                             | `shellcheck` clean across every bash script.                                                                     |
| 5  | [`gate-05-yaml-frontmatter.sh`](../tests/gates/gate-05-yaml-frontmatter.sh)                 | Every Markdown with `---` frontmatter parses as YAML.                                                            |
| 6  | [`gate-06-powers.sh`](../tests/gates/gate-06-powers.sh)                                     | Every `powers/*.power.json` matches §9.1 schema.                                                                 |
| 7  | [`gate-07-hooks-json.sh`](../tests/gates/gate-07-hooks-json.sh)                             | Every `hooks/hooks.json` entry matches §9.2 schema.                                                              |
| 8  | [`gate-08-rules.sh`](../tests/gates/gate-08-rules.sh)                                       | Every rule file matches §6.1 (frontmatter + 2–6 bullets, ≤200 words, no example code).                           |
| 9  | [`gate-09-agents.sh`](../tests/gates/gate-09-agents.sh)                                     | Every agent file matches §5.1 (frontmatter + H2 ordering + section constraints).                                 |
| 10 | [`gate-10-skills.sh`](../tests/gates/gate-10-skills.sh)                                     | Every skill matches §4.3 (frontmatter + ordered sections incl. mandatory **Gotchas** + no example bodies).       |
| 11 | [`gate-11-hook-scripts.sh`](../tests/gates/gate-11-hook-scripts.sh)                         | Every hook script matches §7.3 (header comment + exit codes + side-effect scope + bash-safety boilerplate).      |
| 12 | [`gate-12-mcp-json.sh`](../tests/gates/gate-12-mcp-json.sh)                                 | `.mcp.json` exact-matches the §3.1 server set; each entry has pinned `version` and `timeoutMs`.                  |
| 13 | [`gate-13-init-idempotent.sh`](../tests/gates/gate-13-init-idempotent.sh)                   | Re-running `init.sh` is idempotent (no errors, no duplicate writes).                                             |
| 14 | [`gate-14-markdown.sh`](../tests/gates/gate-14-markdown.sh)                                 | `markdownlint-cli2 --config .markdownlint.jsonc` and `prettier --check` pass on every Markdown.                  |
| 15 | [`gate-15-trademark.sh`](../tests/gates/gate-15-trademark.sh)                               | `README.md` contains a top-level `## Trademark notice` with the four required bullets (§15.4).                   |
| 16 | [`gate-16-skill-description.sh`](../tests/gates/gate-16-skill-description.sh)               | Every `SKILL.md` description ≤300 chars, ≥3 trigger keywords, no banned prefix.                                  |
| 17 | [`gate-17-skill-line-budget.sh`](../tests/gates/gate-17-skill-line-budget.sh)               | Every `SKILL.md` body (excluding frontmatter) is ≤500 lines.                                                     |
| 18 | [`gate-18-tool-name-budget.sh`](../tests/gates/gate-18-tool-name-budget.sh)                 | Longest `mcp__plugin_<plugin>_<server>__<tool>` < 64 chars (Bedrock limit, O3).                                  |

### 3.2 §11.D — Install-safety

| #  | File                                                                                        | Asserts                                                                                                       |
| -- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| 30 | [`gate-30-clean-roundtrip.sh`](../tests/gates/gate-30-clean-roundtrip.sh)                   | `install.sh --symlink` → `uninstall.sh` on a clean tree → byte-identical to pre-install.                      |
| 31 | [`gate-31-dirty-roundtrip.sh`](../tests/gates/gate-31-dirty-roundtrip.sh)                   | Same on a dirty tree with consumer-authored content under `.claude/specs|steering|hooks/` — preserved exactly. |
| 32 | [`gate-32-install-idempotent.sh`](../tests/gates/gate-32-install-idempotent.sh)             | Two consecutive `install.sh --symlink` runs produce a byte-identical manifest.                                |
| 33 | [`gate-33-dryrun-matches-real.sh`](../tests/gates/gate-33-dryrun-matches-real.sh)           | `uninstall.sh --dry-run` enumerates exactly the files the real `uninstall.sh` would remove.                   |

### 3.3 Numbering policy

- **1–18** reserved for §11.A.
- **19–27** reserved for §11.B (transcript-replay; not implemented
  as `gate-NN-*.sh` files — driven by `tests/run-transcripts.sh`).
- **28–29** reserved for §11.C (CI matrix wrappers around §11.A).
- **30–33** reserved for §11.D.
- **34** reserved for §11.E (release dogfood; runbook-driven).
- New §11.A gates land at the next free slot above 18 only after a
  spec amendment (§5.1 below).

---

## 4. Running gates locally

### 4.1 Full run (matches CI)

```bash
bash tests/gates/run-all.sh
```

Stops at the first failure. Add `--keep-going` to run every gate
and report the full list at the end:

```bash
bash tests/gates/run-all.sh --keep-going
```

### 4.2 Single gate

```bash
bash tests/gates/gate-06-powers.sh
bash tests/gates/gate-12-mcp-json.sh
# etc.
```

Single-gate invocation is the right loop while authoring or
debugging the artefact a gate covers.

### 4.3 What CI runs

CI invokes `bash tests/gates/run-all.sh` on `ubuntu-latest` and
`macos-latest` (gates 28–29). A gate must therefore stay portable
across both bash 5 and bash 3.2.

### 4.4 Output format

Every gate emits one of:

```text
PASS gate-06: 3 power files match power-bundle schema
WARN gate-06: powers/foo.power.json: missing required key 'name'
FAIL gate-06: 1 schema violations across 3 power files
```

Helpers come from
[`tests/gates/lib/common.sh`](../tests/gates/lib/common.sh) — use
`gate_pass`, `gate_fail`, `gate_warn`, `gate_info`. `gate_fail`
exits 1 immediately. Multi-violation gates accumulate `gate_warn`s
and end with a single `gate_fail` that summarises the count.

---

## 5. Adding a new gate

A new gate is a SPEC-v4 §11 amendment, not a freelance addition.
Follow this sequence to keep CI green at every step.

### 5.1 Spec amendment first

1. Open `docs/plan/SPEC-v4.md` and add the rule under the correct
   subsection (§11.A / §11.D / etc.). Use the next free gate
   number above 18 for §11.A or above 33 for §11.D.
2. If the gate references a new schema, add it under §9.
3. Cross-reference the gate from `SPEC.md` if user-visible.

### 5.2 Author the script

1. Create `tests/gates/gate-NN-<slug>.sh`. Use a short slug — match
   existing naming (`powers`, `mcp-json`, `skill-description`).
2. Start from this skeleton:

   ```bash
   #!/usr/bin/env bash
   # Gate NN: <one-line summary that matches SPEC-v4 §11 wording>.

   # shellcheck source=SCRIPTDIR/lib/common.sh
   source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

   GATE=NN

   cd "$PLUGIN_ROOT" || exit 1

   # … assertions, using gate_warn / gate_fail / gate_pass …

   gate_pass "$GATE" "<short success message including counts>"
   ```

3. Use the helpers, not raw `echo`:
   - `gate_pass "$GATE" "<msg>"` — success line. Exactly one per gate.
   - `gate_warn "$GATE" "<msg>"` — accumulates a violation; never
     exits.
   - `gate_fail "$GATE" "<msg>"` — exits 1 immediately. Use for
     terminal failure (missing file, summary at end).
   - `read_into VAR < <(cmd)` — bash 3.2-safe replacement for
     `mapfile -t`.
   - `extract_frontmatter <file>` — pulls YAML between the first
     two `---` lines.
   - `yaml_valid` — pipe-in YAML validator.
   - `plugin_files [pattern]` — walks the plugin tree skipping
     `.git`, `node_modules`, `.venv`, `tests/gates/cache`.

4. **Be permissive on the absent case.** When the artefact a gate
   guards doesn't exist yet, prefer `gate_pass "$GATE" "no-op"`
   over `gate_fail`. Gates ship in PRs that pre-date the artefact
   they guard; CI must stay green during the rollout. See
   `gate-06-powers.sh` and `gate-12-mcp-json.sh` for the pattern.

5. **Only assert what the spec mandates.** Resist the urge to add
   "while we're here" checks — each gate covers exactly one §11
   rule. Cross-reference checks belong to the v0.2 author-tooling
   wave (e.g. `aws-power-authoring`).

6. `chmod +x tests/gates/gate-NN-<slug>.sh`.

### 5.3 Validate the gate itself

```bash
# Shellcheck the new script
shellcheck tests/gates/gate-NN-<slug>.sh

# Run it
bash tests/gates/gate-NN-<slug>.sh

# Confirm the runner picks it up
bash tests/gates/run-all.sh
```

A new gate must:

- Pass on a tree where the asserted rule already holds.
- Fail loudly on a hand-broken fixture (sanity-check both polarities).
- Be picked up automatically by `run-all.sh` because `find` matches
  `gate-*.sh` lexicographically.

### 5.4 Wire CI

`gate-28` and `gate-29` are matrix wrappers — adding a new §11.A
gate automatically extends both because they delegate to
`run-all.sh`. No GH Actions edit needed.

### 5.5 Commit

```text
feat(gates): add gate NN for <one-line spec rule>
```

The PR description must reference the SPEC-v4 §11 amendment and
list which §11 gates the change makes pass.

---

## 6. Updating an existing gate

### 6.1 Tightening an existing assertion

Tightening (e.g. raising the line budget from 500→400) is a
breaking change for the artefacts the gate covers. Required steps:

1. Amend SPEC-v4 §11 wording first.
2. Update the gate script.
3. Update every artefact that would now fail in the same PR.
4. Run `bash tests/gates/run-all.sh` to confirm the fleet passes.
5. Commit:

   ```text
   feat(gates)!: tighten gate NN — <new rule>
   ```

### 6.2 Loosening an existing assertion

Loosening (e.g. allowing a previously-banned construct) is also a
spec change but not breaking for consumers. Same procedure as §6.1
without the `!`.

### 6.3 Bug-fix in a gate

If the rule is unchanged but the script is wrong (false positive,
crash on certain inputs), commit as `fix(gates):` with no spec
amendment. Add a regression test fixture under
`tests/fixtures/gates/<NN>/` if practical.

### 6.4 Renumbering

Don't. Gate numbers leak into PR descriptions, ADRs, and changelog
entries. A retired gate keeps its slot empty; new gates take the
next free slot above 18 / 33.

---

## 7. Retiring a gate

1. Amend SPEC-v4 §11 — strike the rule, leave the number entry as
   `Retired in vX.Y.Z — <reason>`.
2. Delete `tests/gates/gate-NN-<slug>.sh`.
3. The gate number is **not** reusable (see §6.4).
4. Commit:

   ```text
   feat(gates)!: retire gate NN — <one-line reason>
   ```

5. CHANGELOG breaking-change entry calling out the removed
   guarantee.

---

## 8. Gate-authoring checklist

Before opening a gate PR:

- [ ] SPEC-v4 §11 amended with the new/changed rule.
- [ ] Script lives at `tests/gates/gate-NN-<slug>.sh` and is
      executable.
- [ ] Script header comment matches the SPEC-v4 wording.
- [ ] Script sources `lib/common.sh` and uses `gate_*` helpers.
- [ ] Script handles the "artefact not yet present" case with
      `gate_pass` no-op.
- [ ] Script is `shellcheck` clean (gate 4 will catch this).
- [ ] Script runs green on the current tree.
- [ ] Script runs red on a hand-broken fixture.
- [ ] `run-all.sh` picks it up automatically.
- [ ] PR description lists which §11 numbers this PR makes pass.

---

## 9. Troubleshooting

| Symptom                                                  | Likely cause                                                                       | Fix                                                                                            |
| -------------------------------------------------------- | ---------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Gate passes locally on macOS, fails on Ubuntu            | bash 3.2 vs 5 difference (`mapfile`, `[[ =~ ]]` quirks, GNU-only flags).           | Use `read_into` instead of `mapfile`; feature-detect GNU-only options; see common.sh helpers.  |
| `gate-04 shellcheck`: `SC2086: Double quote to prevent…` | Unquoted variable expansion.                                                       | Quote the expansion or annotate with a `# shellcheck disable=` line scoped to one statement.   |
| Gate exits 0 but should have failed                      | Helper invocation order — `gate_warn` then forgetting the trailing `gate_fail`.    | Track violations in a counter and call `gate_fail` once at the end if `failed > 0`.            |
| `gate-12 unexpected servers`                             | Roster changed but `REQUIRED=()` array in the gate script not updated.             | Bump the array atomically with the `.mcp.json` edit (see [MCP-SERVERS-GUIDE.md §5.2](./MCP-SERVERS-GUIDE.md#52-authoring-steps-v02-server)). |
| `gate-14 prettier --check` fails                         | Markdown formatting drift.                                                         | `pnpm prettier --write '**/*.md'` then re-run.                                                 |
| `gate-13 init not idempotent`                            | `init.sh` writes are not safe-to-rerun.                                            | Guard writes with `[[ -f $f ]]` or use `install -m`-style overwrite-with-same-content.         |
| Gate passes but covers the wrong thing                   | Assertion drifted from spec wording.                                               | Re-read SPEC-v4 §11 entry; update header comment + assertion + spec in one PR.                 |
| `run-all.sh` skips the new gate                          | Filename doesn't match `gate-*.sh`, or missing executable bit (script still runs). | Rename to `gate-NN-<slug>.sh`; the runner uses `bash`, but executable bit is convention.       |

---

## 10. Future work

- **§11.B runtime gates (19–27)** ship with the transcript-replay
  harness in PR 25 (per `docs/plan/PR-PLAN.md`). The harness lives
  at `tests/run-transcripts.sh`; assertions are JSON files under
  `tests/fixtures/transcripts/`.
- **`aws-power-authoring` skill (v0.2)** will deepen gate 6 with
  cross-reference resolution between Powers, `.mcp.json`, skills,
  hooks, and commands.
- **Performance budgets gate**: cap total `run-all.sh` wall time so
  the gate fleet stays usable as a pre-commit check. Pending an ADR
  amendment.
- **CI matrix expansion (gate 28/29)**: add Windows once the plugin
  ships a non-bash entry path. Out of scope at v0.1.0.
