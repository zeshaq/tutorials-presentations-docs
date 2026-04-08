# DR Runbook

## 1. Pre-checks
- Confirm DNS names for DR ingress
- Confirm Vault URL for DR
- Confirm Kubernetes API endpoint for DR
- Confirm DR intermediate certificate and chain files are available
- Confirm DR secrets required for failover are populated

## 2. Namespaces
Apply:
- `dr/00-namespaces.yaml`

## 3. Vault deployment
Review and edit:
- `dr/vault/values-vault-dr.yaml`

Deploy Vault using your preferred method.

## 4. Vault bootstrap
Edit:
- `dr/vault/bootstrap/00-env-dr.sh`

Then run in order:
- `dr/vault/bootstrap/10-enable-audit-dr.sh`
- `dr/vault/bootstrap/20-enable-k8s-auth-dr.sh`
- `dr/vault/bootstrap/30-enable-kv-dr.sh`
- `dr/vault/bootstrap/40-enable-pki-dr.sh`
- `dr/vault/bootstrap/50-write-policies-dr.sh`
- `dr/vault/bootstrap/60-create-k8s-roles-dr.sh`
- `dr/vault/bootstrap/70-configure-pki-roles-dr.sh`

## 5. Platform controllers
Install:
- cert-manager
- ESO
- Istio

Then apply:
- `dr/cert-manager/clusterissuer-vault-pki-ingress-dr.yaml`
- `dr/istio/certificate-istio-ingressgateway-tls-dr.yaml`
- `dr/external-secrets/clustersecretstore-vault-kv-dr-platform.yaml`
- `dr/external-secrets/app-payments/secretstore-vault-kv-dr-payments.yaml`
- `dr/external-secrets/app-payments/externalsecret-payments-app-secret.yaml`

## 6. Validation
- Check Vault health and seal status
- Check cert-manager issuer readiness
- Check Certificate readiness
- Check TLS secret created in `istio-system`
- Check ExternalSecret sync status
- Check application secret created in target namespace
- Validate DR gateway TLS handshake
- Validate application startup using DR-local secrets

## 7. Failover readiness
- Confirm DR certificates issue without DC dependency
- Confirm DR business secrets are current
- Confirm DNS/GSLB failover procedure has been tested
