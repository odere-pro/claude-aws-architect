# Intent → KB tool sequence

Loaded on demand by the `aws-kb-navigator` skill. Defines the six
read-only intents the kb-navigator agent classifies prompts into,
and the canonical `kb` MCP tool sequence each intent uses.

## Intent table

| Intent     | When it fires                                                                                                                 | Tool sequence                                                                                                                  | TTL class   |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ----------- |
| `lookup`   | Default for a verb-of-inquiry prompt with no flag (e.g., "what is Step Functions?").                                          | `kb:search_documentation` → `kb:read_documentation` (top hit only)                                                             | `immutable` |
| `cli`      | `--cli <service>` flag, or the prompt opens with `aws <service>` / "what does the AWS CLI for X do".                          | `kb:search_documentation` (filter on `aws <service>`) → `kb:read_documentation` → optional `kb:retrieve_agent_sop` for recipes | `immutable` |
| `compare`  | `--compare <a> vs <b>` flag, or the prompt names two services with a comparison verb ("X vs Y", "compare A and B").           | `kb:search_documentation` × 2 (one per subject) → `kb:read_documentation` × 2                                                  | `immutable` |
| `onboard`  | `--onboard <topic>` flag, or the prompt opens with "onboard", "introduce me to", "learn", "getting started".                  | `kb:search_documentation` → `kb:read_documentation` → `kb:recommend`                                                           | `immutable` |
| `next`     | `--next` flag with at least one prior grounding-ledger entry on this turn or a recent turn.                                   | `kb:recommend` against the most recent ledger entry; no other call                                                             | `immutable` |
| `region-q` | The prompt names a region question ("is X available in eu-central-2", "list regions for service Y", "regional availability"). | `kb:list_regions` and/or `kb:get_regional_availability`                                                                        | `region`    |

## Defaulting

If the prompt fires no flag and no clear intent verb, the default is
`lookup`. If the prompt names an SDLC artefact (`requirements`,
`design`, `tasks`, `runbook`, `threat-model`, `ROM`) or a
verb-of-creation, the kb-navigator agent does NOT classify intent —
it short-circuits and tells the caller to route to `/aws`.

## Budget accounting

Every intent counts every `kb` call against the per-turn 6-call cap.
`compare` is the most expensive intent (typically 4 calls: 2 search +
2 read). `onboard` typically uses 3. The rest stay at 1–2.

## TTL class summary

- `immutable` — applies to documentation pages and CLI reference
  retrievals; cache reuse is governed by `aws-grounding-cache`.
- `region` — applies to `list_regions` and `get_regional_availability`
  results; expires per the cache skill's region TTL window.
- `api-shape` — applies to `retrieve_agent_sop` results when the SOP
  exposes API verbs whose stability is tracked separately.
