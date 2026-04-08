# DC Runbook

## 1. Pre-checks
- Confirm DNS names for DC ingress
- Confirm Vault URL for DC
- Confirm Kubernetes API endpoint for DC
- Confirm intermediate certificate and chain files are available
- Confirm storage class and persistence sizes
- Confirm audit log destination

## 2. Namespaces
Apply:
- `dc/00-namespaces.yaml`

## 3. Vault deployment
Review and edit:
- `dc/vault/values-vault-dc.yaml`

Deploy Vault using your preferred method, for example Helm.

## 4. Vault bootstrap
Edit:
- `dc/vault/bootstrap/00-env-dc.sh`

Then run in order:
- `dc/vault/bootstrap/10-enable-audit-dc.sh`
- `dc/vault/bootstrap/20-enable-k8s-auth-dc.sh`
- `dc/vault/bootstrap/30-enable-kv-dc.sh`
- `dc/vault/bootstrap/40-enable-pki-dc.sh`
- `dc/vault/bootstrap/50-write-policies-dc.sh`
- `dc/vault/bootstrap/60-create-k8s-roles-dc.sh`
- `dc/vault/bootstrap/70-configure-pki-roles-dc.sh`

## 5. Platform controllers
Install:
- cert-manager
- ESO
- Istio

Then apply:
- `dc/cert-manager/clusterissuer-vault-pki-ingress-dc.yaml`
- `dc/istio/certificate-istio-ingressgateway-tls-dc.yaml`
- `dc/external-secrets/clustersecretstore-vault-kv-dc-platform.yaml`
- `dc/external-secrets/app-payments/secretstore-vault-kv-dc-payments.yaml`
- `dc/external-secrets/app-payments/externalsecret-payments-app-secret.yaml`

## 6. Validation
- Check Vault health and seal status
- Check cert-manager issuer readiness
- Check Certificate readiness
- Check TLS secret created in `istio-system`
- Check ExternalSecret sync status
- Check application secret created in target namespace
- Validate gateway TLS handshake
- Validate workload reaches target service

## 7. Operational checks
- Confirm audit logs are being written
- Confirm Raft snapshot procedure works
- Confirm certificate renewal path works
- Confirm ESO refresh works
