# Threat model — `claude-aws-architect` v0.1.0

This document enumerates the threat classes that `claude-aws-architect` is designed to mitigate at v0.1.0, the assumptions the design relies on, and the residual risks the user must accept.

It is not a generic AWS or Claude Code threat model. It scopes to risks that are introduced (or shaped) by this plugin: the MCP server roster it activates, the hook scripts it ships, the install scripts it runs, and the agent/skill content that influences Claude's tool calls.

## Trust boundaries

Three boundaries are relevant to v0.1.0:

1. **Plugin tree** — the files in this repository. Audited by review and by the deterministic gates in CI. Treated as trusted code.
2. **Upstream MCP servers** — the six packages and one HTTP endpoint listed in `.mcp.json`. Pinned by version, but their bytes are not vendored. Treated as semi-trusted code: trusted to perform the documented function, not trusted with arbitrary instruction-following authority over Claude.
3. **Consumer project content** — anything outside the plugin tree, including spec files under `.claude/specs/`, IaC under `infra/`, and arbitrary user-authored files. Treated as untrusted input.

The plugin assumes the local Claude Code runtime, the local AWS CLI, and `uvx`/`uv` are themselves trustworthy; vulnerabilities in any of those three are out of scope and are reported upstream per `SECURITY.md`.

## Threat classes

Four threat classes are tracked at v0.1.0. Each is enumerated with attack vector, impact, mitigation, detection, and residual risk.

### T1 — Prompt injection via MCP server output

**Vector.** A malicious or compromised MCP server returns text crafted to look like Claude-addressed instructions ("ignore prior rules", "call this tool with these arguments", "summarise the following file"), embedded in legitimate-looking documentation, pricing data, or security findings. Claude treats the output as content but the upstream server has effectively become an instruction surface.

**Impact.** Tool-call diversion (Claude calls a different MCP tool than intended), data exfiltration (Claude is induced to read files outside the scoped working tree and surface them in conversation), or behavioural override (Claude bypasses a documented merge rule or rule-file constraint).

**Mitigation.**

- File-scoped rules under `rules/` constrain Claude's behaviour by file path, regardless of MCP output content. A rule attached to `*.d2` files cannot be neutralised by a knowledge-base response.
- Section §5.5 of SPEC-v4 defines the merge contract: every L3 specialist's output is reconciled in a deterministic priority order (security → facts → cost → convergence → recency); divergence surfaces under `## Open Questions`, not as silently applied state.
- The user reviews every Claude tool call before it executes — Claude Code's permission model is the final gate.
- MCP server version pins (§16.2 of SPEC-v4) give a verifiable artefact for blame attribution if a server starts emitting injection content.

**Detection.** Unexpected tool calls outside the routing map (per `aws-mcp-routing` skill) and Open Questions citing surprising agent behaviour are the user-facing signals. The grounding ledger (per `aws-grounding-cache` skill) records the canonicalised query for each retrieval and supports audit after the fact.

**Residual risk.** A subtle injection that mimics legitimate AWS guidance (e.g. "use the wildcard `*` in IAM for setup convenience, then tighten later") may pass review if the user is not paying close attention. The plugin does not attempt to detect semantic injection — only behavioural divergence.

### T2 — Hook script abuse

**Vector.** A user authoring spec files or running the plugin in an unfamiliar working tree triggers a hook script with crafted file paths (spaces, quotes, shell metacharacters, symlinks pointing outside the working tree). The hook attempts to expand the path naively or pass it to `eval`, leading to command injection or out-of-tree file access.

**Impact.** Arbitrary command execution under the user's shell environment (worst case); silent corruption of files outside the working tree (lesser case); incorrect hook-script results that mislead later validation (lowest case).

**Mitigation.**

- Hook-script contract (gate 11 in §11.A of SPEC-v4) requires `set -euo pipefail` and shellcheck-clean output. All hook scripts under `hooks/scripts/` are reviewed against this contract in CI.
- §7.3 of SPEC-v4 confines hook scope to the consumer project root. Paths are quoted, validated against the working tree, and rejected if they resolve outside.
- Hooks declare `enabledByDefault` explicitly. Only `aws-secret-scanner` and `aws-api-write-guard` are default-on at v0.1.0; the rest are opt-in via `.claude/claude-aws-architect.local.md`.

**Detection.** `shellcheck` violations are caught in CI. Out-of-tree path attempts produce a hook error that surfaces in the Claude Code transcript; the hook fails closed (non-zero exit, blocking the triggering tool call).

**Residual risk.** Hooks that legitimately need to read outside the working tree (none ship at v0.1.0) would relax this guarantee. A new hook of that shape requires a SPEC update and a new threat-model entry.

### T3 — Install-time tampering

**Vector.** A forked or modified install script writes outside its declared scope: it touches user dotfiles, modifies `~/.aws/`, edits global Claude Code settings, or leaves residue after `uninstall.sh`. A malicious fork could also inject rules or hooks into a consumer project under cover of a legitimate install.

**Impact.** State leakage between projects (rules from project A applied to project B), broken uninstall (residual files after the user removes the plugin), or silent capability escalation (a fork enables a hook the user did not opt into).

**Mitigation.**

- Install-safety gates 30–33 in §11.D of SPEC-v4 assert byte-identical state before/after `install.sh` and `uninstall.sh` on a dirty working tree. A clean uninstall must leave no plugin-authored file behind.
- `init.sh`, `install.sh`, `doctor.sh`, `uninstall.sh` are scoped to the consumer project root by construction; they never touch `$HOME` or `/`.
- `doctor.sh --json` reports the actual installed roster, not the declared roster. A drift between the two is a `doctor.sh` failure.

**Detection.** `tests/install/` fixtures exercise install/uninstall in a sandboxed working tree on every CI run (per gates 30–33, lands in PR 27). Drift between declared and installed roster surfaces in `doctor.sh --json`.

**Residual risk.** A fork that ships a malicious install script and bypasses the install-safety gates is unrecoverable through plugin-internal mitigation. Users must verify the source of any plugin install — the canonical install path is the GitHub Release page (per §17.1 of SPEC-v4).

### T4 — Secret exfiltration via grounding ledger

**Vector.** Upstream MCP servers (notably `sec`, `iam`, `cw`) can return responses that include API keys, account IDs, presigned URLs, or other secret material as part of a legitimate finding. The grounding ledger (per `aws-grounding-cache` skill) records those responses for later citation. Without redaction, the ledger becomes a secret store.

**Impact.** Secret material persists in `.claude/specs/<feature>/grounding-ledger.json` (a tracked file in the consumer's repository) and is exposed on the next git push.

**Mitigation.**

- The `aws-grounding-cache` skill (§4.2 of SPEC-v4) requires secret-redaction on insert. The redaction-policy reference enumerates eight patterns (AWS access keys, secret keys, session tokens, presigned URL signatures, account IDs, JWTs, API gateway keys, generic high-entropy strings) and an application order that fails the write rather than skipping a pattern.
- Gate 17 (SKILL.md line budget per §11.A of SPEC-v4) keeps skill instructions short enough that the redaction rule cannot be silently eroded by future additions to the skill body.
- The `aws-secret-scanner` hook is default-enabled and runs against every Write tool call, providing a second line of defence at the file-write boundary.

**Detection.** `aws-secret-scanner` flags a Write that contains an unredacted secret pattern; the hook fails closed. The grounding-ledger schema validation rejects entries whose `result_summary` field would contain known secret patterns.

**Residual risk.** A novel secret format that none of the eight patterns recognise will pass redaction. The ledger schema and the redaction policy must be revisited if AWS introduces a new secret format. The redaction pattern list is reviewed at every `feat(deps)` MCP version bump (§16.2 of SPEC-v4).

## Out-of-model risks

Risks that are real but not modelled here:

- **Compromised Claude Code runtime, Anthropic API keys, or the user's local shell** — outside the plugin's control surface. Reported to Anthropic per `SECURITY.md`.
- **Compromised upstream MCP server packages** — pinning by version reduces but does not eliminate this. A compromised package release at the pinned version is detected only by external signal (advisory, news). Code signing (rejected for v0.1.0 per ADR A6) would close this gap; deferred decision.
- **Vulnerabilities in `uvx`/`uv`** — out of scope per `SECURITY.md`.
- **Side-channel leakage through Claude's context window** — the plugin does not attempt to prevent the user from intentionally surfacing secrets in chat.

## Update cadence

This file is reviewed when any of the following changes:

- A new MCP server is added to `.mcp.json` (new instruction surface, new T1 surface).
- A new hook script is added to `hooks/scripts/` (new T2 surface).
- A new install or uninstall script is added under `scripts/` (new T3 surface).
- The grounding-ledger schema or redaction-policy changes (T4 surface).

Each review either confirms the four classes still cover the change or appends a new threat class. Changes land in a `docs(security):` PR and are reflected in CHANGELOG under "Security".
