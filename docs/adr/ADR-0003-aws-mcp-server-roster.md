# ADR-0003: AWS MCP server roster — v0.1.0 selection and v0.2 expansion list

- **Status:** Accepted
- **Date:** 2026-05-02
- **Tier:** v0.1.0
- **SPEC anchor:** §3.1 (v0.1.0 roster), §3.2 (v0.2 candidates), §3.3 (deferred), §3.4 (skipped), §3.5 (degraded modes)

## Context

The `awslabs.*` MCP server family covers 30+ servers spanning docs, IaC, pricing, security, identity, observability, and dozens of service planes (DDB, Postgres, Aurora, Bedrock, EKS, ECS, …). Naively wiring all of them into `.mcp.json` would:

- Inflate the install footprint and `uvx` startup cost.
- Multiply the surface area for prompt injection (each server is a trust boundary per §16.3).
- Force every L3 specialist to reason about server selection (§4.2 #6 `aws-mcp-routing`) over a roster too large to fit in a routing rule table.
- Lock the v0.1.0 release to a roster that's almost certainly going to need pruning once real-user telemetry arrives.

At the same time, dropping below a critical mass of servers cripples the plugin's grounding promise (§F4): without `aws-knowledge`, factual claims have no citation; without `aws-iac`, IaC validation degrades to advisory; without `iam` and `well-architected-security`, the security pillar's review surface is checklist-only.

The roster decision is therefore a sizing decision under two constraints: **enough servers to honour grounding and the WAF pillars, no more than the v0.1.0 release can dogfood and CI-validate**.

## Decision

Ship **6 MCP servers at v0.1.0** (§3.1):

1. `awslabs.aws-knowledge-mcp-server` (HTTP) — docs, API refs, What's New, WAF guidance.
2. `awslabs.aws-iac-mcp-server` — CloudFormation/CDK validation, scanning, samples.
3. `awslabs.aws-pricing-mcp-server` — Pricing API and cost estimation.
4. `awslabs.well-architected-security-mcp-server` — WAF security findings, GuardDuty / Security Hub triage.
5. `awslabs.iam-mcp-server` — IAM read and simulate; the least-privilege loop's authoritative source.
6. `awslabs.cloudwatch-mcp-server` — post-deploy observability evidence (alarms, log-insights queries).

The roster maps cleanly to the v0.1.0 specialist set:

- **Discovery** → `aws-knowledge`.
- **Solution-architect** → `aws-knowledge`, `aws-iac`.
- **Implementation** → `aws-iac`, `aws-pricing`, `iam`, `cloudwatch`.
- **All agents** can reach `well-architected-security` through the security-pillar skill.

**v0.2 expansion list (4)** is recorded in §3.2 as a deliberate pre-commit, not a wishlist:

- `aws-api-mcp-server` — gated on §7 write-guard hooks reaching production stability (most write-capable surface; needs the strongest hook coverage).
- `bedrock-agentcore` — bundled with the deferred `claude-aws-architect-bedrock` Recipe.
- `dynamodb` — added when a specialist actually needs authoritative DDB modelling.
- `aws-serverless` — added with `claude-aws-architect-iac-foundations` Recipe.

**Deferred to v0.3+ (§3.3)**: docs offline mirror, billing-cost-management, lambda/stepfunctions tool servers, mcp-proxy. **Skipped (§3.4)**: container plane, non-DDB data planes, cache plane, Bedrock subordinates, niche servers, domain-specific health servers, deprecated `ccapi`. The skip list is an explicit non-goal so it isn't relitigated each release.

Every v0.1.0 server entry carries an explicit `version` pin (per §16.2) and a `timeoutMs` (per O2). Each server has a documented degraded-mode behaviour (§3.5); failures are **surfaced**, not silently dropped.

## Alternatives considered

- **Maximalist roster (all 30+ `awslabs` servers).** Rejected: install latency, trust-boundary count, and routing complexity all grow non-linearly with server count.
- **Minimalist roster (only `aws-knowledge`).** Rejected: collapses grounding to docs-only and forces the implementation agent to fabricate IaC validation, pricing, and IAM checks — exactly the failure mode the plugin exists to prevent.
- **Include `aws-api-mcp-server` at v0.1.0.** Rejected: it exposes broad write capability. v0.1.0 cannot land it before the §7 write-guard hooks have real-world coverage. Pre-committed for v0.2 once the guard surface is proven (§3.2).
- **Include a container-plane server (EKS or ECS) at v0.1.0.** Rejected: container topology is a substantial surface that would dominate v0.1.0's specialist time budget without serving the WAF pillars proportionally. Deferred to v0.3+ via §3.4.
- **Include `bedrock-kb-retrieval` and Bedrock subordinates.** Rejected at v0.1.0: AgentCore alone covers the GenAI surface needed for most prompts; subordinates are only useful inside larger Bedrock builds, which arrive with the v0.2 Bedrock Recipe.
- **Skip the security pillar server, rely on rules + IAM only.** Rejected: removes WAF findings and GuardDuty / Security Hub triage from the security pillar's review surface, which contradicts §F22 and gates 1–4 of §11.A.

## Consequences

**Positive.**

- Roster covers all six WAF pillars at v0.1.0 with no gaps the WAF pillar skills (§4.2 #7–12) cannot route to a server or to a documented degraded-mode fallback.
- Pinned versions and per-server timeouts (§16.2, O2) make supply-chain monitoring and runtime budget enforcement deterministic.
- Roster size (6) fits the parallel cap N13 (3 simultaneous calls) without contention pathologies — most queries hit at most 2 servers per L3 invocation.
- Skip list (§3.4) is an explicit non-goal; future contributors are not pulled into one-off integration requests for excluded servers.

**Negative.**

- **No write-API surface at v0.1.0.** Plugin cannot apply CDK changes itself; it generates artefacts the user runs. Acceptable for the SDLC artefact promise; explicitly revisited via the v0.2 `aws-api` entry once write-guards mature.
- **No DDB modelling assistance at v0.1.0.** Solution-architect must reason about DDB key design from docs grounding alone. Acceptable for v0.1.0; pre-committed for v0.2.
- **HTTP server (aws-knowledge) introduces a network dependency** that stdio servers don't. Mitigated by §3.5 degraded-mode rule — knowledge timeouts produce `grounding-deferred` markers, not silent failures.

## Revisit when

- Real-user telemetry shows >5% of prompts requiring a v0.2 candidate (e.g. DDB modelling). Outcome: pull that server into the next minor release.
- An `awslabs.*` server is deprecated or its package name changes. Outcome: a new ADR superseding this one with the replacement entry.
- A container-plane workflow (EKS/ECS) lands as a real-user demand. Outcome: draft a v0.3+ ADR with explicit threat-model treatment for the larger surface area.
- The §16.4 nightly version-skew check opens repeated upstream-breaking issues for a specific server. Outcome: drop the server from the next release and document the regression in CHANGELOG.
