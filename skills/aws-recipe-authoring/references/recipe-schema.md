# Recipe schema — field-by-field reference

> Schema authority: SPEC-v4 §9.1. Validation authority:
> `tests/gates/gate-06-recipes.sh`.

Every `recipes/<name>.recipe.json` is a single JSON object with these
required keys. Optional keys are deferred to v0.2.

## Required fields

| Field         | Type     | Constraint                                                                                                                           |
| ------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `name`        | string   | Matches the filename stem without `.recipe.json`. Must start with `claude-aws-architect-`. Lowercase, kebab-case after the prefix.   |
| `version`     | string   | SemVer (`MAJOR.MINOR.PATCH`). Never reuse a published version. New recipes start at `0.1.0`.                                         |
| `description` | string   | One sentence. Plain text. No trailing period required. Names the workflow profile and the bundle's substance.                        |
| `mcpServers`  | string[] | ≥1 entry. Each name must exist as a key in `.mcp.json`. Use short keys (`kb`, `iac`, `cost`, `sec`, `iam`, `cw`), not logical names. |
| `skills`      | string[] | Each name must exist as a directory under `skills/`. Must include the substrate trio unless the recipe documents an exception.       |
| `hooks`       | string[] | Each name must match a `name` field in `hooks/hooks.json`. Must include `aws-secret-scanner` at minimum.                             |
| `commands`    | string[] | Each name must match a filename under `commands/`, stripped of the `.md` suffix. Must include `aws` and `aws-spec` at minimum.       |

## Field order

Canonical key order for diff readability:

```json
{
  "name": "...",
  "version": "...",
  "description": "...",
  "mcpServers": [...],
  "skills": [...],
  "hooks": [...],
  "commands": [...]
}
```

## Substrate defaults

Every recipe should include these unless there is a documented reason
to omit:

| Slot         | Default                                                        |
| ------------ | -------------------------------------------------------------- |
| `mcpServers` | `kb` (knowledge base) — read-only AWS docs/SOPs                |
| `skills`     | `aws-mcp-routing`, `aws-spec-grounding`, `aws-grounding-cache` |
| `hooks`      | `aws-secret-scanner`                                           |
| `commands`   | `aws`, `aws-spec`                                              |

Extend per workflow:

- Recipes that touch AWS write verbs add `aws-api-write-guard` to `hooks`.
- Recipes that need host-tooling validation add `aws-doctor` to `commands`.
- Recipes that author IaC add `iac` to `mcpServers` and the
  cost/reliability/op-ex pillar skills to `skills`.
- Recipes that estimate spend add `cost` to `mcpServers` and
  `aws-waf-cost-optimization-skill` to `skills`.
- Recipes that review security add `sec`, `iam` to `mcpServers` and
  `aws-waf-security-skill` to `skills`.

## Forbidden patterns

- An empty `mcpServers` array — every recipe must consult at least one
  AWS knowledge surface.
- A `commands` array without `aws` — recipes are exercised through
  the orchestrator, which is the `aws` command.
- A `name` that does not match the filename — gate 6 fails the build.
- A `name` without the `claude-aws-architect-` prefix — collides with
  other plugins on a multi-plugin host.

## Deferred fields (v0.2)

The following keys are reserved and MUST NOT appear in v0.1.0
recipes:

- `activation` — dynamic trigger block (file patterns, keywords,
  inclusion mode). Pending the `/aws-recipe` runtime resolver.
- `extends` — recipe composition. Pending an ADR on inheritance vs
  flat-bundle semantics.
- `inputs` — parameterised recipes. Pending consumer demand.
