# ADR-0007: Supply chain and release model — pinning, signing, support, dogfood gate

- **Status:** Accepted
- **Date:** 2026-05-02
- **Tier:** v0.1.0
- **SPEC anchor:** §16 (security and supply chain), §17 (release and support model)

## Context

A Claude Code plugin that wires six AWS MCP servers, exposes shell hook scripts, and is installed by a script that touches the consumer's repository operates inside a non-trivial trust boundary. Four supply-chain and release questions had to be answered together, because any one taken in isolation produces a posture inconsistent with the others:

1. **MCP server version handling.** `uvx`-resolved packages and HTTP servers can move out from under a pinned plugin; a "latest" reference becomes a remote-controlled change to the plugin's behaviour without a corresponding plugin release.
2. **Release signing.** Signed commits and signed tarballs raise the bar for tampered releases but require key management infrastructure and contributor onboarding that v0.1.0 cannot reasonably staff.
3. **Support model.** A pre-1.0 plugin in a fast-moving ecosystem cannot credibly support multiple concurrent versions; trying to do so dilutes attention and produces stale branches.
4. **Release gate.** Standard "tests pass + reviewer approval" does not exercise the plugin's actual function. A plugin that promises end-to-end SDLC artefacts must demonstrate it can produce them — on itself — before tagging.

These four are coupled: pinning creates a maintenance load that justifies the single-version support model; deferred signing is acceptable only if version pinning is strict; the dogfood gate exists in part to catch regressions that pinning and version-skew checks alone miss.

## Decision

**MCP server version pinning — strict.**

- Every entry in `.mcp.json` carries an explicit `version` field. `uvx`-resolved targets pin to a specific package version (e.g. `awslabs.aws-knowledge-mcp-server==X.Y.Z`); HTTP servers pin to the documented stable URL with a `versionCheck` script that fails CI if the upstream version skews.
- §11.A gate 12 enforces presence of `version` on every server.
- A nightly scheduled GitHub Actions workflow runs the `versionCheck` script and opens (or updates) a tracking issue when an upstream MCP package version moves.

**GitHub Actions pinning — by SHA.**

- Every workflow under `.github/workflows/` pins each `uses:` reference to a full commit SHA, not a tag.
- Dependabot (Actions ecosystem only at v0.1.0) surfaces SHA updates as PRs.

**Code signing — deferred at v0.1.0.**

- Signed commits and signed releases are deferred. v0.1.0 ships unsigned. The trade-off is recorded here: the engineering hours for key management, contributor onboarding, and release-tooling integration are higher-leverage when spent on substrate authoring (§13) and the dogfood gate.
- Mitigated by version pinning, GitHub Actions SHA pinning, the threat model treatment of install-time tampering (§16.3), and the §11.D install fixtures asserting byte-identical state on dirty trees.

**Single supported version — v0.1.x at v0.1.0.**

- One supported version at a time at v0.1.x. No backports unless the active version is v1.0+.
- Hotfixes for v0.1.x security issues land on `main` while v0.2 is in development; switch to a `release/0.1.x` branch only when v0.2 is the active line.
- SemVer per §N9; pre-1.0 minor versions may break public spec interfaces, with every break called out in CHANGELOG.

**Release gate — dogfood is mandatory.**

- v0.1.0 cannot tag until §11.E gate 34 (release dogfood) passes: the plugin successfully designs itself when run against the design-intent prompt declared in §13.G.
- Acceptance criteria are declarative (§13.G): the generated meta-spec passes every gate in §11.A and §11.B, names every L3 specialist in `design.md`, includes one contract per L3 specialist plus the orchestrator, carries every layer tag in `diagrams.d2`, and has ≥1 grounded citation against `aws-knowledge`.
- If the plugin cannot design itself, v0.1.0 does not tag. The failure mode is documented, fixed, and re-attempted.

## Alternatives considered

- **Range pins instead of exact pins** (e.g. `^X.Y.0`). Rejected: range pins reintroduce the "remote-controlled change" failure mode the version field exists to prevent. The version-skew check is the supervised mechanism for moving forward.
- **No pinning, daily pull.** Rejected: the plugin's behaviour would change without a release. Unauditable.
- **Sign commits and releases at v0.1.0.** Considered: the security upside is real. Rejected for v0.1.0 on cost-of-staffing grounds and because the install-time-tampering threat is independently mitigated by §11.D fixtures and SHA-pinned Actions. Pre-committed to revisit at v0.2+ when contributor onboarding has more headroom.
- **Multiple supported versions in parallel** (e.g. v0.1.x and v0.2.x both supported). Rejected: pre-1.0 maintenance dilutes attention; back-porting fixes across an interface-breaking minor bump is high-cost low-value. Single-line support is the only credible posture pre-1.0.
- **Standard release gate** (CI green + reviewer approval, no dogfood). Rejected: a plugin that promises end-to-end SDLC artefacts must prove it can produce them on a non-trivial input. The dogfood gate is the cheapest instrument that proves it; absent the gate, the plugin can ship with a class of regressions (substrate-iceberg, merge-contract drift, schema shift) that no other gate detects.
- **Dogfood as advisory** (reported but not blocking). Rejected: an advisory dogfood is a regression-monitoring nice-to-have. Making it a blocker is what gives it teeth and prevents the v0.1.0 tag from drifting away from the plugin's stated function.
- **Use Sigstore / cosign keyless signing at v0.1.0** to side-step key management. Considered: lower onboarding cost than GPG. Rejected for v0.1.0 only because it would still require workflow integration and contributor education the v0.1.0 timeline cannot absorb. Documented as a strong candidate for the v0.1.x → v0.2 signing decision.

## Consequences

**Positive.**

- Plugin behaviour is reproducible from a tag: the MCP roster, the Actions workflows, and the install scripts are all version-locked. A user installing v0.1.0 today and three months from now gets the same artefact-producing surface.
- The version-skew check is a structured surface for upstream changes — they arrive as issues, not as silent behavioural drift.
- The dogfood gate makes "the plugin works on its stated job" a release-blocker, not an aspiration. v0.1.0 cannot ship with a substrate-iceberg regression silently in place.
- Single-version support keeps maintenance attention focused; v0.1.x stays receptive to security hotfixes without competing with v0.2 development.

**Negative.**

- **No signature** on v0.1.0 commits or release artefacts. Acceptable per the threat model (§16.3) but explicitly noted in the README's `## Privacy and supply chain` posture — users running in high-assurance environments may need to defer adoption until signing lands.
- **Pinning creates a maintenance load.** The nightly version-skew workflow and the Dependabot Actions PRs will produce a steady stream of small bumps. Acceptable: that flow is the plugin's safety mechanism, not a tax on top of one.
- **Dogfood gate adds release-time cost.** Tagging v0.1.0 requires successfully running the design-intent prompt and validating the produced meta-spec. Acceptable and intentional — the cost is the proof.
- **Single-version support means** v0.1.0 users on a slow upgrade cadence may find themselves on an unsupported line as soon as v0.2 ships. Documented in `SUPPORT.md`; users with longer support horizons should wait for v1.0.

## Revisit when

- Contributor headroom permits adding signed commits and signed releases. Outcome: a new ADR superseding the deferred-signing portion of this one, almost certainly using Sigstore/cosign for keyless signing.
- An MCP server's upstream cadence breaks the version-skew check signal-to-noise (e.g. daily releases of patch bumps). Outcome: tighten the check to skip patch-only bumps automatically, or move that server to a longer pin window.
- v0.1.x reaches a maintenance steady state and v1.0 is being scoped. Outcome: a new ADR introducing the multi-version support model, including the back-port matrix.
- The dogfood prompt's acceptance criteria need extension because the plugin gains a new artefact class (e.g. runbooks). Outcome: amend §13.G's acceptance list rather than replacing this ADR.
- The plugin lands a transitive dependency that introduces npm or other package managers (currently forbidden at v0.1.0 per §N2). Outcome: a new ADR explicitly scoping the new supply-chain surface and the additional pinning/signing posture it requires.
