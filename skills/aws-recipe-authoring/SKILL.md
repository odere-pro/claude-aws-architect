---
name: aws-recipe-authoring
description: |
  **WORKFLOW SKILL** — Build, update, and use recipe bundles under
  `recipes/*.recipe.json`. Validate the recipe schema, check
  MCP/skill/hook/command cross-references, run gate 6, and invoke
  a recipe via `@`-reference or the `/aws` orchestrator commands.
version: 0.1.0
---

## When to Use

Apply this skill any time a session touches a recipe bundle — authoring a new one, modifying an existing one, or using one to scope a piece of AWS work. The skill carries the full lifecycle so a single load covers the three workflows: build, update, use.

Trigger conditions:

- A new workflow profile is needed and no existing recipe covers it (build).
- An existing recipe references a skill, MCP, hook, or command that just changed (update).
- A user wants to scope a session to one workflow and is choosing between recipes (use).
- A reviewer is checking a PR that adds or modifies `recipes/*.recipe.json` (review-as-update).

Do not apply this skill for general AWS architecture work; use the workflow recipe itself (`cdk`, `cost`, `security`, `kb`, `bedrock-ai`) and the `/aws` orchestrator.

## Procedure

### Build a new recipe

1. **Scope the bundle.** One workflow profile per recipe. Avoid catch-all bundles. Confirm the gap by `ls recipes/` — if an existing recipe is close, prefer updating it.
2. **Pre-flight cross-references.** Every referenced artefact must already exist. Run the commands in `references/build-checklist.md` to list available MCPs (from `.mcp.json`), skills (from `skills/`), hooks (from `hooks/hooks.json`), and commands (from `commands/`). A recipe pointing at unmerged work fails review.
3. **Write the JSON.** Use `references/recipe-schema.md` as the authoritative field-by-field spec. Filename must be `claude-aws-architect-<topic>.recipe.json`; the inner `name` field must match the filename stem.
4. **Add substrate defaults.** Every recipe should include the substrate skills `aws-mcp-routing`, `aws-spec-grounding`, `aws-grounding-cache`; the substrate hook `aws-secret-scanner`; and the substrate commands `aws`, `aws-spec`. See `references/build-checklist.md` for when to extend.
5. **Validate locally.** Run `bash tests/gates/gate-06-recipes.sh` for shape. Cross-reference resolution is currently author discipline at v0.1.0; the deeper validation lands when the `/aws-recipe` command ships.
6. **Document.** Add a playbook at `docs/playbooks/<topic>-recipe-playbook.md` with AWS-200, AWS-300, and AWS-500 scenarios. Add a row to the reference table in `docs/recipes-guide.md` §6.
7. **Commit.** `feat(recipes): add claude-aws-architect-<topic> bundle`. The PR description must list gate 6.

### Update an existing recipe

1. **Classify the change.** Per `docs/recipes-guide.md` §4.1: typo → patch, added entry → minor, removed entry → major (breaking for consumers that loaded the bundle as a unit), rename → new file + deprecation.
2. **Bump `version`.** SemVer. Never reuse a published version.
3. **Re-verify cross-references.** For each newly-added entry, confirm it resolves against `.mcp.json` / `skills/` / `hooks/hooks.json` / `commands/`. Removing entries does not need a pre-check, but flag the breaking change in the PR.
4. **Re-run gate 6.** `bash tests/gates/gate-06-recipes.sh`. Re-run `bash tests/gates/run-all.sh` if hooks, MCPs, or commands also changed.
5. **Update the playbook.** Any added/removed capability must be reflected in `docs/playbooks/<topic>-recipe-playbook.md` so the worked scenarios remain accurate.
6. **Commit.** `chore(recipes): bump claude-aws-architect-<topic> to <version>` for patches, `feat(recipes):` for added capabilities, `feat(recipes)!:` for breaking removals or renames.

### Use a recipe in a session

1. **Pick the recipe.** Match the workflow to the table in `docs/recipes-guide.md` §6 or the index in `docs/playbooks/README.md`. One recipe per session; recipes do not stack at v0.1.0.
2. **Choose the invocation mode** per `references/usage-patterns.md`:
   - **Playbook-driven** — open `docs/playbooks/<topic>-recipe-playbook.md`, copy the AWS-200/300/500 trigger phrase, run via `/aws`.
   - **Direct `@`-reference** — paste `@recipes/claude-aws-architect-<topic>.recipe.json` followed by the request; Claude reads the bundle and steers toward the listed skills/MCPs.
   - **Orchestrator-routed** — invoke `/aws <prompt>`; the orchestrator selects skills and MCPs by depth-classification rules, and the recipe's bundle is the contract for what should be exercised.
3. **Verify the bundle fired.** After the session, check that the recipe's declared hooks ran (e.g. `aws-secret-scanner` always; `aws-api-write-guard` on write-verb workflows) and that any cited MCP server appears as a `<server>:<short-key>` reference in the grounding ledger.

## Gotchas

- **Do not author a recipe that points at unmerged artefacts.** Gate 6 enforces shape, not cross-references. A recipe naming a missing skill silently breaks at use time. Always pre-flight per step 2.
- **Do not assume a recipe gates loading.** All skills, MCPs, and hooks declared in the plugin tree load session-wide regardless of which recipe is "active". Recipes are routing recommendations, not load-time gates.
- **Do not rename a recipe in-place.** The `name` field is the user-visible identifier and is referenced from playbooks, docs, and consumer prompts. Rename via deprecation per `docs/recipes-guide.md` §4.3.
- **Do not bundle every skill into one recipe.** The value is curation. A bundle covering everything is functionally the same as no bundle.
- **Do not skip the playbook update on bundle change.** A recipe whose playbook lists capabilities the JSON no longer carries (or vice versa) misleads users at exactly the moment they are choosing which recipe to invoke.
- **Do not use a recipe to mix workflows.** One workflow profile per recipe; if a session needs CDK _and_ cost-review, run the CDK recipe and lean on its bundled cost MCP, not two recipes in one prompt.

## Boundaries

- This skill MUST NOT introduce new MCP servers, skills, hooks, or commands as a side-effect of authoring a recipe. The underlying artefact lands in its own PR first.
- This skill MUST NOT bypass gate 6. Even a typo-fix patch goes through the gate.
- This skill MUST NOT load a recipe at runtime — there is no runtime loader at v0.1.0. The `/aws-recipe` command and the dynamic resolver are deferred.
- This skill MUST NOT modify `tests/gates/gate-06-recipes.sh` to relax validation. Schema tightening lands in a separate PR with an ADR.
- This skill MUST NOT expand a recipe beyond the §9.1 field set (`name`, `version`, `description`, `mcpServers`, `skills`, `hooks`, `commands`). Optional activation fields are deferred to a future ADR.

## Quality Checks

Before merging a recipe change, confirm:

- The filename stem matches the inner `name` field, and both carry the `claude-aws-architect-` prefix.
- Every entry in `mcpServers` resolves to a key in `.mcp.json`.
- Every entry in `skills` resolves to a directory under `skills/`.
- Every entry in `hooks` resolves to a `name` in `hooks/hooks.json`.
- Every entry in `commands` resolves to a file under `commands/` (without the `.md` suffix).
- The substrate defaults (`aws-mcp-routing`, `aws-spec-grounding`, `aws-grounding-cache`, `aws-secret-scanner`, `aws`, `aws-spec`) are included unless there is a documented reason to omit.
- `bash tests/gates/gate-06-recipes.sh` reports `PASS`.
- The matching playbook in `docs/playbooks/<topic>-recipe-playbook.md` is updated for any added or removed capability.
- The reference table in `docs/recipes-guide.md` §6 is updated when a new recipe is added.
- The SemVer bump matches the change class per `docs/recipes-guide.md` §4.1.
