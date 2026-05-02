# MCP Servers — setup, add & update guide

This guide covers how attached MCP (Model Context Protocol) servers
are configured, added, and updated for `claude-aws-architect`.

> Authoritative roster: [SPEC.md §MCP servers](../SPEC.md). Schema
> and roster rationale: [SPEC-v4 §3](./plan/SPEC-v4.md). Validation:
> [`tests/gates/gate-12-mcp-json.sh`](../tests/gates/gate-12-mcp-json.sh).
> Doctor probe: [`scripts/doctor.sh`](../scripts/doctor.sh).

---

## 1. Where MCP servers live

```
.mcp.json                  # plugin-root manifest (the contract)
scripts/doctor.sh          # local resolvability probe (uvx --help / curl)
tests/gates/gate-12-mcp-json.sh   # CI schema + roster gate
```

All wiring is declarative in `.mcp.json`. There is no per-server
glue code in this repo — servers are referenced by short key from
skills (e.g. `aws-mcp-routing`), agents, and Powers
(`powers/*.power.json#mcpServers`).

---

## 2. Naming conventions

Every entry in `.mcp.json#mcpServers` uses a **short key** so that
the fully-qualified tool name `mcp__plugin_<plugin>_<server>__<tool>`
stays under Bedrock's 64-character limit (SPEC-v4 O3).

| Short key | Logical name (in skills/agents) | Package                                        |
| --------- | ------------------------------- | ---------------------------------------------- |
| `kb`      | `aws-knowledge`                 | `https://knowledge-mcp.global.api.aws` (HTTP)  |
| `iac`     | `aws-iac`                       | `awslabs.aws-iac-mcp-server`                   |
| `cost`    | `aws-pricing`                   | `awslabs.aws-pricing-mcp-server`               |
| `sec`     | `well-architected-security`     | `awslabs.well-architected-security-mcp-server` |
| `iam`     | `iam`                           | `awslabs.iam-mcp-server`                       |
| `cw`      | `cloudwatch`                    | `awslabs.cloudwatch-mcp-server`                |

Rules of thumb when proposing a new short key:

- 2–4 lowercase ASCII characters, no separators.
- Must be unique within `.mcp.json`.
- Prefer the smallest unambiguous abbreviation of the logical name.
- Never reuse a short key after retirement — it will collide with
  cached `mcp__plugin_…` tool names in transcripts.

---

## 3. `.mcp.json` schema

`.mcp.json` is a single object with one top-level key, `mcpServers`,
mapping a short key to a server descriptor. Two transports are
supported.

### 3.1 stdio server (uvx-launched)

```json
{
  "mcpServers": {
    "<short-key>": {
      "command": "uvx",
      "args": ["--from", "<pypi-package>==<version>", "<entry-point>"],
      "version": "<version>",
      "timeoutMs": 30000
    }
  }
}
```

Required fields: `command`, `args`, `version`, `timeoutMs`.

- `command` is **always** `uvx` for stdio servers in this plugin.
  This is enforced indirectly by `scripts/doctor.sh`, which only
  probes entries where `command == "uvx"`.
- `args` must include `--from <pypi-package>==<version>` so the
  pinned wheel resolves deterministically. The trailing entry-point
  arg is the executable inside the wheel.
- `version` field **must equal** the pinned version inside `args`.
  Gate 12 will warn if the field is missing; the entry-point pin is
  the operational source of truth.
- `timeoutMs` per SPEC-v4 O2:

  | Workload                                  | Default `timeoutMs` |
  | ----------------------------------------- | ------------------- |
  | Read-only queries                         | 30000               |
  | Validation / scan operations              | 60000               |
  | AWS API calls (read-only)                 | 30000               |

### 3.2 HTTP server

```json
{
  "mcpServers": {
    "<short-key>": {
      "type": "http",
      "url": "https://<endpoint>",
      "version": "<version>",
      "timeoutMs": 30000
    }
  }
}
```

Required fields: `type`, `url`, `version`, `timeoutMs`.

- `type` must be `"http"`.
- `url` must be HTTPS. No auth headers are configured at v0.1.0; if
  a future server requires bearer auth, that lands as a separate
  ADR + manifest-schema update.
- `version` is the server's own SemVer (not the wire-protocol
  version).

### 3.3 What gate 12 enforces

[`tests/gates/gate-12-mcp-json.sh`](../tests/gates/gate-12-mcp-json.sh):

1. `.mcp.json` exists and is valid JSON.
2. `mcpServers` keys exactly match the v0.1.0 set
   `{kb, iac, cost, sec, iam, cw}` — no missing, no extras.
   Adding a server requires bumping the gate's `REQUIRED` array in
   the same PR (see §5.1).
3. Each entry has a non-empty `version`.
4. Each entry has an integer `timeoutMs`.

Cross-references from Powers (`mcpServers[]`) and skills
(`aws-mcp-routing`) to short keys are author-discipline at v0.1.0;
the deeper validator ships in v0.2.

---

## 4. Setup — local environment

### 4.1 Prerequisites

`scripts/doctor.sh` (a.k.a. the `/aws-doctor` slash command) checks
all three:

- `uvx` (Python launcher) on `PATH`. Install:
  `pipx install uv` or follow [astral.sh/uv](https://astral.sh/uv).
- `jq` on `PATH` (for `.mcp.json` introspection).
- `aws` CLI on `PATH` (for caller-identity and live AWS calls from
  `iam`, `cloudwatch`, `well-architected-security`).

### 4.2 Verify `.mcp.json` resolves

```bash
# Syntactic + roster gate
bash tests/gates/gate-12-mcp-json.sh

# Live resolution probe — runs uvx --from <pkg> --help for each
# stdio entry, plus aws sts get-caller-identity.
bash scripts/doctor.sh

# Equivalent in-session
/aws-doctor
```

A green doctor run means every stdio package resolves on PyPI at
the pinned version and your AWS credentials are valid. `kb` (HTTP)
is not probed live by doctor — its reachability is exercised
implicitly the first time the plugin queries the knowledge base.

### 4.3 Per-server credentials

| Server                      | Credentials needed                          |
| --------------------------- | ------------------------------------------- |
| `kb`                        | None — public AWS docs endpoint.            |
| `iac`                       | None for validation; AWS creds for samples. |
| `cost`                      | AWS creds in pricing region (`us-east-1`).  |
| `sec`                       | AWS creds with WAF security read scope.     |
| `iam`                       | AWS creds with IAM read + `iam:Simulate*`.  |
| `cw`                        | AWS creds with CloudWatch read scope.       |

The plugin never embeds AWS credentials. Use the standard SDK chain
(`AWS_PROFILE`, IRSA, `aws sso login`, etc.). The `aws-secret-scanner`
hook (PreToolUse, default-on) blocks any commit that ships a key.

---

## 5. Adding a new MCP server

A server addition is a **schema + roster + power + ADR** change, not
a one-line edit. Follow this order so CI stays green throughout.

### 5.1 Decide whether the server fits v0.1 or v0.2

- v0.1.0 has a frozen roster of six. Adding a seventh server at
  v0.1.0 is a roster change requiring a major rationale update —
  prefer slotting into v0.2.
- v0.2 candidates are listed in SPEC-v4 §3.2. New servers outside
  that list require an ADR amendment to `ADR-A3`.

### 5.2 Authoring steps (v0.2+ server)

1. **ADR entry.** Append to `ADR-A3 aws-mcp-server-roster.md` with
   the server's purpose, transport, package, version, timeout
   rationale, and the Power(s) that will reference it.
2. **`.mcp.json` entry.** Add the descriptor under a unique short
   key (§2). Pin both `args` and `version` to the same SemVer.
3. **Update gate 12.** Edit
   [`tests/gates/gate-12-mcp-json.sh`](../tests/gates/gate-12-mcp-json.sh)
   line `REQUIRED=(kb iac cost sec iam cw)` to include the new key.
4. **Update SPEC.md.** Append the row in the §MCP servers table
   (`SPEC.md:22`). Update the count in the section header.
5. **Update `aws-mcp-routing` skill.** Add the routing rule, the
   degraded-mode entry (per SPEC-v4 §3.5), and any tool-budget
   adjustment.
6. **Wire into a Power** (per
   [POWERS-GUIDE.md](./POWERS-GUIDE.md)) by adding the short key to
   `mcpServers[]`. A server that no Power references is dead weight
   and gate 6 will catch the orphan once the v0.2 cross-validator
   ships.
7. **Run doctor + gates.**

   ```bash
   bash scripts/doctor.sh
   bash tests/gates/gate-12-mcp-json.sh
   bash tests/gates/run-all.sh
   ```

8. **Commit.**

   ```text
   feat(mcp): add <short-key> (<package>) as <category> server
   ```

### 5.3 Authoring steps (v0.1.x patch — emergency add)

Only justified when an in-roster server is removed upstream and a
drop-in replacement must ship. Treat as a `feat(deps)!:` PR with
ADR-A3 amendment and CHANGELOG breaking-change entry.

---

## 6. Updating an existing MCP server

### 6.1 Version bumps

Pin updates land via a `feat(deps)` PR (SPEC.md:98). One PR per
server bump keeps blame readable.

1. Update `args` `--from <pkg>==<new-version>` and the sibling
   `version` field — they must stay equal.
2. Run `bash scripts/doctor.sh` to confirm the new wheel resolves
   on PyPI.
3. Run `bash tests/gates/gate-12-mcp-json.sh`.
4. Update `SPEC.md` version column.
5. Commit:

   ```text
   feat(deps): bump <short-key> to <new-version>

   <one-paragraph rationale: changelog highlights, breaking changes,
   why now.>
   ```

### 6.2 Timeout adjustments

Timeouts are an O2 policy decision, not a tuning knob. Raising a
timeout is a `chore(mcp):` PR with a one-line rationale referencing
observed call durations. Lowering a timeout is a `feat(mcp):` PR
because it can break consumers — call out the change in CHANGELOG.

### 6.3 Transport changes (stdio ↔ http)

A transport flip is a breaking change. Treat as removal + add:
deprecate the old short key for one minor release with a
"deprecated, will be removed in <next>" note in the ADR, then
remove and re-add under a new short key in the next release.

### 6.4 Renaming the short key

Don't. Short keys leak into transcript tool names and into every
Power that references them. If you must, treat exactly like §6.3.

---

## 7. Removing an MCP server

1. Confirm no Power, skill, agent, or rule references the short key.

   ```bash
   grep -rn "<short-key>" powers/ skills/ agents/ rules/ commands/
   ```

2. Delete the entry from `.mcp.json`.
3. Edit gate 12's `REQUIRED` array.
4. Update SPEC.md table and section header count.
5. Update ADR-A3 with the removal rationale.
6. Major version bump on the plugin.
7. Commit:

   ```text
   feat(mcp)!: remove <short-key> server

   Replaced by <successor> | Functionality moved to <skill> | etc.
   ```

---

## 8. Degraded-mode contract (SPEC-v4 §3.5)

Every server has a declared fallback. When you add a server, you
**must** declare its degraded behaviour in the SPEC-v4 §3.5 table
and in the `aws-mcp-routing` skill's `degraded-modes.md` reference.
The orchestrator labels degraded output (`grounding-deferred`,
`validation-advisory`, etc.) instead of silently dropping signal —
your new server needs a marker name.

Existing markers, by category:

| Category   | Marker                       | Meaning                                       |
| ---------- | ---------------------------- | --------------------------------------------- |
| Docs       | `grounding-deferred`         | Discovery couldn't ground a claim.            |
| IaC        | `validation-advisory`        | IaC validation downgraded; contract still emits. |
| Cost       | `grounding-deferred` (ROM)   | Cost estimate is a range, not a quote.        |
| Security   | `automated-assessment-unavailable` | Checklist-only; no live findings.       |
| IAM        | `least-privilege-deferred`   | Simulate-loop skipped; advisory only.         |
| Operations | `observability-incomplete`   | Test design only; no alarm/log evidence.      |

Reuse an existing marker if your server fits the category.

---

## 9. Reference — v0.1.0 roster

| Short | Logical                     | Transport | Pkg/URL                                               | Ver    | Timeout | Power(s) referencing      |
| ----- | --------------------------- | --------- | ----------------------------------------------------- | ------ | ------- | ------------------------- |
| `kb`  | aws-knowledge               | http      | `https://knowledge-mcp.global.api.aws`                | 0.1.0  | 30000ms | cdk, cost, security       |
| `iac` | aws-iac                     | stdio     | `awslabs.aws-iac-mcp-server`                          | 1.0.17 | 60000ms | cdk                       |
| `cost`| aws-pricing                 | stdio     | `awslabs.aws-pricing-mcp-server`                      | 1.0.28 | 30000ms | cdk, cost                 |
| `sec` | well-architected-security   | stdio     | `awslabs.well-architected-security-mcp-server`        | 0.1.7  | 60000ms | security                  |
| `iam` | iam                         | stdio     | `awslabs.iam-mcp-server`                              | 1.0.18 | 30000ms | security                  |
| `cw`  | cloudwatch                  | stdio     | `awslabs.cloudwatch-mcp-server`                       | 0.0.26 | 30000ms | (none yet — v0.2 ops Power) |

---

## 10. Troubleshooting

| Symptom                                                    | Likely cause                                                      | Fix                                                                                          |
| ---------------------------------------------------------- | ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `gate-12: missing required servers: <key>`                 | Roster reduced without bumping gate 12.                           | Re-add or update gate 12's `REQUIRED` array in the same PR.                                  |
| `gate-12: unexpected servers: <key>`                       | New server added without bumping gate 12.                         | Add the key to gate 12's `REQUIRED` array (§5.2 step 3).                                     |
| `gate-12: <key>: missing 'version' field`                  | Version pinned in `args` but not mirrored in the `version` field. | Add the `version` field; keep it equal to the version inside `args`.                         |
| `doctor.sh: <pkg> not resolvable via uvx`                  | Version yanked or never published.                                | Roll back to the prior pin or pick the next valid release; update both `args` and `version`. |
| `doctor.sh: aws sts get-caller-identity failed`            | No AWS credentials in the shell.                                  | `aws sso login` / set `AWS_PROFILE`; doctor will not run live AWS-call servers without it.   |
| Tool name `mcp__plugin_…__<tool>` exceeds 64 chars at use  | New short key too long, or wrapped tool name too long.            | Shorten the short key (§2); per SPEC-v4 O3 the chain must stay under 64.                     |
| Skill/agent references a missing server                    | Short key renamed without updating consumers.                     | `grep -rn "<old-key>"` and update all references atomically (§6.4 — don't rename).           |
| Server hits its `timeoutMs`                                | Network slowness or upstream rate-limit.                          | Confirm with two-or-more consecutive failures before raising; see §6.2.                      |

---

## 11. Future work

- **v0.2 server expansion** (SPEC-v4 §3.2): `aws-api-mcp-server`,
  `bedrock-agentcore-mcp-server`, `dynamodb-mcp-server`,
  `aws-serverless-mcp-server`. Each lands with its own ADR amendment
  and a Power that references it.
- **Cross-reference validator**: gate 12 currently checks `.mcp.json`
  shape only. The deeper validator (does every Power's `mcpServers[]`
  resolve, does every skill's routing rule reference a real key)
  ships with the `aws-power-authoring` skill in v0.2.
- **HTTP auth schema**: the v0.1.0 HTTP transport assumes
  unauthenticated endpoints. Bearer-token / SigV4 support lands when
  a roster candidate requires it.
