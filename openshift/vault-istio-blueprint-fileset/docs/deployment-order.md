# Deployment Order

## DC
1. Apply `dc/00-namespaces.yaml`
2. Deploy Vault using `dc/vault/values-vault-dc.yaml`
3. Run DC bootstrap scripts in numeric order
4. Install cert-manager
5. Install ESO
6. Install Istio
7. Apply `dc/cert-manager/clusterissuer-vault-pki-ingress-dc.yaml`
8. Apply `dc/istio/certificate-istio-ingressgateway-tls-dc.yaml`
9. Apply `dc/istio/gateway-sample-dc.yaml`
10. Apply DC SecretStore and ExternalSecret manifests
11. Validate

## DR
1. Apply `dr/00-namespaces.yaml`
2. Deploy Vault using `dr/vault/values-vault-dr.yaml`
3. Run DR bootstrap scripts in numeric order
4. Install cert-manager
5. Install ESO
6. Install Istio
7. Apply `dr/cert-manager/clusterissuer-vault-pki-ingress-dr.yaml`
8. Apply `dr/istio/certificate-istio-ingressgateway-tls-dr.yaml`
9. Apply `dr/istio/gateway-sample-dr.yaml`
10. Apply DR SecretStore and ExternalSecret manifests
11. Validate
