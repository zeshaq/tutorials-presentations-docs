# Vault with OpenShift — Intermediate PKI and Secret Storage Tutorial

## Overview

This tutorial explains how to use **HashiCorp Vault** with **OpenShift** as:

- Intermediate Certificate Authority (PKI)
- Secret storage (KV)
- Integrated with:
  - cert-manager (for certificates)
  - External Secrets Operator (ESO) (for secrets)

---

# Architecture Diagram

```mermaid
flowchart LR
    A[Offline Root CA] --> B[Vault PKI Intermediate]
    B --> C[cert-manager]
    C --> D[TLS Secret in OpenShift]
    D --> E[Route / Gateway]

    F[Vault KV] --> G[External Secrets Operator]
    G --> H[Kubernetes Secret]
    H --> I[Application Pod]

    J[Service Account] --> K[Vault Kubernetes Auth]
    K --> B
    K --> F
```

---

# Topic 1 — Core Concepts

## KV (Key-Value)
Stores:
- passwords
- API keys
- configs

## PKI
Issues:
- TLS certificates
- intermediate CA

## Kubernetes Auth
Maps:
- ServiceAccount → Vault Role → Policy

---

# Topic 2 — Deployment Architecture

```mermaid
flowchart TB
    subgraph OpenShift
        CM[cert-manager]
        ESO[External Secrets Operator]
        APPS[Applications]
        TLS[TLS Secrets]
        SECRETS[App Secrets]
    end

    subgraph Vault
        AUTH[Kubernetes Auth]
        PKI[PKI]
        KV[KV]
    end

    CM --> AUTH --> PKI --> CM --> TLS
    ESO --> AUTH --> KV --> ESO --> SECRETS
    TLS --> APPS
    SECRETS --> APPS
```

---

# Topic 3 — Setup Flow

```mermaid
flowchart LR
    A[Deploy Vault] --> B[Init/Unseal]
    B --> C[Enable KV]
    C --> D[Enable K8s Auth]
    D --> E[Enable PKI]
    E --> F[Import Intermediate]
    F --> G[Policies]
    G --> H[Roles]
    H --> I[Integrate cert-manager]
    I --> J[Integrate ESO]
```

---

# Topic 4 — Vault Setup Steps

## 1. Enable KV
```bash
vault secrets enable -path=kv -version=2 kv
```

## 2. Enable Kubernetes Auth
```bash
vault auth enable kubernetes
```

## 3. Configure Auth
```bash
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc" \
  kubernetes_ca_cert=@ca.crt \
  token_reviewer_jwt="$JWT"
```

---

# Topic 5 — PKI Intermediate Setup

```mermaid
flowchart TB
    A[Root CA] --> B[Sign CSR]
    B --> C[Vault PKI]
    C --> D[PKI Role]
    D --> E[cert-manager]
```

## Enable PKI
```bash
vault secrets enable -path=pki pki
vault secrets tune -max-lease-ttl=8760h pki
```

## Generate CSR
```bash
vault write pki/intermediate/generate/internal common_name="Intermediate"
```

## Import cert
```bash
vault write pki/intermediate/set-signed certificate=@cert.pem
```

---

# Topic 6 — Policies

## ESO Policy
```hcl
path "kv/data/*" {
  capabilities = ["read"]
}
```

## cert-manager Policy
```hcl
path "pki/sign/*" {
  capabilities = ["update"]
}
```

---

# Topic 7 — Kubernetes Roles

```mermaid
flowchart LR
    A[cert-manager SA] --> B[Vault Role]
    C[ESO SA] --> D[Vault Role]
```

---

# Topic 8 — cert-manager Integration

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: vault
spec:
  vault:
    server: https://vault
    path: pki/sign/role
```

---

# Topic 9 — ESO Integration

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: app-secret
spec:
  data:
    - secretKey: password
      remoteRef:
        key: apps/app
        property: password
```

---

# Topic 10 — KV Flow

```mermaid
flowchart LR
    A[Vault KV] --> B[ESO]
    B --> C[K8s Secret]
    C --> D[Pod]
```

---

# Topic 11 — Validation

```mermaid
flowchart TB
    A[Vault OK] --> B[KV OK]
    A --> C[PKI OK]
    B --> D[ESO OK]
    C --> E[cert-manager OK]
```

---

# Final Rules

- KV = secrets
- PKI = certificates
- ESO = KV only
- cert-manager = PKI only
- Use intermediate CA
- Keep root offline
