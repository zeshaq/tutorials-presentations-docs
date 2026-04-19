# Implementation Guide

This guide explains how to use the YAML pack step by step on OpenShift for the target architecture:

- OpenShift Service Mesh 3
- ambient mode
- Gateway API ingress
- controlled egress
- Vault PKI
- Vault KV
- cert-manager
- External Secrets Operator
- F5 as public edge
- WSO2 as API gateway

## Before you begin

Confirm these prerequisites first:

1. OpenShift cluster is on a supported version for OSSM 3 ambient mode.
2. OpenShift Service Mesh 3 Operator is already installed.
3. cert-manager Operator is already installed.
4. External Secrets Operator is already installed.
5. Gateway API CRDs are available in the cluster.
6. Vault is reachable from the cluster.
7. You know which namespace and service account mappings Vault should trust.
8. You have final values for:
   - public hostname
   - WSO2 internal hostname
   - Vault address
   - Vault PKI sign path
   - Vault KV mount path
   - Kubernetes auth mount path in Vault
   - base64 CA bundle
   - sample image or real service image
   - partner or external host for egress testing

## Recommended preparation

Before applying anything:

- copy this folder into an environment-specific directory if needed
- replace all `REPLACE_ME_*` placeholders
- review all namespace names
- confirm whether WSO2 is in-cluster or external
- confirm whether the egress destination is HTTP, HTTPS, or mTLS

## Phase 1: Prepare the namespaces

Apply:

```bash
oc apply -f 00-namespaces.yaml
```

What this does:

- creates namespaces for the control plane
- creates namespaces for ingress and egress gateways
- creates namespaces for applications
- enables discovery labels
- enables ambient dataplane label on the sample app namespace

Validate:

```bash
oc get ns istio-system istio-cni ztunnel mesh-ingress mesh-egress app-sample wso2-system
```

Watch out for:

- namespace labels must match the discovery selector strategy used by the mesh
- `ztunnel` namespace name must match the `trustedZtunnelNamespace` value in the Istio resource

## Phase 2: Install the OSSM 3 control plane

Apply:

```bash
oc apply -f 01-istio-control-plane.yaml
```

Validate:

```bash
oc get istio -A
oc wait --for=condition=Ready istio/default -n istio-system --timeout=5m
```

What to watch out for:

- the `profile` must be `ambient`
- the control plane namespace must be correct
- if you change namespace labels later, discovery may stop matching workloads

## Phase 3: Install Istio CNI

Apply:

```bash
oc apply -f 02-istio-cni.yaml
```

Validate:

```bash
oc get istiocni -A
oc get pods -n istio-cni
```

Watch out for:

- ambient mode depends on correct traffic redirection
- if CNI is unhealthy, workloads may not enter the ambient path correctly

## Phase 4: Install ztunnel

Apply:

```bash
oc apply -f 03-ztunnel.yaml
```

Validate:

```bash
oc get ztunnel -A
oc get pods -n ztunnel -o wide
```

Watch out for:

- Red Hat requires the trusted ztunnel namespace to match the Istio config
- if ztunnel is missing or unhealthy, ambient-mode traffic will not behave correctly

## Phase 5: Configure Vault PKI and Vault KV integrations

Apply:

```bash
oc apply -f 04-platform-pki-and-secrets.yaml
```

This creates:

- a `ClusterIssuer` for cert-manager using Vault PKI
- a `ClusterSecretStore` for ESO using Vault KV

Validate:

```bash
oc get clusterissuer vault-pki-platform-internal
oc get clustersecretstore vault-kv-platform
```

Watch out for:

- `caBundle` must be valid and correctly encoded
- `mountPath` must match your Vault Kubernetes auth method
- Vault role names must already exist and allow these service accounts
- `cert-manager` and `external-secrets` service accounts must match the names in Vault policies

## Phase 6: Configure Gateway API ingress

Apply:

```bash
oc apply -f 05-gateway-api-ingress.yaml
```

This does two things:

- requests the ingress TLS certificate from Vault via cert-manager
- creates the Gateway API ingress listener

Validate:

```bash
oc get certificate -n mesh-ingress
oc get secret public-api-ingress-cert -n mesh-ingress
oc get gateway -n mesh-ingress
```

Watch out for:

- the hostname must match what WSO2 will use upstream
- the certificate will not issue if Vault auth or the PKI sign path is wrong
- Gateway API listener TLS uses the Kubernetes Secret name, so the Certificate must succeed first

## Phase 7: Configure routes to applications

Apply:

```bash
oc apply -f 06-gateway-api-routes.yaml
```

Validate:

```bash
oc get httproute -n app-sample
oc describe httproute sample-api-route -n app-sample
```

Watch out for:

- `allowedRoutes` on the Gateway must allow the application namespace
- route hostnames must match the Gateway hostname
- backend service names and ports must match the deployed application

## Phase 8: Configure the egress starting point

Apply:

```bash
oc apply -f 07-egress-gateway-and-external-service.yaml
```

This file is intentionally a starter template, not a final universal egress design.

Validate:

```bash
oc get gateway -n mesh-egress
oc get serviceentry -n app-sample
oc get authorizationpolicy -n mesh-egress
```

Watch out for:

- egress is highly destination-specific
- TLS, HTTP, HTTPS, or partner mTLS flows may each need different configuration
- this file gives structure, but real egress implementations often need more policy and routing detail
- if your destination is a partner with mTLS, you must also manage client cert material and trust expectations

## Phase 9: Deploy the sample app

Apply:

```bash
oc apply -f 08-sample-app.yaml
```

Validate:

```bash
oc get deploy,svc,sa -n app-sample
oc get pods -n app-sample -o wide
```

Watch out for:

- sample image name must be replaced first
- application namespace must still carry the ambient dataplane label
- if the app starts before secrets are available, it may fail depending on startup behavior

## Phase 10: Sync application secrets from Vault KV

Apply:

```bash
oc apply -f 09-sample-app-secrets.yaml
```

Validate:

```bash
oc get secretstore,externalsecret -n app-sample
oc get secret sample-api-app-secret -n app-sample
```

Watch out for:

- remote KV path must match the actual Vault data path
- property names must exist in the secret document
- the sample app service account must match the Vault auth role

## Phase 11: Issue a WSO2 internal certificate if WSO2 runs in-cluster

Apply:

```bash
oc apply -f 10-wso2-internal-certificate.yaml
```

Validate:

```bash
oc get certificate -n wso2-system
oc get secret wso2-internal-tls -n wso2-system
```

Watch out for:

- only use this manifest if WSO2 runs inside the cluster
- if WSO2 is external, issue the cert using Vault through that platform’s normal delivery path instead

## End-to-end validation

After all manifests are applied:

1. Confirm the ingress certificate was issued.
2. Confirm WSO2 can trust and connect to the Gateway API ingress endpoint.
3. Confirm the sample route resolves to the sample service.
4. Confirm the application received its Vault KV secrets.
5. Confirm ambient mesh traffic works between services.
6. Confirm outbound traffic follows the intended egress path.

## Suggested validation commands

```bash
oc get gateway -A
oc get httproute -A
oc get certificate -A
oc get secret -n mesh-ingress
oc get pods -n ztunnel
oc get pods -n app-sample
oc logs deploy/sample-api -n app-sample
```

## Things to watch out for

### 1. Ambient mode prerequisites

Ambient mode needs:

- supported OpenShift version
- supported OSSM 3 version
- correct Gateway API CRDs
- correct CNI behavior

### 2. Vault auth mismatches

Most early failures happen because:

- wrong Kubernetes auth mount
- wrong Vault role
- wrong service account name
- incorrect CA bundle

### 3. Gateway namespace placement

Keep ingress and egress gateways outside the control-plane namespace.

### 4. Placeholder drift

Do not leave placeholder values in:

- hostnames
- Vault paths
- sample image
- CA bundle

### 5. WSO2 and F5 are not fully covered by Kubernetes YAML

You still need external configuration for:

- F5 public VIP and DigiCert cert
- F5 trust of internal Vault-issued certs
- WSO2 upstream configuration to Gateway API ingress
- WSO2 trust settings for Vault-issued ingress certs

### 6. Egress is not one-size-fits-all

The egress file in this pack is a scaffold.

Real outbound traffic patterns may need:

- destination-specific policies
- partner-specific mTLS
- protocol-specific tuning
- more complete Gateway API or mesh routing rules

## Safe rollout recommendation

Roll out in this order:

1. dev
2. test
3. pre-prod
4. one low-risk production API
5. wider production rollout

## Final implementation advice

Treat this folder as a platform template pack, not a copy-paste production install.

The cleanest implementation path is:

- replace placeholders carefully
- validate each phase before moving to the next
- test one service first
- add egress controls gradually
- tighten trust and policy only after the traffic path is stable
