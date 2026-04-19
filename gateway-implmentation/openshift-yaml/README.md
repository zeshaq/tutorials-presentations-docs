# OpenShift YAML Pack

This folder contains a template manifest pack for implementing the target architecture on OpenShift:

- OpenShift Service Mesh 3
- ambient mode
- Gateway API ingress
- controlled egress
- Vault PKI
- Vault KV
- cert-manager
- External Secrets Operator

These files are **environment templates**. You must replace placeholder values such as:

- `REPLACE_ME_CLUSTER_DOMAIN`
- `REPLACE_ME_PUBLIC_HOSTNAME`
- `REPLACE_ME_VAULT_ADDR`
- `REPLACE_ME_BASE64_CA_BUNDLE`
- `REPLACE_ME_PARTNER_HOST`

## Apply order

1. `00-namespaces.yaml`
2. `01-istio-control-plane.yaml`
3. `02-istio-cni.yaml`
4. `03-ztunnel.yaml`
5. `04-platform-pki-and-secrets.yaml`
6. `05-gateway-api-ingress.yaml`
7. `06-gateway-api-routes.yaml`
8. `07-egress-gateway-and-external-service.yaml`
9. `08-sample-app.yaml`
10. `09-sample-app-secrets.yaml`
11. `10-wso2-internal-certificate.yaml` if WSO2 runs in-cluster
12. `11-implementation-guide.md` for rollout instructions, validation, and pitfalls

## Important notes

- These manifests assume the OpenShift Service Mesh 3 Operator, cert-manager Operator, and External Secrets Operator are already installed.
- These manifests standardize on `Gateway API` for ingress.
- The included egress manifests provide a **starting point** for controlled outbound traffic. External destinations and protocol-specific egress policy must be adapted for each real integration.
- WSO2 upstream and F5 configuration are not fully controlled by Kubernetes YAML if those components are external to the cluster.

## Operator guide

Use this guide while implementing:

- [11-implementation-guide.md](/Users/ze/Documents/tutorials-presentations-docs/gateway-implmentation/openshift-yaml/11-implementation-guide.md)
