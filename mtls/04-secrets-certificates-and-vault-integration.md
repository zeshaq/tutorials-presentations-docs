# 4. Secrets, Certificates, And Vault Integration

This article clarifies how Vault is used for both PKI and non-PKI secrets without mixing the two concepts.

## Two different Vault use cases

Vault usually plays two distinct roles in this design:

1. `Vault PKI`
   - issues certificates
   - enforces subject and lifetime policy
   - supports certificate-based trust

2. `Vault KV`
   - stores application secrets
   - passwords, tokens, API keys, connection strings
   - supports secret distribution

These are different engines, different policies, and often different consumers.

## Flow overview

```mermaid
flowchart LR
    subgraph VAULT["Vault"]
        PKI["PKI Engine"]
        KV["KV Engine"]
    end

    CM["cert-manager"] --> PKI
    ESO["External Secrets Operator"] --> KV

    PKI --> TLS["TLS certificates"]
    KV --> APPSEC["Application secrets"]

    TLS --> GW["Ingress Gateway"]
    APPSEC --> APP["Microservices"]
```

## cert-manager path for certificates

cert-manager is the right choice when:

- the target is a Kubernetes TLS secret
- the secret should be renewed automatically
- the consumer is an ingress gateway or other K8s-native TLS consumer

## ESO path for secrets

ESO is the right choice when:

- the data is not a certificate issuance workflow
- the source is KV, not PKI
- the application expects a Kubernetes Secret

## End-to-end app secret flow

```mermaid
sequenceDiagram
    participant AppTeam as Application team
    participant Vault as Vault KV
    participant ESO as External Secrets Operator
    participant K8s as Kubernetes Secret
    participant App as Microservice

    AppTeam->>Vault: Write secret to allowed KV path
    ESO->>Vault: Authenticate with Kubernetes auth
    Vault-->>ESO: Return allowed secret values
    ESO->>K8s: Sync Kubernetes Secret
    App->>K8s: Read mounted secret or env var
```

## End-to-end certificate flow

```mermaid
sequenceDiagram
    participant CM as cert-manager
    participant Vault as Vault PKI
    participant K8s as Kubernetes TLS Secret
    participant GW as Gateway

    CM->>Vault: Request certificate under PKI role
    Vault->>Vault: Enforce TTL, CN, SAN, and policy
    Vault-->>CM: Return certificate chain
    CM->>K8s: Write TLS Secret
    GW->>K8s: Consume certificate for TLS
```

## Why not let all apps talk directly to Vault

Some applications do benefit from direct Vault integration, but many teams prefer ESO for common use cases because:

- application code stays simpler
- no Vault client library is required
- Kubernetes-native secret consumption still works
- namespace and role boundaries stay clear

A balanced rule is:

- use `ESO + KV` for standard application secrets
- use `cert-manager + PKI` for certificate automation
- use direct app-to-Vault integration only when dynamic secrets or advanced lease behavior is genuinely needed

## How authentication works

Both cert-manager and ESO authenticate to Vault using Kubernetes identities.

That usually means:

- a service account in OpenShift
- a Vault Kubernetes auth role
- a Vault policy restricting what that service account may read or issue

## The policy picture

```mermaid
flowchart TB
    SA1["Service Account: cert-manager"] --> AUTH["Vault Kubernetes Auth"]
    SA2["Service Account: eso"] --> AUTH

    AUTH --> ROLE1["Role: cert-manager-pki"]
    AUTH --> ROLE2["Role: eso-kv-readonly"]

    ROLE1 --> POL1["Policy: issue only approved certs"]
    ROLE2 --> POL2["Policy: read only approved KV paths"]
```

## What your audience should leave with

They should understand that:

- not every secret is a certificate
- not every certificate should be treated like a generic secret
- Vault can serve both domains cleanly if the policies and consumers are separated

## Teaching line for this article

Vault is both a **certificate authority platform** and a **secret storage platform**, but the PKI and KV paths should remain operationally and conceptually separate.
