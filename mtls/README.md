# mTLS Session Pack

This folder contains a complete teaching pack for explaining how mTLS, OpenShift, Istio, microservices, cert-manager, Vault, and certificates work together in one production-style setup.

The explanations are aligned to the architecture already present in this repository:

- OpenShift or Kubernetes runs the platform
- Istio runs the service mesh
- Istio CA handles east-west workload mTLS inside the mesh
- Vault is the system of record for PKI and secrets
- cert-manager requests and renews selected certificates from Vault
- External Secrets Operator syncs non-certificate secrets from Vault KV into Kubernetes

## Suggested reading order

1. [01-architecture-and-trust-model.md](/Users/ze/Documents/tutorials-presentations-docs/mtls/01-architecture-and-trust-model.md)
2. [02-istio-mtls-service-to-service-flow.md](/Users/ze/Documents/tutorials-presentations-docs/mtls/02-istio-mtls-service-to-service-flow.md)
3. [03-ingress-tls-vault-cert-manager-flow.md](/Users/ze/Documents/tutorials-presentations-docs/mtls/03-ingress-tls-vault-cert-manager-flow.md)
4. [04-secrets-certificates-and-vault-integration.md](/Users/ze/Documents/tutorials-presentations-docs/mtls/04-secrets-certificates-and-vault-integration.md)
5. [05-certificate-lifecycle-rotation-and-failure-flows.md](/Users/ze/Documents/tutorials-presentations-docs/mtls/05-certificate-lifecycle-rotation-and-failure-flows.md)
6. [06-session-walkthrough-and-speaking-notes.md](/Users/ze/Documents/tutorials-presentations-docs/mtls/06-session-walkthrough-and-speaking-notes.md)

## One-sentence summary

In this design, **Istio secures service-to-service traffic with mesh-issued workload certificates**, while **Vault plus cert-manager secures externally exposed gateway/server certificates**, and **Vault KV plus External Secrets Operator delivers application secrets**.

## The key distinction to repeat during the session

Do not merge these into one mental model:

- `Istio mTLS` protects pod-to-pod traffic inside the mesh
- `Ingress TLS` protects client-to-gateway traffic
- `Vault PKI` is used for managed certificate issuance where platform policy requires it
- `Vault KV` stores passwords, API keys, and similar application secrets
- `cert-manager` automates certificate issuance and renewal
- `ESO` automates secret synchronization from KV
