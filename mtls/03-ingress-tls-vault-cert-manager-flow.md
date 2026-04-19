# 3. Ingress TLS With Vault And cert-manager

This article explains the north-south certificate flow from external client to Istio ingress gateway.

## What problem this solves

When a user, browser, partner system, or external API client connects to your platform, the gateway needs a server certificate that external clients can validate.

That certificate is not the same as the workload certificates used internally by Istio sidecars.

## High-level flow

```mermaid
flowchart LR
    CLIENT["External client"] -->|"HTTPS"| IGW["Istio Ingress Gateway"]
    IGW -->|"HTTP or mesh traffic"| SVC["Backend service"]

    CM["cert-manager"] -->|"request cert"| VAULT["Vault PKI"]
    VAULT -->|"signed cert"| CM
    CM -->|"store tls.crt + tls.key + ca.crt"| SECRET["Kubernetes TLS Secret"]
    SECRET --> IGW
```

## The issuance flow step by step

```mermaid
sequenceDiagram
    participant Admin as Platform config
    participant CM as cert-manager
    participant Vault as Vault PKI
    participant Secret as K8s TLS Secret
    participant IGW as Istio Ingress Gateway
    participant Client as External client

    Admin->>CM: Create Issuer or ClusterIssuer and Certificate
    CM->>Vault: Authenticate using Kubernetes auth
    Vault->>Vault: Apply PKI role and subject policy
    Vault-->>CM: Return signed certificate chain
    CM->>Secret: Write TLS secret
    IGW->>Secret: Mount or read secret
    Client->>IGW: Start TLS handshake
    IGW-->>Client: Present gateway certificate
```

## Why cert-manager exists in the middle

cert-manager automates the certificate lifecycle:

- creates the request
- renews before expiry
- writes the resulting secret
- keeps the secret updated for the gateway

Without cert-manager, teams often renew certificates manually, which becomes slow, error-prone, and inconsistent.

## Why Vault exists in the middle

Vault provides PKI governance:

- allowed subject names
- allowed SANs
- TTL policy
- auditability
- site-specific PKI boundaries

That means platform security can control what kind of certificate may be issued to the gateway.

## Client-to-service path

There are two common variants.

### Variant A: TLS terminates at the gateway

```mermaid
flowchart LR
    C["Client"] -->|"TLS"| G["Ingress Gateway"]
    G -->|"HTTP or HTTP/gRPC"| S1["Service A"]
```

In this mode, the external TLS session ends at the gateway. After that, traffic may enter the mesh and be protected by a separate internal mTLS session.

### Variant B: TLS at the edge, mTLS inside the mesh

```mermaid
flowchart LR
    C["Client"] -->|"TLS with Vault-issued gateway cert"| G["Ingress Gateway"]
    G -->|"Istio mTLS"| E["Destination sidecar"]
    E --> S["Backend service"]
```

This is the model most worth teaching because it shows the two layers clearly:

- edge TLS for the client-facing connection
- mesh mTLS for internal service-to-service trust

## Certificate data model

The gateway secret usually contains:

- `tls.crt`
- `tls.key`
- optionally `ca.crt` or full chain material

Istio reads that material when serving HTTPS at the gateway.

## The key identity difference

The ingress gateway certificate usually represents a DNS name such as:

- `api.example.com`
- `payments.example.com`
- `*.apps.example.com`

The mesh certificate represents a workload identity such as:

- namespace
- service account
- workload principal

These are different trust subjects for different audiences.

## A practical teaching diagram

```mermaid
flowchart TB
    subgraph EXT["External Zone"]
        Client["Browser / API client"]
    end

    subgraph EDGE["Cluster Edge"]
        Gateway["Istio Ingress Gateway"]
        Secret["TLS Secret"]
    end

    subgraph PKI["Certificate Automation"]
        CM["cert-manager"]
        Vault["Vault PKI"]
    end

    subgraph MESH["Internal Mesh"]
        Sidecar["Destination Envoy"]
        App["Microservice"]
    end

    Client -->|"HTTPS"| Gateway
    Secret --> Gateway
    CM --> Vault
    Vault --> CM
    CM --> Secret
    Gateway -->|"mTLS"| Sidecar
    Sidecar --> App
```

## Common mistakes

### Mistake 1

Thinking the gateway certificate also secures all internal service-to-service calls.

It does not. That certificate secures the edge connection.

### Mistake 2

Trying to use one wildcard certificate as the identity for internal workloads.

That weakens the identity model and does not map cleanly to zero-trust service authorization.

### Mistake 3

Letting gateways use long-lived manually renewed certificates.

That creates operational and audit risk.

## Teaching line for this article

Vault plus cert-manager gives you **controlled and automated certificate issuance for the gateway**, while Istio gives you **automatic identity-based mTLS once traffic enters the mesh**.
