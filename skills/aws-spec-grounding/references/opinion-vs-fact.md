# Opinion vs fact

Loaded on demand by the `aws-spec-grounding` skill. Defines the boundary between _factual claims_ (which need citations) and _design opinions_ (which need rationales). The boundary is not always obvious; this file is the authoritative tiebreaker.

## The rule

- **Factual claim**: a statement about AWS or about the world that is true or false independent of the author's preferences. The reader can in principle verify it by consulting an AWS source. Citation required.
- **Design opinion**: a statement about how the proposed system _should_ be built. Reasonable engineers can disagree. Rationale required.

A useful test: if two competent AWS engineers read the same docs, would they agree on the truth? If yes, it is a fact. If they could rationally choose differently, it is an opinion.

## Examples

### Clearly factual (need citation)

| Claim                                                                            | Why factual                             |
| -------------------------------------------------------------------------------- | --------------------------------------- |
| "AWS Lambda has a default unreserved-concurrency limit of 1000 per region."      | Documented quota; verifiable.           |
| "S3 Standard storage in eu-west-1 costs $0.023 per GB per month."                | Pricing API; verifiable (within TTL).   |
| "Aurora Serverless v2 is available in eu-west-1."                                | Region availability matrix; verifiable. |
| "An IAM role ARN has the format `arn:aws:iam::<account>:role/<name>`."           | ARN format reference; verifiable.       |
| "DynamoDB on-demand mode bills per request and has no provisioned-capacity tax." | Service-pricing-model fact; verifiable. |

### Clearly opinion (need rationale)

| Claim                                                                                 | Why opinion                                                                    |
| ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| "We will use Aurora Serverless v2 for the payments database."                         | Architectural choice; alternatives exist (RDS, DynamoDB, provisioned cluster). |
| "Synchronous request-response is preferable to async event-driven for this workflow." | Design philosophy; reasonable engineers may choose differently.                |
| "The eu-west-1 region is the right home for this workload."                           | Regional placement; depends on data-residency, latency, cost trade-offs.       |
| "We will fan out via SNS rather than EventBridge."                                    | Eventing service choice; both work.                                            |
| "Lambda is preferable to Fargate for this microservice."                              | Compute model; reasonable engineers may choose differently.                    |

### Edge cases — and how to resolve them

#### "AWS recommends X."

This is _factual_ if you can cite AWS saying it, but the recommendation itself is an _opinion_ by AWS. So:

- "AWS documentation recommends provisioned concurrency for predictable bursts (kb:lambda-pc-guidance)" — fact (you cited the doc). Adopting that recommendation in the spec then becomes an opinion that needs a rationale: "We accept this recommendation because our payments load is predictable diurnally and we value cold-start elimination over per-second cost."

#### "X is best practice."

Treat as opinion. "Best practice" without a named source or named principle is not a fact and not a rationale. Either cite where the practice is documented (turning it into a citation) or name the principle (turning it into a rationale).

#### Quantitative claims inside design choices

A design statement that contains a quantitative claim should be split:

- Factual portion: the number, with a citation.
- Opinion portion: the design choice, with a rationale.

Example:

```text
We provision 100 RCUs per second of peak load (kb:dynamodb-rcu-pricing).
Rationale: Cost Optimisation pillar — peak load was measured at 80 reads/sec
in the discovery report; 100 RCUs gives 25% headroom with a documented refusal
to over-provision more than that.
```

Here `100 RCUs` is a derived fact backed by pricing; the _choice_ of 25% headroom is the opinion the rationale defends.

#### Claims that are obvious or universally known

There is no such thing in an AWS spec. The whole point of grounding is that pretrained AWS knowledge is stale. If the claim is obvious, the citation is also obvious — write it down.

#### Negative claims ("X does not support Y")

These are factual and need citations _more_, not less. Negative claims are easier to get wrong because the author may be relying on stale memory of an old limitation. Cite or omit.

## Resolution algorithm

When a sentence does not clearly fall into one category, apply this in order:

1. Could a competent engineer reading the same AWS docs reach a different conclusion about the _truth_ of the statement? If no → factual.
2. Could a competent engineer make a different _choice_ in the same situation? If yes → opinion.
3. Does the sentence mix both? If yes → split into two sentences and treat each independently.
4. Still unclear? Default to opinion. Requiring a rationale on a fact is mildly annoying. Letting an opinion through with no rationale is a real defect.
