# Build / update checklist

Run these checks before opening a PR that adds or modifies a recipe.

## Pre-flight: confirm every reference resolves

```bash
# MCP servers (keys in .mcp.json)
jq -r '.mcpServers | keys[]' .mcp.json

# Skills (directory names under skills/)
ls -1 skills/

# Hooks (names declared in hooks/hooks.json)
jq -r '.hooks[].name' hooks/hooks.json

# Commands (filenames under commands/, minus .md)
ls -1 commands/ | sed 's/\.md$//'
```

If any name in the recipe does not appear in the matching list,
either ship the underlying artefact first or correct the typo.

## Build flow

1. Pick a workflow profile no existing recipe covers. Read the
   `description` of each existing recipe to confirm the gap.
2. Draft the JSON in canonical key order (`name`, `version`,
   `description`, `mcpServers`, `skills`, `hooks`, `commands`).
3. Start `version` at `0.1.0`. Set `description` to a single sentence
   that says what the bundle is for, not what it contains.
4. Include the substrate defaults from `recipe-schema.md` unless there
   is a documented reason to omit.
5. Validate locally:

   ```bash
   bash tests/gates/gate-06-recipes.sh
   bash tests/gates/run-all.sh --keep-going  # if hooks/MCPs also changed
   ```

6. Add a playbook at `docs/playbooks/<topic>-recipe-playbook.md` with
   one AWS-200, one AWS-300, and one AWS-500 scenario.
7. Add a row to the reference table in `docs/recipes-guide.md` §6.
8. Commit:

   ```text
   feat(recipes): add claude-aws-architect-<topic> bundle
   ```

## Update flow

| Change                               | SemVer bump            |
| ------------------------------------ | ---------------------- |
| Typo in `description`                | patch                  |
| Added skill / hook / command / MCP   | minor                  |
| Removed skill / hook / command / MCP | major (breaking)       |
| Renamed recipe                       | new file + deprecation |

1. Edit in place. Keep keys in canonical order.
2. Bump `version` per the table above.
3. Re-run pre-flight cross-reference checks for any newly-added entries.
4. Re-run gate 6 and the full gate suite if hooks/MCPs changed.
5. Update the playbook to reflect any added or removed capability.
6. Commit:

   ```text
   chore(recipes): bump claude-aws-architect-<topic> to <new-version>
   ```

   Use `feat(recipes):` for added capabilities, `feat(recipes)!:` for
   breaking removals or renames.

## Rename flow

Renames change the user-visible identifier and are always breaking.

1. Create the new file (`recipes/claude-aws-architect-<new>.recipe.json`)
   with `version: 1.0.0`.
2. Leave the old file in place for one minor release with a
   `description` that says `Deprecated: use <new>.`.
3. Remove the old file in the next release with a `feat(recipes)!:`
   commit.
4. Update every doc that referenced the old name (`grep -rn <old>`).

## Gate 6 outcomes

| Outcome | Meaning                                                             |
| ------- | ------------------------------------------------------------------- |
| PASS    | All recipes match the §9.1 schema.                                  |
| WARN    | A specific recipe fails a check; other recipes may still be valid.  |
| FAIL    | One or more schema violations across the recipe set; PR is blocked. |

Gate 6 today validates shape only. Cross-reference resolution
(does each `mcpServers` name actually exist in `.mcp.json`, etc.) is
left to author discipline at v0.1.0 — always run the pre-flight
commands above.
