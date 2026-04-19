# Gateway Patterns

This folder contains a set of architecture articles for designing clean north-south and east-west traffic patterns with:

- F5 load balancers
- WSO2 API Gateway
- OpenShift
- OpenShift Service Mesh 3
- Gateway API ingress and egress
- Vault PKI and KV
- microservices

The goal is to explain not just one recommendation, but the main options, the tradeoffs, and where each component should sit.

## Suggested reading order

1. [01-core-concepts.md](/Users/ze/Documents/tutorials-presentations-docs/gateway patterns/01-core-concepts.md)
2. [02-pattern-catalog.md](/Users/ze/Documents/tutorials-presentations-docs/gateway patterns/02-pattern-catalog.md)
3. [03-recommended-pattern-f5-wso2-istio.md](/Users/ze/Documents/tutorials-presentations-docs/gateway patterns/03-recommended-pattern-f5-wso2-istio.md)
4. [04-tls-termination-and-trust-models.md](/Users/ze/Documents/tutorials-presentations-docs/gateway patterns/04-tls-termination-and-trust-models.md)
5. [05-openshift-routes-gateway-api-and-ingress.md](/Users/ze/Documents/tutorials-presentations-docs/gateway patterns/05-openshift-routes-gateway-api-and-ingress.md)
6. [06-ambient-mode-patterns.md](/Users/ze/Documents/tutorials-presentations-docs/gateway patterns/06-ambient-mode-patterns.md)
7. [07-anti-patterns-and-decision-guide.md](/Users/ze/Documents/tutorials-presentations-docs/gateway patterns/07-anti-patterns-and-decision-guide.md)
8. [08-ossm3-gateway-api-and-egress-reference.md](/Users/ze/Documents/tutorials-presentations-docs/gateway patterns/08-ossm3-gateway-api-and-egress-reference.md)

## One-line recommendation

For most enterprise setups like yours, the cleanest default is:

```text
Inbound:  Client -> F5 -> WSO2 API Gateway -> OSSM 3 Gateway API ingress -> meshed services
Outbound: meshed services -> OSSM 3 egress gateway -> external systems
```

But the right final design depends on:

- where TLS terminates
- where API security and throttling live
- whether outbound traffic must be centrally controlled
- whether OpenShift Routes are only secondary platform plumbing
- whether you use classic sidecar mode or ambient mode
