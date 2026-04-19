# 2. Implementation Diagram

This page gives a single implementation diagram for the target architecture using:

- OpenShift
- OpenShift Service Mesh 3 ambient mode
- Gateway API ingress
- egress gateway
- F5
- WSO2
- Vault PKI and KV
- DigiCert for public trust

## End-to-end implementation diagram

```mermaid
flowchart TB
    INTERNET["Internet application / external consumer"] --> RTR["Router / firewall"]
    RTR --> F5["F5 load balancer / WAF"]
    F5 --> WSO2["WSO2 API Gateway"]
    WSO2 --> GWIN["OSSM 3 Gateway API ingress gateway"]

    subgraph OCP["OpenShift cluster"]
        subgraph MESH["OSSM 3 ambient mesh"]
            ZT1["ztunnel node A"]
            ZT2["ztunnel node B"]
            WP["Waypoint proxy where L7 policy is needed"]
            APP1["Service A"]
            APP2["Service B"]
            EGW["OSSM 3 egress gateway"]
        end

        CM["cert-manager"]
        ESO["External Secrets Operator"]
    end

    subgraph VAULT["Vault"]
        PKI["Vault PKI intermediate"]
        KV["Vault KV"]
    end

    DIGI["DigiCert"] --> F5
    PKI --> WSO2
    CM --> PKI
    PKI --> CM
    CM --> GWIN

    ESO --> KV
    KV --> ESO
    ESO --> APP1
    ESO --> APP2

    GWIN --> ZT1
    ZT1 --> ZT2
    ZT2 --> WP
    WP --> APP1
    WP --> APP2
    APP1 <--> APP2
    APP1 --> EGW
    APP2 --> EGW
    EGW --> EXT["External APIs / partner systems / SaaS"]
```

## Trust and traffic overlays

```mermaid
flowchart LR
    C1["Public TLS"] --> F5["F5 with DigiCert certificate"]
    C2["Internal platform TLS"] --> P1["WSO2 and Gateway API ingress with Vault-issued certs"]
    C3["Ambient mesh mTLS"] --> M1["ztunnel to ztunnel and waypoint-assisted mesh traffic"]
    C4["Application secrets"] --> S1["Vault KV -> ESO -> Kubernetes Secrets"]
```

## Inbound path

```mermaid
sequenceDiagram
    participant Client as Internet app
    participant Router as Router/firewall
    participant F5 as F5
    participant WSO2 as WSO2
    participant Ingress as Gateway API ingress
    participant Ztunnel as Ambient ztunnel
    participant Service as Service

    Client->>Router: Internet request
    Router->>F5: Forward to enterprise edge
    F5->>WSO2: Forward approved request
    WSO2->>Ingress: Forward API traffic
    Ingress->>Ztunnel: Enter ambient mesh
    Ztunnel->>Service: Deliver to workload
```

## Outbound path

```mermaid
sequenceDiagram
    participant Service as Meshed service
    participant Ztunnel as Ambient mesh
    participant Egress as Egress gateway
    participant External as External system

    Service->>Ztunnel: Outbound request inside ambient mesh
    Ztunnel->>Egress: Route through controlled egress path
    Egress->>External: TLS or mTLS to external endpoint
```

## Certificate ownership summary

| Segment | Certificate source |
|---|---|
| Internet client to F5 | DigiCert |
| F5 to WSO2 | Vault PKI or enterprise internal PKI |
| WSO2 to Gateway API ingress | Vault PKI |
| Ambient mesh service-to-service | Istio CA |
| Egress client certificate when needed | Vault PKI |

## Design note

This implementation keeps the responsibilities clean:

- `F5` owns edge exposure
- `WSO2` owns API governance
- `Gateway API ingress` owns cluster entry
- `ambient mesh` owns service-to-service trust
- `egress gateway` owns controlled outbound access
- `Vault` owns internal PKI and secret storage
