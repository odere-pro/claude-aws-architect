# ADR-0006: License, telemetry, listing strategy, and trademark posture

- **Status:** Accepted
- **Date:** 2026-05-02
- **Tier:** v0.1.0
- **SPEC anchor:** §15 (full posture)

## Context

A new public Claude Code plugin in the AWS space lands at a junction of four orthogonal decisions: license, telemetry, marketplace listing, and trademark posture. Each independently has failure modes that compound if they're inherited by accident:

- **License.** Permissive vs copyleft vs none-stated. None-stated is "all rights reserved" by default and effectively unusable. Copyleft (GPL family) rules out embedding inside proprietary consumer codebases — at odds with the plugin's primary use case.
- **Telemetry.** "Anonymous usage stats" defaults are routine in CLI tooling but high-friction in a tool that handles AWS account configuration; anything that phones home from inside an MCP-routing agent is a privacy red flag and a supply-chain risk.
- **Marketplace listing.** The Claude Code plugin ecosystem has multiple discovery indexes of varying maturity. Listing aggressively into all of them at v0.1.0 ships an under-baked plugin under multiple identities; listing only on GitHub starves discovery.
- **Trademark posture.** The plugin name (`claude-aws-architect`, ADR-0001) contains "AWS" — a registered trademark of Amazon. The relationship between this plugin and AWS is **descriptive only**, not affiliated; that has to be stated unambiguously to avoid both legal exposure and user confusion.

These four decisions were grouped into a single ADR because they're consumed together by the user (every decision is visible in `README.md` or in the install footprint) and because changing any one of them later is a marketing event, not a code change.

## Decision

**License — MIT.**

- Permissive: anyone may use, modify, redistribute, and embed in proprietary work.
- Standard for the Claude Code plugin ecosystem (matches the de-facto convention used by comparable AWS-tooling plugins).
- No contributor licence agreement at v0.1.0; contributions accepted under inbound = outbound.
- `LICENSE` file at repository root is committed before the v0.1.0 tag (per §15.1).

**Telemetry — none, ever, at v0.1.0.**

- Zero data collected, logged, or transmitted by the plugin or any of its agents, hooks, or scripts.
- The grounding ledger (§9.5) is local under `.claude/specs/<feature>/.grounding-ledger.json`, git-ignored, never read or transmitted by the plugin itself.
- `doctor.sh --json` emits structured output to stdout for the user's own diagnostic use; it makes no network calls beyond what `sts:GetCallerIdentity` requires.
- README states this explicitly under a `## Privacy` section so users do not have to infer it.

**Marketplace listing — delayed and curated.**

- v0.1.0: GitHub-only. Discovery via repository README, GitHub topic tags (`aws`, `claude-code`, `claude-plugin`, `aws-cdk`, `claude-skills`), and word-of-mouth.
- After v0.1.1 (first round of real-user bugfixes): submit to two community indexes — `skills.sh` and `awesome-claude-skills`. One submission each, tracked in CHANGELOG.
- Not listed at any tier: npm (Claude Code plugins are not npm packages), commercial marketplaces, ad-hoc awesome-\* repos beyond the two named.
- Each listing carries: short description matching `plugin.json#description`, screenshot of the dogfooded `sdlc-full-depth` example, and the install command.

**Trademark posture — descriptive, disclaimed.**

- README ships a top-level `## Trademark notice` section declaring:
  - Not affiliated with, endorsed by, or sponsored by Amazon Web Services, Inc. or its affiliates.
  - "AWS", "Amazon Web Services", "Well-Architected", and AWS service names are trademarks of Amazon.com, Inc. or its affiliates.
  - Pointer to the AWS trademark guidelines URL.
  - "AWS" appears in the plugin name as a descriptive token, not as a claim of affiliation.
- §11.A gate 15 enforces the four bullet points are present.

## Alternatives considered

- **Apache 2.0** instead of MIT. Considered: stronger patent grant. Rejected for v0.1.0: MIT is the plugin-ecosystem default; switching adds friction for downstream embedding without a concrete benefit a v0.1.0 plugin can articulate. Pre-committed to revisit if a corporate sponsor requires Apache 2.0 (per §15.5).
- **GPL-family license.** Rejected: copyleft would prevent embedding inside proprietary consumer projects, which is precisely the dominant use case.
- **No license file.** Rejected: equivalent to "all rights reserved" and effectively unusable. Causes immediate downstream friction and a wave of "what's the license?" issues.
- **Opt-in telemetry at v0.1.0.** Rejected: even opt-in adds a code surface that needs to be tested, audited, and documented; v0.1.0 has higher-leverage uses for the engineering hours. Re-considered for v0.2+ only if filing-issues workflow benefits from log capture, and only as opt-in local-only; remote telemetry is out of scope indefinitely (§15.5).
- **Anonymous usage stats opt-out.** Rejected on user trust grounds. A plugin with broad AWS read access cannot ship default-on telemetry without eroding the trust posture documented in §16.3.
- **Aggressive listing at v0.1.0** (all known indexes the day of tag). Rejected: ships an under-baked plugin to multiple audiences; bug reports fragment across indexes; harder to roll back. Delayed-and-curated landing in two named indexes after v0.1.1 is a deliberate baking window.
- **No listing at all (GitHub only, indefinitely).** Rejected: the plugin's value is realised when discovered. Permanent GitHub-only is a discoverability ceiling the project should not impose on itself.
- **Drop "AWS" from the plugin name** to avoid the trademark question. Rejected (recorded in ADR-0001): the name's discoverability depends on the descriptive token. Trademark disclaimer carries the legal load instead.
- **Skip the trademark notice and rely on disclaimer-by-license.** Rejected: MIT does not address trademark. The notice is a separate surface and is enforced by gate 15.

## Consequences

**Positive.**

- License posture is unambiguous and matches ecosystem default.
- Privacy posture is **structurally** zero-telemetry — there is no data-collection surface to maintain, audit, or roll back. The simplest possible privacy story.
- Listing posture lets v0.1.x bake on GitHub before broader discovery; bugs surface in a smaller blast radius.
- Trademark notice is enforced (gate 15); a future contributor cannot accidentally rebrand the plugin into an affiliation claim.

**Negative.**

- **No usage data** means the v0.2 prioritisation decisions (which deferred command, which deferred skill, which v0.2 MCP server) rely on user-reported demand and dogfood transcripts only. Acceptable for v0.1.0; documented as a deliberate trade-off in §15.5.
- **Listing delay** slows initial adoption. Acceptable: discoverability accrues once the plugin earns it through real-user testimony in v0.1.1 listings.
- **MIT** does not include an explicit patent grant. Acceptable for v0.1.0; revisitable per §15.5.

## Revisit when

- A corporate sponsor or major contributor requires Apache 2.0. Outcome: a new ADR with the license bump, alongside a CLA decision.
- Real-user demand surfaces a compelling case for opt-in local-only telemetry (§15.5). Outcome: a new ADR explicitly scoping the data, the storage, and the off-by-default contract.
- The two v0.1.1 listings drive measurable installs over a 60-day window and additional indexes become worth submitting to (§15.5). Outcome: extend §15.3 with the new listings.
- AWS publishes updated trademark guidelines that change the descriptive-use posture. Outcome: refresh the trademark notice and gate 15's enforced bullets.
- The Claude Code plugin marketplace contract finalises. Outcome: validate the listing strategy against the contract; update §15.3 if a marketplace listing becomes viable.
