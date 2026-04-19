# 1. Target Architecture

This article describes the exact target architecture for your platform.

## End-to-end topology

```mermaid
flowchart TB
    INTERNET["Internet app / consumer"] --> RTR["Router / firewall"]
    RTR --> F5["F5 load balancer / WAF"]
    F5 --> WSO2["WSO2 API Gateway"]
    WSO2 --> IGW["OSSM 3 Gateway API ingress gateway"]
    IGW --> APP1["Meshed service A"]
    IGW --> APP2["Meshed service B"]
    APP1 <--> APP2
    APP1 --> EGW["OSSM 3 egress gateway"]
    APP2 --> EGW
    EGW --> EXT["External APIs / partner endpoints / SaaS"]
```

## Component responsibilities

| Component | Responsibility |
|---|---|
| Router / firewall | perimeter network filtering and path to enterprise edge |
| F5 | public VIPs, WAF, public TLS, edge protections |
| WSO2 | API governance, OAuth, throttling, subscriptions, API security |
| OSSM 3 Gateway API ingress | north-south entry into the cluster |
| OSSM 3 service mesh | service identity, mTLS, mesh routing, telemetry |
| OSSM 3 egress gateway | controlled outbound exit from the mesh |
| Vault PKI | internal TLS certificate issuance |
| Vault KV | application secrets |
| cert-manager | automated certificate request and renewal |
| ESO | Vault KV synchronization into Kubernetes Secrets |

## Why this is the clean pattern

This pattern works well because every layer has a clear role:

- internet-facing trust is separate from internal platform trust
- API policy is separate from mesh policy
- ingress and egress are explicit
- platform TLS and mesh mTLS are separate concerns

## Reference architecture with PKI and secrets

```mermaid
flowchart LR
    DIGI["DigiCert"] --> F5["F5 public certificate"]
    VAULTPKI["Vault PKI intermediate"] --> WSO2CERT["WSO2 internal certificate"]
    VAULTPKI --> IGWCERT["Gateway API ingress certificate"]
    VAULTPKI --> EGWCERT["Optional egress client certificate"]

    CM["cert-manager"] --> VAULTPKI
    VAULTPKI --> CM
    CM --> IGW["Gateway API ingress"]

    ESO["ESO"] --> VAULTKV["Vault KV"]
    VAULTKV --> ESO
    ESO --> APPS["Meshed services"]

    ISTIOD["Istio CA"] --> APPS
```

## Inbound and outbound view together

```mermaid
flowchart LR
    IN["Inbound traffic"] --> F5["F5"]
    F5 --> WSO2["WSO2"]
    WSO2 --> IGW["Gateway API ingress"]
    IGW --> MESH["Meshed services"]
    MESH --> EGW["Egress gateway"]
    EGW --> OUT["Outbound traffic"]
```
