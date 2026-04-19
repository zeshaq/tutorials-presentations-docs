# 1. Architecture And Trust Model

This article explains the full trust model before we go into individual flows.

## The big picture

In this setup, OpenShift hosts the platform, **OpenShift Service Mesh 3** provides the service mesh, **Gateway API** is the preferred model for ingress and egress gateways, Vault provides centralized PKI and secret storage, cert-manager automates certificate requests, and External Secrets Operator syncs application secrets from Vault KV into Kubernetes.

The most important design decision is this:

- **Istio CA is responsible for internal mesh identity**
- **Vault PKI is responsible for selected platform-managed certificates, especially Gateway API ingress certificates**
- **Vault KV is responsible for non-certificate application secrets**
- **Gateway API ingress and egress gateways are the default north-south control points in OSSM 3**

For a standalone summary of Istio’s platform role, see [Appendix 1: Istio Overview](/Users/ze/Documents/tutorials-presentations-docs/mtls/appendix-1-istio-overview.md).

## Logical architecture

```mermaid
flowchart LR
    ROOT["Offline Root CA"] --> INT["Vault Intermediate CA"]

    subgraph OCP["OpenShift Cluster"]
        subgraph ISTIO["OpenShift Service Mesh 3"]
            CP["Istiod / Istio CA"]
            IGW["Gateway API ingress gateway"]
            EGW["Gateway API egress gateway"]
            A["Service A + sidecar"]
            B["Service B + sidecar"]
        end

        CM["cert-manager"]
        ESO["External Secrets Operator"]
        K8SSEC["Kubernetes Secrets"]
    end

    subgraph VAULT["Vault"]
        PKI["PKI Engine"]
        KV["KV Engine"]
        AUTH["Kubernetes Auth"]
        POL["Policies / Roles"]
    end

    INT --> PKI
    CM -->|"CSR / issue / renew"| PKI
    PKI -->|"signed certs"| CM
    CM -->|"write tls secret"| K8SSEC
    K8SSEC --> IGW

    ESO -->|"read allowed paths"| KV
    KV -->|"secret values"| ESO
    ESO -->|"sync secrets"| K8SSEC
    K8SSEC --> A
    K8SSEC --> B

    CP -->|"workload identities"| A
    CP -->|"workload identities"| B
    A -->|"mTLS"| B
    A -->|"controlled outbound traffic"| EGW
    B -->|"controlled outbound traffic"| EGW
```

## Trust boundaries

### 1. Offline root CA

The root CA is kept offline and should not be used to sign normal application certificates directly. Its role is to sign one or more intermediate CAs used by Vault.

### 2. Vault security boundary

Vault holds:

- intermediate CA private keys
- PKI roles and issuance policy
- KV secrets
- Kubernetes auth roles
- audit trail for sensitive operations

This is the platform trust anchor for issued certificates and stored secrets.

### 3. OpenShift platform boundary

OpenShift runs:

- workloads
- service mesh data plane
- cert-manager
- ESO
- Istio control plane
- Gateway API ingress gateway namespace
- Gateway API egress gateway namespace

OpenShift stores resulting TLS material and synced app secrets as Kubernetes Secrets, but it does not become the original authority for those values.

### 4. Mesh identity boundary

Inside Istio, each workload gets a short-lived identity certificate for service-to-service authentication. That identity is tied to the workload service account and workload namespace.

## Why people get confused

Teams often ask, "If Vault already issues certificates, why does Istio need its own CA?"

The answer is that the two systems solve different operational problems:

- Istio needs fast, automatic, short-lived workload identities for every meshed workload
- Vault provides centralized PKI governance and certificate issuance for selected use cases
- Using Vault for every internal sidecar-issued workload certificate usually adds complexity without improving the mesh operating model

## A clean responsibility matrix

| Function | Primary component | Why |
|---|---|---|
| Internal pod-to-pod mTLS | Istio CA | Native mesh identity and rotation |
| Gateway API ingress certificate | Vault PKI via cert-manager | Controlled PKI policy and automated renewal |
| App passwords, API keys, tokens | Vault KV via ESO | Central secret storage and sync |
| Controlled outbound internet or partner access | Egress gateway | Auditable and policy-controlled mesh exit |
| Trust anchor governance | Offline Root CA | Controlled signing of intermediates |

## End-to-end trust story

```mermaid
sequenceDiagram
    participant Root as Offline Root CA
    participant Vault as Vault PKI
    participant CM as cert-manager
    participant IGW as Gateway API ingress gateway
    participant EGW as Egress gateway
    participant Istiod as Istio CA
    participant A as Service A
    participant B as Service B

    Root->>Vault: Sign intermediate CA
    Vault-->>CM: Accept authenticated certificate requests
    CM->>Vault: Request gateway cert
    Vault-->>CM: Return signed gateway cert
    CM->>IGW: Store cert in Kubernetes Secret

    Istiod->>A: Issue workload cert
    Istiod->>B: Issue workload cert
    A->>B: Establish service-to-service mTLS
    B->>EGW: Exit mesh through controlled egress path
```

## What to emphasize in the session

Say this clearly and repeatedly:

- The gateway certificate and the workload certificate are not the same certificate
- The client-facing TLS path and the service-to-service mTLS path are different security flows
- In OSSM 3, Gateway API is the preferred ingress and egress model for this design
- Vault, cert-manager, and Istio are cooperating, not duplicating each other
