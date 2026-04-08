# Implementation Blueprint

Vault OSS + cert-manager + ESO + two independent Istio meshes for DC/DR



Implementation Blueprint

Vault OSS + cert-manager + ESO + two independent Istio meshes for DC/DR

This blueprint assumes:

Two independent Kubernetes/OpenShift clusters: one in DC, one in DR
Two independent Vault OSS clusters: one per site
One offline root CA
One intermediate CA per site
cert-manager for gateway/server certificates from Vault PKI
ESO for KV secret sync only
Istio CA for in-mesh mTLS
Vault Kubernetes auth for controllers, with policies bound to service accounts. Vault policies are path-based and deny by default.
1. Target namespace layout

Use the same namespace model in both DC and DR for operational symmetry.

1.1 Platform namespaces
Namespace	Purpose
vault-system	Vault cluster
cert-manager	cert-manager controller
external-secrets	External Secrets Operator
istio-system	Istio control plane and ingress gateway
platform-secrets	optional shared platform secrets synced by ESO
app-<name>	application namespaces
1.2 Recommended naming by site

Use site suffixes in Vault paths and role names, not in Kubernetes namespaces, so manifests stay portable.

Examples:

Site code: dc
Site code: dr

That yields patterns like:

Vault auth mount: kubernetes-dc, kubernetes-dr
PKI mount: pki-ingress-dc, pki-ingress-dr
KV mount: kv-dc, kv-dr
2. Vault mount layout per site

Keep mounts explicit and purpose-specific.

2.1 DC Vault mounts
Mount path	Type	Purpose
auth/kubernetes-dc	auth	Kubernetes auth for DC cluster
kv-dc	KV v2	Application and platform secrets for DC
pki-ingress-dc	PKI	Gateway/server cert issuance for DC
pki-int-dc	PKI optional	reserved if you later separate internal platform PKI
2.2 DR Vault mounts
Mount path	Type	Purpose
auth/kubernetes-dr	auth	Kubernetes auth for DR cluster
kv-dr	KV v2	Application and platform secrets for DR
pki-ingress-dr	PKI	Gateway/server cert issuance for DR
pki-int-dr	PKI optional	reserved if you later separate internal platform PKI

Vault PKI is designed to issue dynamic X.509 certificates, and mounts can be enabled at arbitrary paths.

3. Vault auth roles

Use separate Vault auth roles for each controller and site.

3.1 Minimum auth roles per site
DC
eso-kv-readonly-dc
cert-manager-pki-issuer-dc
platform-breakglass-dc
security-audit-read-dc
DR
eso-kv-readonly-dr
cert-manager-pki-issuer-dr
platform-breakglass-dr
security-audit-read-dr

Vault Kubernetes auth binds identities to Kubernetes service accounts and namespaces.

3.2 Service account bindings
DC bindings
Vault role	Kubernetes namespace	Service account	Purpose
eso-kv-readonly-dc	external-secrets	external-secrets	Read KV only
cert-manager-pki-issuer-dc	cert-manager	cert-manager	Sign gateway/server certs
platform-breakglass-dc	restricted ops namespace or human auth path	not controller-bound	emergency ops
security-audit-read-dc	none or read-only admin workflow	not controller-bound	audit review
DR bindings
Vault role	Kubernetes namespace	Service account	Purpose
eso-kv-readonly-dr	external-secrets	external-secrets	Read KV only
cert-manager-pki-issuer-dr	cert-manager	cert-manager	Sign gateway/server certs
platform-breakglass-dr	restricted ops namespace or human auth path	not controller-bound	emergency ops
security-audit-read-dr	none or read-only admin workflow	not controller-bound	audit review
4. Vault policy layout

Vault policies should map to function, not to product teams broadly. Policies are deny-by-default and path-based.

4.1 Policy set per site
DC policies
policy-eso-kv-readonly-dc
policy-cert-manager-pki-dc
policy-breakglass-dc
policy-audit-read-dc
DR policies
policy-eso-kv-readonly-dr
policy-cert-manager-pki-dr
policy-breakglass-dr
policy-audit-read-dr
4.2 KV policy design

Keep KV pathing predictable:

DC KV path model
kv-dc/data/platform/*
kv-dc/data/apps/<app>/*
DR KV path model
kv-dr/data/platform/*
kv-dr/data/apps/<app>/*
Example ESO read-only DC policy
path "kv-dc/data/platform/*" {
  capabilities = ["read"]
}

path "kv-dc/metadata/platform/*" {
  capabilities = ["read", "list"]
}

path "kv-dc/data/apps/*" {
  capabilities = ["read"]
}

path "kv-dc/metadata/apps/*" {
  capabilities = ["read", "list"]
}
Example ESO read-only DR policy
path "kv-dr/data/platform/*" {
  capabilities = ["read"]
}

path "kv-dr/metadata/platform/*" {
  capabilities = ["read", "list"]
}

path "kv-dr/data/apps/*" {
  capabilities = ["read"]
}

path "kv-dr/metadata/apps/*" {
  capabilities = ["read", "list"]
}
4.3 PKI policy design

cert-manager should only be able to issue certificates through the intended PKI role and not manage CA internals. cert-manager’s Vault integration uses a Vault Issuer or ClusterIssuer to request certificates from Vault.

Example cert-manager PKI DC policy
path "pki-ingress-dc/sign/role-istio-gateway-dc" {
  capabilities = ["update"]
}

path "pki-ingress-dc/issue/role-istio-gateway-dc" {
  capabilities = ["update"]
}
Example cert-manager PKI DR policy
path "pki-ingress-dr/sign/role-istio-gateway-dr" {
  capabilities = ["update"]
}

path "pki-ingress-dr/issue/role-istio-gateway-dr" {
  capabilities = ["update"]
}

Do not give cert-manager access to:

root/sign-intermediate
CRL config writes
issuer creation
broad reads on unrelated mounts
4.4 Break-glass policy design

Keep this minimal and audited.

Example break-glass DC policy
path "kv-dc/data/platform/*" {
  capabilities = ["read", "list"]
}

path "kv-dc/data/apps/*" {
  capabilities = ["read", "list"]
}

path "pki-ingress-dc/cert/*" {
  capabilities = ["read", "list"]
}

path "sys/health" {
  capabilities = ["read"]
}

No write unless explicitly justified.

5. PKI role layout

Use one intermediate per site for ingress/server certificates. Do not use Vault PKI for Istio workload mTLS in this design.

5.1 PKI engines
DC
pki-ingress-dc
signed by offline root
default issuer for DC gateway/server certs
DR
pki-ingress-dr
signed by offline root
default issuer for DR gateway/server certs
5.2 Recommended PKI roles
DC PKI roles
role-istio-gateway-dc
role-platform-ingress-dc
role-internal-server-dc optional
DR PKI roles
role-istio-gateway-dr
role-platform-ingress-dr
role-internal-server-dr optional

Vault PKI roles are the mechanism for defining issuance constraints such as allowed names and TTL behavior.

5.3 Recommended constraints for gateway roles
role-istio-gateway-dc

Use this only for DC ingress gateway certificates.

Recommended settings:

allow only DC DNS names
allow subdomains only where justified
short TTL
server auth only
key type aligned to your enterprise standard
no wildcard unless operationally necessary

Example intended SAN scope

api.dc.bank.example.com
*.apps.dc.bank.example.com only if your policy allows wildcard gateway use
role-istio-gateway-dr

Equivalent DR-only scope.

Example intended SAN scope

api.dr.bank.example.com
*.apps.dr.bank.example.com only if approved
5.4 Example PKI role posture table
Role	Site	Intended subjects	TTL posture	Consumer
role-istio-gateway-dc	DC	DC gateway FQDNs	short-lived	cert-manager
role-platform-ingress-dc	DC	platform route/internal LB names	short-lived	cert-manager
role-istio-gateway-dr	DR	DR gateway FQDNs	short-lived	cert-manager
role-platform-ingress-dr	DR	platform route/internal LB names	short-lived	cert-manager
6. ESO store layout

ESO’s Vault provider supports the KV secrets engine only, and SecretStore is namespaced while ClusterSecretStore is cluster-scoped. For regulated environments, prefer namespaced SecretStore unless there is a strong central-governance reason to widen scope.

6.1 Recommended pattern
Use one ClusterSecretStore per site only for centrally governed platform use cases
Use one SecretStore per application namespace for business apps
6.2 Example names
DC
ClusterSecretStore: vault-kv-dc-platform
SecretStore in app-payments: vault-kv-dc-payments
DR
ClusterSecretStore: vault-kv-dr-platform
SecretStore in app-payments: vault-kv-dr-payments
7. cert-manager issuer layout

Use a site-local issuer that talks only to the site-local Vault PKI mount.

7.1 Recommended issuer naming
DC
ClusterIssuer: vault-pki-ingress-dc
DR
ClusterIssuer: vault-pki-ingress-dr

Use ClusterIssuer if multiple namespaces need certificates from the same PKI authority; otherwise use namespaced Issuer. cert-manager supports Vault as an issuer backend.

7.2 Certificate objects

Use Certificate objects in the namespace where the Istio ingress gateway expects the TLS secret, typically istio-system. cert-manager writes the resulting keypair to a Kubernetes Secret referenced by the gateway.

Example secret naming
DC: istio-ingressgateway-tls-dc
DR: istio-ingressgateway-tls-dr
8. Istio integration model

Use:

Vault PKI + cert-manager for gateway TLS
Istio CA for mesh mTLS

Do not blend the two trust functions unless there is a specific requirement.

Gateway consumption model

Istio ingress gateway references a Kubernetes TLS secret, and cert-manager maintains that secret lifecycle.

9. Exact deployment sequence

This is the practical order.

9.1 Phase 0 — prerequisites

Complete these before touching either site.

Finalize DNS model:
DC public/internal gateway names
DR public/internal gateway names
Finalize certificate subject policy:
whether wildcards are allowed
TTL standards
approved SAN patterns
Finalize namespace names
Finalize service account names
Finalize backup and audit requirements
Prepare offline root CA
Generate and securely store site intermediate CSRs or signing inputs
9.2 Phase 1 — offline root CA ceremony
Generate offline root CA with OpenSSL.
Store private key offline under dual-control.
Create one intermediate signing flow for DC.
Create one intermediate signing flow for DR.
Record:
serial number
validity period
issuance policy
responsible approvers

Result:

root CA stays offline
signed intermediate material available for DC and DR Vault PKI engines
9.3 Phase 2 — deploy Vault in DC
Create namespace vault-system in DC cluster.
Deploy Vault OSS HA with integrated Raft in DC.
Initialize and unseal Vault.
Enable audit logging.
Configure backup/snapshot procedure.
Enable auth mount auth/kubernetes-dc.
Configure Kubernetes auth for the DC cluster.
Enable kv-dc as KV v2.
Enable pki-ingress-dc.
Import or configure the DC intermediate CA into pki-ingress-dc.
Configure PKI URLs, CRL/AIA as per your enterprise PKI policy.
Create Vault policies:
policy-eso-kv-readonly-dc
policy-cert-manager-pki-dc
policy-breakglass-dc
Create Vault roles:
eso-kv-readonly-dc
cert-manager-pki-issuer-dc
Create PKI roles:
role-istio-gateway-dc
role-platform-ingress-dc

Result:

DC Vault is ready for KV and PKI
9.4 Phase 3 — deploy platform controllers in DC
Create namespaces:
cert-manager
external-secrets
istio-system
Install cert-manager.
Install ESO.
Install Istio control plane and ingress gateway.
Confirm service accounts:
cert-manager/cert-manager
external-secrets/external-secrets
Bind Vault Kubernetes auth roles to those service accounts.

Result:

platform controllers are installed but not yet integrated
9.5 Phase 4 — integrate cert-manager with Vault in DC
Export the Vault CA chain needed by cert-manager trust.
Create the trust secret/config as required by your cert-manager Vault integration model.
Create ClusterIssuer vault-pki-ingress-dc.
Create a Certificate in istio-system for the DC ingress gateway secret.
Wait for cert issuance.
Verify the Kubernetes TLS secret exists.
Configure Istio gateway to use that secret.
Test TLS handshake against the gateway.

Result:

DC gateway/server TLS is working through Vault PKI and cert-manager
9.6 Phase 5 — integrate ESO with Vault in DC
Decide whether each app gets:
its own SecretStore, or
a shared ClusterSecretStore
Create the DC Vault auth reference for ESO.
Create:
ClusterSecretStore for shared platform secrets
SecretStore in each app namespace for app-local secrets
Create ExternalSecret resources mapping Vault KV paths to Kubernetes Secrets.
Verify synced Kubernetes Secrets appear.
Verify app pods can consume them.

Result:

DC apps can receive KV secrets from Vault through ESO
9.7 Phase 6 — deploy business workloads in DC
Create application namespaces.
Create DC-specific SecretStore objects.
Create DC-specific ExternalSecret objects.
Create app Deployments/StatefulSets.
Enable sidecar injection for Istio as needed.
Create Gateway/VirtualService or Gateway API equivalents.
Validate:
gateway TLS
mesh mTLS
secret availability
app readiness

Result:

DC production path is ready
9.8 Phase 7 — repeat for DR with site-local values

Do not clone DC runtime identity blindly. Recreate DR with DR-specific values.

Deploy Vault OSS HA in vault-system on DR cluster.
Initialize and unseal DR Vault.
Enable audit logging and backups.
Enable auth/kubernetes-dr.
Enable kv-dr.
Enable pki-ingress-dr.
Import/configure the DR intermediate CA.
Create DR policies:
policy-eso-kv-readonly-dr
policy-cert-manager-pki-dr
policy-breakglass-dr
Create DR auth roles:
eso-kv-readonly-dr
cert-manager-pki-issuer-dr
Create DR PKI roles:
role-istio-gateway-dr
role-platform-ingress-dr
Install cert-manager, ESO, Istio in DR.
Create ClusterIssuer vault-pki-ingress-dr.
Issue DR gateway certificate.
Create DR SecretStore / ExternalSecret objects.
Deploy DR workloads.
Validate end-to-end independently of DC.

Result:

DR is self-sufficient
9.9 Phase 8 — failover readiness
Populate DR KV with the business secrets required during failover.
Validate DR certificates issue without any DC dependency.
Validate DR ingress TLS.
Validate DR mesh mTLS.
Validate DR app startup from DR-synced secrets.
Validate DNS/GSLB failover procedure.
Run a controlled failover drill.
10. Recommended artifact set per site

This is the minimum manifest/runbook set I would maintain.

DC artifacts
00-namespaces-dc.yaml
01-vault-install-dc.yaml or Helm values
02-vault-bootstrap-dc.sh
03-vault-policies-dc.hcl
04-vault-roles-dc.sh
05-cert-manager-install-dc.yaml
06-eso-install-dc.yaml
07-istio-install-dc.yaml
08-clusterissuer-dc.yaml
09-gateway-certificate-dc.yaml
10-secretstores-dc.yaml
11-externalsecrets-dc.yaml
12-app-deployments-dc.yaml
90-validation-dc.sh
DR artifacts

Mirror the same with -dr.

11. Example logical mapping for one application
Application: payments
DC
Namespace: app-payments
Vault secret path: kv-dc/data/apps/payments/prod
SecretStore: vault-kv-dc-payments
ExternalSecret target: payments-app-secret
Gateway cert issuer: vault-pki-ingress-dc
Gateway secret: istio-ingressgateway-tls-dc
DR
Namespace: app-payments
Vault secret path: kv-dr/data/apps/payments/prod
SecretStore: vault-kv-dr-payments
ExternalSecret target: payments-app-secret
Gateway cert issuer: vault-pki-ingress-dr
Gateway secret: istio-ingressgateway-tls-dr
12. Opinionated production recommendations
Keep these design rules
Rule 1

One site, one Vault, one PKI intermediate, one mesh.

Rule 2

cert-manager touches PKI; ESO touches KV.
Do not cross those roles. ESO’s Vault provider is KV-only.

Rule 3

No cross-site runtime dependency.
DC controllers should never require DR Vault. DR controllers should never require DC Vault.

Rule 4

Use identical structure, different values.
The DC and DR deployment sequence should be the same, with only site-scoped configuration differing.

Rule 5

Failover is tested, not assumed.