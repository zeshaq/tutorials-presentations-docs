# Gateway Implmentation

This folder contains the implementation-focused architecture for this exact target design:

- internet applications as clients
- edge router and firewall
- F5 load balancer
- WSO2 API Gateway
- OpenShift
- Red Hat OpenShift Service Mesh 3
- Gateway API for ingress and egress
- Vault for PKI and KV
- cert-manager for certificate automation
- External Secrets Operator for Vault KV sync

## Reading order

1. [01-target-architecture.md](/Users/ze/Documents/tutorials-presentations-docs/gateway-implmentation/01-target-architecture.md)
2. [02-certificate-flows.md](/Users/ze/Documents/tutorials-presentations-docs/gateway-implmentation/02-certificate-flows.md)
3. [03-implementation-principles.md](/Users/ze/Documents/tutorials-presentations-docs/gateway-implmentation/03-implementation-principles.md)

## Target traffic model

```text
Inbound:  Internet app -> router -> F5 -> WSO2 -> OSSM 3 Gateway API ingress -> meshed services
Outbound: meshed services -> OSSM 3 egress gateway -> external systems
```

## Certificate model

- `DigiCert` for public-facing internet endpoints
- `Vault PKI` for internal platform TLS endpoints
- `Istio CA` for service-to-service mesh mTLS
- `Vault KV` for non-certificate application secrets
