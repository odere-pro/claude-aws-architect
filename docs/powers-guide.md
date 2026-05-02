# Powers — author & maintenance guide

A **Power** is a JSON bundle that groups a curated set of plugin
capabilities — MCP servers, skills, hooks, and commands — under one
name a user can opt into. This guide covers how to set up, add, and
update Powers shipped by `claude-aws-architect`.

> Schema authority: [SPEC-v4 §9.1](./plan/SPEC-v4.md). Validation
> authority: [`tests/gates/gate-06-powers.sh`](../tests/gates/gate-06-powers.sh).

---

## 1. Where Powers live

```text
powers/
├── claude-aws-architect-cdk.power.json
├── claude-aws-architect-cost.power.json
├── claude-aws-architect-kb.power.json
└── claude-aws-architect-security.power.json
```

- Files live at `powers/*.power.json` at the plugin root.
- Filename **must** be `<name>.power.json` where `<name>` matches the
  `name` field inside the file. Gate 6 fails the build otherwise.
- Filename `<name>` **must** start with the `claude-aws-architect-`
  prefix (CLAUDE.md naming policy) so the bundle never collides with
  another plugin's Power on a multi-plugin host.

---

## 2. Schema

Every `powers/<name>.power.json` is a single JSON object with these
required keys:

| Key           | Type     | Constraint                                                                |
| ------------- | -------- | ------------------------------------------------------------------------- |
| `name`        | string   | Matches filename without `.power.json`. Prefixed `claude-aws-architect-`. |
| `version`     | string   | SemVer (e.g. `0.1.0`).                                                    |
| `description` | string   | One sentence. Plain text. No trailing period required.                    |
| `mcpServers`  | string[] | ≥1 entry. Each name must exist in `.mcp.json`.                            |
| `skills`      | string[] | Each name must exist as `skills/<name>/`.                                 |
| `hooks`       | string[] | Each name must match a `hooks[].name` in `hooks/hooks.json`.              |
| `commands`    | string[] | Each name must exist as `commands/<name>.md` (no `.md` suffix).           |

Minimal template:

```json
{
  "name": "claude-aws-architect-<topic>",
  "version": "0.1.0",
  "description": "<one-sentence description of what this Power bundles and when to load it>",
  "mcpServers": ["<server-from-.mcp.json>"],
  "skills": ["<skill-dir-name>"],
  "hooks": ["<hook-name-from-hooks.json>"],
  "commands": ["<command-file-stem>"]
}
```

---

## 3. Setup — adding a new Power

### 3.1 Decide the bundle scope

Pick a single, named workflow profile a user would opt into in one
step. Examples already shipped: CDK authoring, cost-only review,
security-only review. Avoid Powers that just re-export everything —
the value is curation.

### 3.2 Pre-flight: confirm every reference resolves

A Power can only reference artefacts that already exist in the
plugin tree. Before authoring, verify the targets:

```bash
# MCP servers
jq -r '.mcpServers | keys[]' .mcp.json

# Skills (directory names under skills/)
ls -1 skills/

# Hooks (names declared in hooks/hooks.json)
jq -r '.hooks[].name' hooks/hooks.json

# Commands (filenames under commands/, minus .md)
ls -1 commands/ | sed 's/\.md$//'
```

If a reference is missing, ship the underlying artefact first in its
own PR; do not author a Power that points at unmerged work.

### 3.3 Create the file

```bash
cat > powers/claude-aws-architect-<topic>.power.json <<'JSON'
{
  "name": "claude-aws-architect-<topic>",
  "version": "0.1.0",
  "description": "<one sentence>",
  "mcpServers": ["kb"],
  "skills": ["aws-mcp-routing", "aws-spec-grounding", "aws-grounding-cache"],
  "hooks": ["aws-secret-scanner"],
  "commands": ["aws", "aws-spec"]
}
JSON
```

Defaults to copy from existing Powers (recommended baseline):

- `aws-mcp-routing`, `aws-spec-grounding`, `aws-grounding-cache` are
  the substrate skills every Power should include — they wire MCP
  routing, citation discipline, and the grounding-ledger cache.
- `kb` (knowledge base MCP) is a sensible default `mcpServers` entry
  for any AWS-shaped Power.
- `aws-secret-scanner` is the minimum hook bar; add
  `aws-api-write-guard` for any Power that touches AWS write verbs.
- `aws`, `aws-spec` are the commands every Power should expose;
  add `aws-doctor` for Powers that need host-tooling validation.

### 3.4 Validate locally

```bash
# Gate 6 alone (fast)
bash tests/gates/gate-06-powers.sh

# All gates (matches CI)
bash tests/gates/run-all.sh
```

Gate 6 enforces:

1. Valid JSON.
2. `name`, `version`, `description` non-empty.
3. `mcpServers`, `skills`, `hooks`, `commands` are arrays.
4. `name` field matches the filename stem.

> Note: gate 6 today enforces shape only. Cross-reference resolution
> (does each `mcpServers` name actually exist in `.mcp.json`, etc.)
> is left to author discipline at v0.1.0 — the
> `aws-power-authoring` skill that deepens this check is deferred to
> v0.2 ([SPEC-v4 §13](./plan/SPEC-v4.md#13)). Always run §3.2
> manually.

### 3.5 Markdown / formatting gates

Powers are JSON, so prettier/markdownlint don't apply. But if you
also document the Power (for example in `SPEC.md` or the README),
those edits go through gate 14 (`prettier --check` and
`markdownlint-cli2`).

### 3.6 Commit and PR

Per `docs/plan/PR-CONVENTIONS.md`:

```text
feat(powers): add claude-aws-architect-<topic> bundle
```

The PR description must list the §11 gates the change makes pass —
at minimum gate 6.

---

## 4. Updating an existing Power

### 4.1 What counts as a change

| Change                                        | Bump                   |
| --------------------------------------------- | ---------------------- |
| Typo in `description`                         | patch                  |
| Added a skill / hook / command / MCP server   | minor                  |
| Removed a skill / hook / command / MCP server | major                  |
| Renamed the Power                             | new file + deprecation |

A removed reference is breaking for any consumer that loaded the
Power as a unit, so it is always a major bump.

### 4.2 Procedure

1. Edit the JSON in place. Keep keys in the canonical order
   (`name`, `version`, `description`, `mcpServers`, `skills`,
   `hooks`, `commands`) for diff readability.
2. Bump `version` per §4.1.
3. Re-run §3.2 cross-reference checks for any newly-added entries.
4. Re-run `bash tests/gates/gate-06-powers.sh`.
5. Commit:

   ```text
   chore(powers): bump claude-aws-architect-<topic> to <new-version>
   ```

   or `feat(powers):` if a capability was added.

### 4.3 Renaming a Power

Renaming changes the user-visible identifier. Treat as a deprecation:

1. Create the new file (`powers/claude-aws-architect-<new>.power.json`)
   with `version: 1.0.0`.
2. Leave the old file in place for one minor release with a
   `description` that says `Deprecated: use <new>.`.
3. Remove the old file in the next release with a `feat(powers)!:`
   commit.

---

## 5. Removing a Power

1. Delete `powers/<name>.power.json`.
2. Update `SPEC.md:63` if the count of shipped Powers changes.
3. Update any docs that referenced the bundle by name.
4. Major version bump on the plugin if a removed Power was part of a
   GA release.
5. Commit:

   ```text
   feat(powers)!: remove claude-aws-architect-<topic> bundle
   ```

---

## 6. Reference — Powers shipped at v0.1.0

> **Production-ready scenarios:** see [`docs/playbooks/`](./playbooks/README.md) for one playbook per Power, each with AWS-200 / AWS-300 / AWS-500 use cases.

| File                                                                                             | MCPs                | Hooks                                       | Commands                        | Pillar focus                                           |
| ------------------------------------------------------------------------------------------------ | ------------------- | ------------------------------------------- | ------------------------------- | ------------------------------------------------------ |
| [`claude-aws-architect-cdk.power.json`](../powers/claude-aws-architect-cdk.power.json)           | `iac`, `cost`, `kb` | `aws-secret-scanner`, `aws-api-write-guard` | `aws`, `aws-spec`, `aws-doctor` | CDK authoring + ROM cost + reliability + op excellence |
| [`claude-aws-architect-cost.power.json`](../powers/claude-aws-architect-cost.power.json)         | `cost`, `kb`        | `aws-secret-scanner`                        | `aws`, `aws-spec`               | Cost-only review                                       |
| [`claude-aws-architect-kb.power.json`](../powers/claude-aws-architect-kb.power.json)             | `kb`                | `aws-secret-scanner`, `aws-api-write-guard` | `aws-kb`                        | Read-only KB lookup, CLI reference, SOPs, onboarding   |
| [`claude-aws-architect-security.power.json`](../powers/claude-aws-architect-security.power.json) | `sec`, `iam`, `kb`  | `aws-secret-scanner`, `aws-api-write-guard` | `aws`, `aws-spec`, `aws-doctor` | Security-only review                                   |

---

## 7. Troubleshooting

| Symptom                                              | Likely cause                                               | Fix                                                      |
| ---------------------------------------------------- | ---------------------------------------------------------- | -------------------------------------------------------- |
| `gate-06: invalid JSON`                              | Trailing comma, missing quote, syntax error.               | `jq . powers/<file>.power.json` to locate.               |
| `gate-06: name '<x>' does not match filename '<y>'`  | File renamed but `name` field not updated (or vice versa). | Make filename and `name` match.                          |
| `gate-06: '<key>' must be an array, got <type>`      | Wrote a string where an array is required.                 | Wrap in `[ … ]` even if there is one entry.              |
| Power loads but a referenced skill/hook does nothing | Name typo — gate 6 does not yet cross-check existence.     | Re-run §3.2 manual checks.                               |
| MCP server name unknown at runtime                   | `mcpServers` entry not in `.mcp.json`.                     | Add the server to `.mcp.json` first or correct the name. |

---

## 8. Future work

- **`aws-power-authoring` skill** (deferred to v0.2,
  [SPEC-v4 §13](./plan/SPEC-v4.md#13) — deepens gate 6 to validate
  every cross-reference (`mcpServers` ↔ `.mcp.json`, `skills` ↔
  `skills/`, `hooks` ↔ `hooks.json`, `commands` ↔ `commands/`).
- **`/aws-power` command** (deferred to v0.2, SPEC-v4 §1 F8) —
  user-facing introspection of installed Powers.
