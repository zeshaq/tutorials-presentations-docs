# 5. Certificate Lifecycle, Rotation, And Failure Flows

This article explains what happens after initial setup: issuance, renewal, rotation, expiry, and failure.

## Lifecycle layers

There are three certificate lifecycles worth discussing:

1. Offline root lifecycle
2. Vault intermediate and gateway certificate lifecycle
3. Istio workload certificate lifecycle

Each one rotates differently.

## Gateway certificate lifecycle

```mermaid
flowchart LR
    A["Create Certificate resource"] --> B["cert-manager requests cert from Vault"]
    B --> C["Vault signs cert under role policy"]
    C --> D["cert-manager writes TLS Secret"]
    D --> E["Ingress Gateway serves certificate"]
    E --> F["Renewal window reached"]
    F --> B
```

## Mesh workload certificate lifecycle

```mermaid
flowchart LR
    W1["Workload starts"] --> W2["Sidecar gets short-lived identity cert"]
    W2 --> W3["Service-to-service mTLS"]
    W3 --> W4["Approaching expiry"]
    W4 --> W5["Sidecar rotates cert through Istiod"]
    W5 --> W3
```

## Why short-lived certificates matter

Short-lived certificates reduce blast radius:

- less useful if stolen
- less operational pressure around revocation
- continuous renewal exercises the path regularly

This principle fits especially well with mesh-issued workload identities.

## Full rotation story

```mermaid
sequenceDiagram
    participant Root as Offline Root CA
    participant Vault as Vault Intermediate CA
    participant CM as cert-manager
    participant GW as Ingress Gateway
    participant Istiod as Istio CA
    participant Sidecar as Workload sidecar

    Root->>Vault: Sign or rotate intermediate CA
    CM->>Vault: Request renewed gateway cert
    Vault-->>CM: Return renewed cert
    CM->>GW: Update TLS secret
    Istiod->>Sidecar: Rotate short-lived workload cert
```

## Failure scenario 1: gateway certificate expires

What users see:

- browser warnings
- API clients reject the endpoint
- external traffic fails even if the backend service is healthy

What likely went wrong:

- cert-manager could not renew
- Vault PKI role or auth broke
- Certificate resource was misconfigured

## Failure scenario 2: workload certificate rotation fails

What users see:

- internal calls fail
- 503s or upstream TLS errors in the mesh
- some pods work while others fail after rotation thresholds

What likely went wrong:

- sidecar cannot contact Istiod
- mesh trust bundle changed incorrectly
- identity issuance or SDS delivery failed

## Failure scenario 3: wrong trust chain at the edge

What users see:

- clients reject the gateway certificate
- TLS handshake errors on the public endpoint

What likely went wrong:

- incomplete chain in secret
- wrong issuer configured
- a certificate for the wrong hostname was mounted

## Failure scenario 4: secret delivery works but auth policy fails

This is an important teaching case.

The flow can look healthy:

- gateway certificate is valid
- mesh mTLS is enabled
- app secrets are present

But traffic still fails because authorization and identity policy are separate from basic certificate presence.

## A practical troubleshooting tree

```mermaid
flowchart TB
    START["Traffic failed"] --> Q1{"External or internal?"}

    Q1 -->|External| E1["Check gateway TLS cert, hostname, chain, expiry"]
    Q1 -->|Internal| I1["Check sidecars, PeerAuthentication, DestinationRule, AuthorizationPolicy"]

    E1 --> E2{"Secret present and fresh?"}
    E2 -->|No| E3["Check cert-manager and Vault auth"]
    E2 -->|Yes| E4["Check gateway config and hostname matching"]

    I1 --> I2{"mTLS handshake failed?"}
    I2 -->|Yes| I3["Check Istiod, cert rotation, trust bundle"]
    I2 -->|No| I4["Check authorization policy and routing"]
```

## Operational recommendations

1. Keep gateway certificates and mesh certificates as separate operational concerns.
2. Monitor certificate expiry for both gateway and intermediate CAs.
3. Test renewal before you need it.
4. Run failure drills for Vault outage, cert-manager auth failure, and mesh CA issues.
5. Document the expected trust chain for every externally exposed hostname.

## Teaching line for this article

Secure setups do not stay secure only because certificates exist; they stay secure because **issuance, renewal, trust chain management, and failure handling all keep working over time**.
