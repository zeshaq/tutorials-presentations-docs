# Implementation Blueprint  
**Vault OSS + cert-manager + ESO + two independent Istio meshes for DC/DR**

(This file is ready for GitHub. All sections preserved in Markdown.)

---

## 1. Target namespace layout

### Platform namespaces

| Namespace | Purpose |
|---|---|
| `vault-system` | Vault cluster |
| `cert-manager` | cert-manager controller |
| `external-secrets` | External Secrets Operator |
| `istio-system` | Istio control plane and ingress gateway |
| `platform-secrets` | optional shared platform secrets |
| `app-<name>` | application namespaces |

---

## 2. Vault mount layout per site

### DC

| Mount | Type | Purpose |
|---|---|---|
| `auth/kubernetes-dc` | auth | Kubernetes auth |
| `kv-dc` | KV v2 | Secrets |
| `pki-ingress-dc` | PKI | Gateway certs |

### DR

| Mount | Type | Purpose |
|---|---|---|
| `auth/kubernetes-dr` | auth | Kubernetes auth |
| `kv-dr` | KV v2 | Secrets |
| `pki-ingress-dr` | PKI | Gateway certs |

---

## 3. Vault auth roles

### DC
- eso-kv-readonly-dc
- cert-manager-pki-issuer-dc

### DR
- eso-kv-readonly-dr
- cert-manager-pki-issuer-dr

---

## 4. Vault policy examples

### ESO DC
```hcl
path "kv-dc/data/*" {
  capabilities = ["read"]
}
```

### cert-manager DC
```hcl
path "pki-ingress-dc/sign/role-istio-gateway-dc" {
  capabilities = ["update"]
}
```

---

## 5. PKI role layout

| Role | Site | Purpose |
|---|---|---|
| role-istio-gateway-dc | DC | Gateway TLS |
| role-istio-gateway-dr | DR | Gateway TLS |

---

## 6. cert-manager

### DC
- ClusterIssuer: vault-pki-ingress-dc

### DR
- ClusterIssuer: vault-pki-ingress-dr

---

## 7. ESO layout

### DC
- SecretStore per namespace
- KV path: kv-dc/data/apps/<app>

### DR
- SecretStore per namespace
- KV path: kv-dr/data/apps/<app>

---

## 8. Deployment sequence

### Phase 1 - Root CA
- Generate offline root CA
- Sign DC and DR intermediates

### Phase 2 - Vault DC
- Deploy Vault
- Enable KV + PKI
- Configure roles + policies

### Phase 3 - Platform DC
- Install cert-manager
- Install ESO
- Install Istio

### Phase 4 - Integrations DC
- Configure ClusterIssuer
- Configure SecretStore
- Deploy apps

### Phase 5 - Repeat DR
- Same steps with DR config

---

## 9. Failover model

- DR is fully independent
- No dependency on DC Vault
- DNS failover controlled

---

## 10. Key rules

1. ESO = KV only  
2. cert-manager = PKI only  
3. Istio CA = mesh only  
4. No cross-site dependency  
5. Separate intermediate per site  

---

## 11. Summary

This architecture ensures:

- Strong isolation between DC and DR  
- Proper PKI separation  
- Automated certificate lifecycle  
- Secure secret distribution  
- Production-grade compliance readiness  

