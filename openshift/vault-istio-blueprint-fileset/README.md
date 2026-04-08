# Vault OSS + cert-manager + ESO + Istio DC/DR Blueprint

This is a **ready-to-edit template file set** for:

- DC site
- DR site
- Vault OSS
- cert-manager
- External Secrets Operator
- Istio ingress gateway TLS
- Independent meshes in each site

## Important
These files are **templates**, not fully environment-specific manifests. You must edit at least:

- domain names
- Vault URLs
- Kubernetes API endpoints
- service account names if different
- PKI subject/SAN policy
- storage classes
- resource sizing
- image versions
- namespaces if your standards differ

## Structure

- `docs/` runbooks and deployment order
- `common/` shared examples
- `dc/` DC-specific templates
- `dr/` DR-specific templates

## Suggested deployment order

1. Prepare offline root and sign intermediates
2. Deploy Vault in DC
3. Bootstrap DC Vault
4. Install cert-manager, ESO, Istio in DC
5. Apply DC ClusterIssuer and Certificate
6. Apply DC SecretStore and ExternalSecret
7. Repeat for DR
8. Run validation and failover drills

## Notes
- ESO is used for **KV only**
- cert-manager is used for **PKI only**
- Istio CA is used for **mesh mTLS only**
- DC and DR are **independent**
