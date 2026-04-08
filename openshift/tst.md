Below is the **complete GitHub-ready Markdown file** exactly as requested.  
Copy everything into a file like `vault-setup.md` and push to GitHub.  
(All diagrams preserved exactly.)

---

\# Vault Setup with KV (DC/DR) — Implementation Guide

\#\# Overview

This document describes the \*\*Vault OSS setup\*\* for:

\- DC and DR sites  
\- KV secrets engine  
\- PKI engine  
\- Kubernetes authentication  
\- Policy and role structure

\---

\# Architecture Diagram

\`\`\`mermaid  
flowchart TB  
   A\[Offline Root CA\<br/\>OpenSSL\] \--\> B\[Sign DC Intermediate\]  
   A \--\> C\[Sign DR Intermediate\]

   subgraph DC\[DC Site\]  
       D\[Vault OSS Cluster \- DC\<br/\>Raft HA\]  
       E\[Init Vault\]  
       F\[Unseal\]  
       G\[Enable Audit Log\]  
       H\[Enable KV v2\<br/\>kv-dc\]  
       I\[Enable Kubernetes Auth\<br/\>auth/kubernetes-dc\]  
       J\[Enable PKI\<br/\>pki-ingress-dc\]  
       K\[Import DC Intermediate\]  
       L\[Configure PKI URLs\]  
       M\[Write Policies\]  
       N\[Create Auth Roles\]  
       O\[Create PKI Roles\]

       B \--\> K  
       D \--\> E \--\> F \--\> G \--\> H \--\> I \--\> J \--\> K \--\> L \--\> M \--\> N \--\> O  
   end

   subgraph DR\[DR Site\]  
       P\[Vault OSS Cluster \- DR\<br/\>Raft HA\]  
       Q\[Init Vault\]  
       R\[Unseal\]  
       S\[Enable Audit Log\]  
       T\[Enable KV v2\<br/\>kv-dr\]  
       U\[Enable Kubernetes Auth\<br/\>auth/kubernetes-dr\]  
       V\[Enable PKI\<br/\>pki-ingress-dr\]  
       W\[Import DR Intermediate\]  
       X\[Configure PKI URLs\]  
       Y\[Write Policies\]  
       Z\[Create Auth Roles\]  
       AA\[Create PKI Roles\]

       C \--\> W  
       P \--\> Q \--\> R \--\> S \--\> T \--\> U \--\> V \--\> W \--\> X \--\> Y \--\> Z \--\> AA  
   end  
---

# **Vault Internal Components**

---

# **Setup Flow**

---

# **Step-by-Step Setup**

## **Phase 1 — Offline Root CA**

1. Generate root CA (offline)  
2. Store private key securely  
3. Create:  
   * DC intermediate CSR  
   * DR intermediate CSR  
4. Sign both with root CA

---

## **Phase 2 — Deploy Vault (DC)**

1. Create namespace:  
   kubectl create ns vault-system  
2. Deploy Vault OSS (HA \+ Raft)  
3. Verify:  
   kubectl get pods \-n vault-system

---

## **Phase 3 — Initialize and Unseal**

vault operator init  
vault operator unseal

* Store unseal keys securely  
* Store root token securely

---

## **Phase 4 — Enable Audit Log**

vault audit enable file file\_path=/vault/audit/vault\_audit.log  
---

## **Phase 5 — Enable KV (IMPORTANT)**

vault secrets enable \-path=kv-dc \-version=2 kv

### **Example secrets**

vault kv put kv-dc/platform/config appName="banking-app"

vault kv put kv-dc/apps/payments/prod \\  
 username="payments-user" \\  
 password="secure-password"  
---

## **Phase 6 — Enable Kubernetes Auth**

vault auth enable \-path=kubernetes-dc kubernetes  
vault write auth/kubernetes-dc/config \\  
 kubernetes\_host="https://api.dc.cluster:6443" \\  
 kubernetes\_ca\_cert=@ca.crt \\  
 token\_reviewer\_jwt="$(cat jwt.token)"  
---

## **Phase 7 — Enable PKI**

vault secrets enable \-path=pki-ingress-dc pki  
vault secrets tune \-max-lease-ttl=8760h pki-ingress-dc  
---

## **Phase 8 — Import Intermediate CA**

vault write pki-ingress-dc/config/ca \\  
 pem\_bundle=@dc-intermediate-chain.pem  
---

## **Phase 9 — Configure PKI URLs**

vault write pki-ingress-dc/config/urls \\  
 issuing\_certificates="https://vault-dc:8200/v1/pki-ingress-dc/ca" \\  
 crl\_distribution\_points="https://vault-dc:8200/v1/pki-ingress-dc/crl"  
---

## **Phase 10 — Policies**

### **KV policy (ESO)**

path "kv-dc/data/\*" {  
 capabilities \= \["read"\]  
}

path "kv-dc/metadata/\*" {  
 capabilities \= \["read", "list"\]  
}  
---

### **PKI policy (cert-manager)**

path "pki-ingress-dc/sign/role-istio-gateway-dc" {  
 capabilities \= \["update"\]  
}  
---

## **Phase 11 — Create Roles**

### **ESO role**

vault write auth/kubernetes-dc/role/eso-kv-readonly-dc \\  
 bound\_service\_account\_names=external-secrets \\  
 bound\_service\_account\_namespaces=external-secrets \\  
 policies=policy-eso \\  
 ttl=1h  
---

### **cert-manager role**

vault write auth/kubernetes-dc/role/cert-manager-pki-issuer-dc \\  
 bound\_service\_account\_names=cert-manager \\  
 bound\_service\_account\_namespaces=cert-manager \\  
 policies=policy-pki \\  
 ttl=1h  
---

## **Phase 12 — PKI Role**

vault write pki-ingress-dc/roles/role-istio-gateway-dc \\  
 allowed\_domains="dc.bank.example.com" \\  
 allow\_subdomains=true \\  
 max\_ttl="720h"  
---

## **Phase 13 — Validation**

vault status  
vault kv get kv-dc/apps/payments/prod  
vault read pki-ingress-dc/roles/role-istio-gateway-dc  
---

# **DR Setup**

Repeat all steps with:

* `kv-dr`  
* `pki-ingress-dr`  
* `kubernetes-dr`  
* DR-specific domains

---

# **KV Role in Your Architecture**

## **KV Flow**

---

# **Key Design Rules**

1. KV \= secrets only  
2. PKI \= certificates only  
3. ESO \= KV only  
4. cert-manager \= PKI only  
5. Istio CA \= mTLS only  
6. DC and DR are independent

---

# **Summary**

This setup gives you:

* Secure secret storage (KV)  
* Automated certificate issuance (PKI)  
* Kubernetes-native integration  
* Strong DC/DR isolation  
* Financial-grade security model

\---

If you want next step, I can convert this into:

\- \*\*ArgoCD GitOps repo (DC/DR overlays)\*\*  
\- \*\*Helm charts\*\*  
\- \*\*OpenShift-ready manifests (Routes, SCC, etc.)\*\*

Just tell me 👍  
give me a downloadable md file of the above answer

Here is your downloadable Markdown file:

Download vault-setup-kv.md

If you want, I can next generate a **fully production-grade version (with exact commands, no simplifications, and OpenShift-specific tweaks)**.

can you give me a tutorial on how to use hashicorp vault with openshift as intermediate pki and secret storage . arrange the tutorial by topics and attach a markdown diagram to explain each topic.  
Thought for 10s  
Thought

# **Tutorial: Using HashiCorp Vault with OpenShift as Intermediate PKI and Secret Storage**

This tutorial is arranged by topic and uses a consistent model:

* **Vault PKI** as an **intermediate CA**  
* **Vault KV** as the **secret store**  
* **cert-manager** for certificate issuance from Vault PKI  
* **External Secrets Operator (ESO)** for syncing secrets from Vault KV into OpenShift  
* **Kubernetes auth** so controllers authenticate to Vault with service accounts

That division matches the intended roles of the products: Vault PKI issues certificates, Vault KV stores secrets, cert-manager obtains and renews certificates from Vault, and ESO’s Vault provider supports the **KV secrets engine** for secret sync.

---

## **Topic 1 — What you are building**

You are building two separate trust paths inside OpenShift:

* **Certificate path**: OpenShift workload or gateway → cert-manager → Vault PKI  
* **Secret path**: OpenShift app → ESO → Vault KV

Vault’s Kubernetes auth method allows a pod or controller using a Kubernetes service account token to authenticate to Vault and receive a Vault token with attached policies.

### **Outcome**

At the end of this setup you will have:

* Vault deployed on or reachable from OpenShift  
* Vault configured with:  
  * **KV v2**  
  * **Kubernetes auth**  
  * **PKI intermediate**  
* cert-manager issuing certificates from Vault  
* ESO syncing secrets from Vault KV into namespaces

---

## **Topic 2 — Core concepts you need first**

### **2.1 KV**

Vault **KV** is the key-value secrets engine. It stores secrets like database usernames, passwords, API keys, and configuration values. ESO’s Vault provider supports the **KV secrets engine only**.

### **2.2 PKI**

Vault **PKI** is the certificate engine. It can act as a certificate authority and is commonly used with an **intermediate CA**, which is the recommended operational model instead of issuing directly from a root. Vault’s own intermediate-CA quick start explicitly says issuing directly from the root is not recommended.

### **2.3 Kubernetes auth**

Vault’s Kubernetes auth method lets a pod or controller authenticate using its service account token and receive Vault policies mapped to that identity.

### **2.4 cert-manager**

cert-manager creates and renews certificates in Kubernetes/OpenShift and supports Vault as an issuer backend.

---

## **Topic 3 — Reference architecture for OpenShift**

For OpenShift, use this structure:

* `vault-system` for Vault  
* `cert-manager` for cert-manager  
* `external-secrets` for ESO  
* `istio-system` or app namespace for certificate consumers  
* app namespaces like `app-payments`, `app-core`, `app-portal`

This tutorial assumes Vault is either:

* deployed **inside OpenShift**, or  
* deployed **externally** but reachable over TLS from OpenShift

Vault can be deployed into Kubernetes using the official HashiCorp Helm chart, including HA configurations.

---

## **Topic 4 — Prerequisites**

Before configuration, prepare:

* an **offline root CA**  
* a signed **intermediate certificate** for Vault PKI  
* OpenShift cluster-admin access  
* a DNS name and TLS path for Vault  
* cert-manager installed  
* ESO installed  
* a service account token review path for Kubernetes auth

If you do not already have Vault deployed, the official deployment material from HashiCorp for Kubernetes is the right starting point.

### **Recommended sequence**

1. Deploy Vault  
2. Initialize and unseal Vault  
3. Enable audit  
4. Enable KV  
5. Enable Kubernetes auth  
6. Enable PKI  
7. Import intermediate  
8. Create policies  
9. Create auth roles  
10. Integrate cert-manager  
11. Integrate ESO  
12. Validate

---

## **Topic 5 — Deploy Vault on OpenShift**

Deploy Vault using the official Helm chart or your standard platform deployment mechanism. For OpenShift, ensure:

* persistent storage is available  
* Vault pods can communicate with each other  
* Vault is reachable over TLS  
* the service account and security context are compatible with your cluster policy

HashiCorp documents running Vault on Kubernetes with the official Helm chart and provides a Kubernetes Raft deployment guide.

### **Minimum operational steps**

oc new-project vault-system  
helm repo add hashicorp ...  
helm install vault hashicorp/vault \-n vault-system

Then verify Vault pods and service endpoints before bootstrap.

---

## **Topic 6 — Initialize and unseal Vault**

After deployment:

1. initialize Vault  
2. store unseal keys securely  
3. unseal nodes  
4. log in with the bootstrap root token  
5. immediately move operational control into a safer admin workflow

Vault’s deployment guide covers initialization and integrated storage setups for Kubernetes.

### **Typical commands**

vault operator init  
vault operator unseal  
vault login  
---

## **Topic 7 — Enable KV for secret storage**

Enable KV v2 for application secrets.

vault secrets enable \-path=kv kv-v2

A more common current form is:

vault secrets enable \-path=kv \-version=2 kv

Vault’s KV engine stores secrets, and KV v2 adds versioning and metadata. ESO’s HashiCorp Vault provider supports the KV engine.

### **Example secret paths**

* `kv/platform/shared`  
* `kv/apps/payments/prod`  
* `kv/apps/portal/prod`

### **Example write**

vault kv put kv/apps/payments/prod \\  
 username="payments-user" \\  
 password="change-me"

### **Why this matters**

Use KV for:

* passwords  
* tokens  
* API keys  
* sensitive configuration

Do not use KV for certificate issuance; that belongs to PKI.

---

## **Topic 8 — Enable Kubernetes auth**

Enable Kubernetes auth so cert-manager and ESO can authenticate with Vault using service accounts.

vault auth enable kubernetes

Then configure it with:

* Kubernetes API server address  
* Kubernetes CA certificate  
* token reviewer JWT

Vault’s Kubernetes auth method is specifically designed for authentication with Kubernetes service account tokens.

### **Example configuration**

vault write auth/kubernetes/config \\  
 kubernetes\_host="https://kubernetes.default.svc:443" \\  
 kubernetes\_ca\_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \\  
 token\_reviewer\_jwt="$TOKEN\_REVIEW\_JWT"

### **Design rule**

Use **different Vault roles** for:

* cert-manager  
* ESO  
* human admins

Do not reuse one broad policy for everything.

---

## **Topic 9 — Configure Vault as an intermediate CA**

This is the PKI part.

The recommended model is:

* **offline root CA**  
* **Vault PKI as intermediate CA**  
* **cert-manager requests certificates from Vault**

Vault’s PKI documentation and intermediate quick start describe setting up an intermediate authority signed by a root authority, and note that direct issuance from a root is not recommended.

### **Steps**

#### **9.1 Enable PKI**

vault secrets enable \-path=pki pki  
vault secrets tune \-max-lease-ttl=8760h pki

#### **9.2 Generate intermediate CSR in Vault**

vault write \-format=json pki/intermediate/generate/internal \\  
 common\_name="OpenShift Intermediate CA" \\  
 | jq \-r '.data.csr' \> vault-intermediate.csr

#### **9.3 Sign the CSR with your offline root**

Use your PKI process outside Vault.

#### **9.4 Import the signed intermediate**

vault write pki/intermediate/set-signed certificate=@vault-intermediate.crt

#### **9.5 Configure URLs**

vault write pki/config/urls \\  
 issuing\_certificates="https://vault.example.com/v1/pki/ca" \\  
 crl\_distribution\_points="https://vault.example.com/v1/pki/crl"

#### **9.6 Create a PKI role**

vault write pki/roles/openshift-ingress \\  
 allowed\_domains="apps.example.com,api.example.com" \\  
 allow\_subdomains=true \\  
 max\_ttl="720h"  
---

## **Topic 10 — Create Vault policies**

You need two policy families:

* **KV read policy** for ESO  
* **PKI sign/issue policy** for cert-manager

Vault policies are path-based and attached after authentication via an auth method such as Kubernetes auth.

### **Example ESO policy**

path "kv/data/apps/\*" {  
 capabilities \= \["read"\]  
}

path "kv/metadata/apps/\*" {  
 capabilities \= \["read", "list"\]  
}

### **Example cert-manager policy**

path "pki/sign/openshift-ingress" {  
 capabilities \= \["update"\]  
}

path "pki/issue/openshift-ingress" {  
 capabilities \= \["update"\]  
}

Write them into Vault:

vault policy write eso-read eso-read.hcl  
vault policy write certmgr-pki certmgr-pki.hcl  
---

## **Topic 11 — Create Kubernetes auth roles in Vault**

Map service accounts to policies.

### **cert-manager role**

vault write auth/kubernetes/role/certmgr-role \\  
 bound\_service\_account\_names="cert-manager" \\  
 bound\_service\_account\_namespaces="cert-manager" \\  
 policies="certmgr-pki" \\  
 ttl="1h"

### **ESO role**

vault write auth/kubernetes/role/eso-role \\  
 bound\_service\_account\_names="external-secrets" \\  
 bound\_service\_account\_namespaces="external-secrets" \\  
 policies="eso-read" \\  
 ttl="1h"

Vault’s Kubernetes auth method is designed for this SA-to-role mapping pattern.

---

## **Topic 12 — Integrate cert-manager with Vault PKI**

cert-manager supports Vault as an issuer. You create an `Issuer` or `ClusterIssuer` that points at Vault, and then `Certificate` resources request certificates through that issuer. cert-manager documentation describes Vault issuers and the `Certificate` resource model.

### **Example ClusterIssuer**

apiVersion: cert-manager.io/v1  
kind: ClusterIssuer  
metadata:  
 name: vault-pki  
spec:  
 vault:  
   server: https://vault.example.com  
   path: pki/sign/openshift-ingress  
   caBundle: \<BASE64\_CA\_BUNDLE\>  
   auth:  
     kubernetes:  
       mountPath: /v1/auth/kubernetes  
       role: certmgr-role  
       serviceAccountRef:  
         name: cert-manager

### **Example Certificate**

apiVersion: cert-manager.io/v1  
kind: Certificate  
metadata:  
 name: app-tls  
 namespace: app-payments  
spec:  
 secretName: app-tls  
 issuerRef:  
   name: vault-pki  
   kind: ClusterIssuer  
 commonName: payments.apps.example.com  
 dnsNames:  
   \- payments.apps.example.com  
 usages:  
   \- server auth  
---

## **Topic 13 — Integrate ESO with Vault KV**

ESO synchronizes external secrets into Kubernetes secrets. The Vault provider supports HashiCorp Vault KV, and ESO uses `SecretStore` or `ClusterSecretStore` plus `ExternalSecret` resources to define sync behavior.

### **Example SecretStore**

apiVersion: external-secrets.io/v1  
kind: SecretStore  
metadata:  
 name: vault-kv  
 namespace: app-payments  
spec:  
 provider:  
   vault:  
     server: https://vault.example.com  
     path: kv  
     version: v2  
     auth:  
       kubernetes:  
         mountPath: kubernetes  
         role: eso-role  
         serviceAccountRef:  
           name: external-secrets  
           namespace: external-secrets

### **Example ExternalSecret**

apiVersion: external-secrets.io/v1  
kind: ExternalSecret  
metadata:  
 name: payments-secret  
 namespace: app-payments  
spec:  
 refreshInterval: 1h  
 secretStoreRef:  
   name: vault-kv  
   kind: SecretStore  
 target:  
   name: payments-secret  
 data:  
   \- secretKey: username  
     remoteRef:  
       key: apps/payments/prod  
       property: username  
   \- secretKey: password  
     remoteRef:  
       key: apps/payments/prod  
       property: password  
---

## **Topic 14 — Validation**

Validate each layer separately.

### **14.1 Vault**

vault status  
vault auth list  
vault secrets list  
vault policy list

### **14.2 KV**

vault kv get kv/apps/payments/prod

### **14.3 PKI**

vault read pki/roles/openshift-ingress

### **14.4 cert-manager**

oc get clusterissuer  
oc get certificate \-A  
oc describe certificate app-tls \-n app-payments

### **14.5 ESO**

oc get secretstore \-A  
oc get externalsecret \-A  
oc describe externalsecret payments-secret \-n app-payments

If cert-manager is working, the `Certificate` should become ready and produce a Kubernetes TLS secret. If ESO is working, the `ExternalSecret` should reconcile into a normal Kubernetes `Secret`. cert-manager’s docs describe that a `Certificate` resource results in a Kubernetes secret, and ESO’s docs describe that `ExternalSecret` syncs into a Kubernetes `Secret`.

---

## **Topic 15 — Operating model and security rules**

For production, keep these rules:

1. **Use Vault as an intermediate, not the root**  
2. **Keep the root CA offline**  
3. **Use separate Vault policies for ESO and cert-manager**  
4. **Use Kubernetes auth, not broad static tokens**  
5. **Use KV only for secrets**  
6. **Use PKI only for certificates**  
7. **Enable audit logging early**  
8. **Keep certificate TTLs short and renew automatically**

Vault’s intermediate guidance, PKI engine design, Kubernetes auth model, and cert-manager renewal model support that approach.

---

## **Topic 16 — Suggested learning path**

Study in this order:

1. Vault deployment on Kubernetes/OpenShift  
2. Vault KV  
3. Vault Kubernetes auth  
4. Vault PKI intermediate  
5. cert-manager Vault issuer  
6. ESO Vault provider  
7. validation and rotation testing

---

## **Final practical advice**

