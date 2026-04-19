# 8. OSSM 3 Gateway API And Egress Reference

This article is the reference architecture for the exact target model used in the updated docs:

- OpenShift
- Red Hat OpenShift Service Mesh 3
- Vault as PKI and KV
- cert-manager for certificate automation
- External Secrets Operator for Vault KV sync
- Gateway API for ingress
- egress gateway for outbound traffic

## Reference architecture

```mermaid
flowchart TB
    CLIENT["Client / Partner / Browser"] --> F5["F5"]
    F5 --> WSO2["WSO2 API Gateway"]
    WSO2 --> IGW["OSSM 3 Gateway API ingress gateway"]
    IGW --> APP1["Meshed service A"]
    IGW --> APP2["Meshed service B"]
    APP1 <--> APP2
    APP1 --> EGW["OSSM 3 egress gateway"]
    APP2 --> EGW
    EGW --> EXT["External APIs / SaaS / partner endpoints"]

    CM["cert-manager"] --> VAULTPKI["Vault PKI"]
    VAULTPKI --> CM
    CM --> IGW

    ESO["External Secrets Operator"] --> VAULTKV["Vault KV"]
    VAULTKV --> ESO
    ESO --> APP1
    ESO --> APP2

    ISTIOD["Istiod / mesh CA"] --> APP1
    ISTIOD --> APP2
```

## Core rules

1. Use **Gateway API ingress** as the default north-south entry into the cluster.
2. Use **egress gateway** for outbound traffic that must be governed or audited.
3. Use **Vault PKI** for ingress certificates managed through cert-manager.
4. Use **Vault KV** for application secrets synced through ESO.
5. Keep ingress and egress gateways in namespaces separate from the OSSM control plane namespace.

## Inbound flow

```mermaid
sequenceDiagram
    participant Client as Client
    participant F5 as F5
    participant WSO2 as WSO2
    participant IGW as Gateway API ingress
    participant Svc as Meshed service

    Client->>F5: HTTPS request
    F5->>WSO2: Forward request
    WSO2->>WSO2: Apply API security and policy
    WSO2->>IGW: Forward approved request
    IGW->>Svc: Route request into mesh
```

## Outbound flow

```mermaid
sequenceDiagram
    participant Svc as Meshed service
    participant EGW as Egress gateway
    participant Ext as External endpoint

    Svc->>EGW: Route approved outbound traffic
    EGW->>EGW: Apply egress policy and monitoring
    EGW->>Ext: Connect to external destination
```

## PKI and secret flows

```mermaid
flowchart LR
    VAULTPKI["Vault PKI"] --> CM["cert-manager"]
    CM --> TLS["Gateway TLS Secret"]
    TLS --> IGW["Gateway API ingress"]

    VAULTKV["Vault KV"] --> ESO["ESO"]
    ESO --> SEC["Kubernetes Secrets"]
    SEC --> APP["Applications"]
```

## Why this model is clean

- public edge ownership is clear
- API ownership is clear
- cluster ingress is standardized on Gateway API
- outbound traffic is centralized through egress
- certificate and secret lifecycles are separated cleanly

## Platform notes

The current Red Hat guidance that matters most here is:

- OSSM 3 does not auto-deploy gateways as part of the control plane
- ingress and egress gateways should be deployed separately from the control plane namespace
- Gateway API is fully supported in ambient mode and can also be used for sidecar-based deployments
- egress in ambient mode should use Gateway API instead of Istio `Gateway` and `VirtualService`

## Suggested references

- [Red Hat OpenShift Service Mesh 3.3 gateways](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.3/html-single/gateways/index)
- [Red Hat OpenShift Service Mesh 3.3 installing](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.3/html-single/installing/index)
- [Istio Gateway API docs](https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/)
- [Istio egress gateway docs](https://istio.io/latest/docs/tasks/traffic-management/egress/egress-gateway/)
