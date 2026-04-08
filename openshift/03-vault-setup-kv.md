# Vault Setup with KV (DC/DR) — Implementation Guide

## Overview

This document describes the **Vault OSS setup** for:

- DC and DR sites
- KV secrets engine
- PKI engine
- Kubernetes authentication
- Policy and role structure

---

# Architecture Diagram

```mermaid
flowchart TB
    A[Offline Root CA<br/>OpenSSL] --> B[Sign DC Intermediate]
    A --> C[Sign DR Intermediate]

    subgraph DC[DC Site]
        D[Vault OSS Cluster - DC<br/>Raft HA]
        E[Init Vault]
        F[Unseal]
        G[Enable Audit Log]
        H[Enable KV v2<br/>kv-dc]
        I[Enable Kubernetes Auth<br/>auth/kubernetes-dc]
        J[Enable PKI<br/>pki-ingress-dc]
        K[Import DC Intermediate]
        L[Configure PKI URLs]
        M[Write Policies]
        N[Create Auth Roles]
        O[Create PKI Roles]

        B --> K
        D --> E --> F --> G --> H --> I --> J --> K --> L --> M --> N --> O
    end

    subgraph DR[DR Site]
        P[Vault OSS Cluster - DR<br/>Raft HA]
        Q[Init Vault]
        R[Unseal]
        S[Enable Audit Log]
        T[Enable KV v2<br/>kv-dr]
        U[Enable Kubernetes Auth<br/>auth/kubernetes-dr]
        V[Enable PKI<br/>pki-ingress-dr]
        W[Import DR Intermediate]
        X[Configure PKI URLs]
        Y[Write Policies]
        Z[Create Auth Roles]
        AA[Create PKI Roles]

        C --> W
        P --> Q --> R --> S --> T --> U --> V --> W --> X --> Y --> Z --> AA
    end
```

---

# Vault Internal Components

```mermaid
flowchart LR
    A[Vault KV] --> B[ESO reads secrets]
    C[Vault PKI] --> D[cert-manager requests certs]
    E[Vault Kubernetes Auth] --> B
    E --> D
    F[Vault Policies] --> E
    G[Vault Audit Log] --> H[SIEM / Logs]
```

---

# Setup Flow

```mermaid
flowchart LR
    A[Deploy Vault] --> B[Init / Unseal]
    B --> C[Enable Audit]
    C --> D[Enable KV]
    D --> E[Enable K8s Auth]
    E --> F[Enable PKI]
    F --> G[Import Intermediate]
    G --> H[Write Policies]
    H --> I[Create Auth Roles]
    I --> J[Create PKI Roles]
    J --> K[Validate]
```

---

# Step-by-Step Setup

## Phase 1 — Offline Root CA

1. Generate root CA (offline)
2. Store private key securely
3. Create:
   - DC intermediate CSR
   - DR intermediate CSR
4. Sign both with root CA

---

## Phase 2 — Deploy Vault (DC)

1. Create namespace:
   kubectl create ns vault-system

2. Deploy Vault OSS (HA + Raft)

3. Verify:
   kubectl get pods -n vault-system

---

## Phase 3 — Initialize and Unseal

vault operator init  
vault operator unseal  

---

## Phase 4 — Enable Audit Log

vault audit enable file file_path=/vault/audit/vault_audit.log

---

## Phase 5 — Enable KV

vault secrets enable -path=kv-dc -version=2 kv

---

## Phase 6 — Enable Kubernetes Auth

vault auth enable -path=kubernetes-dc kubernetes

---

## Phase 7 — Enable PKI

vault secrets enable -path=pki-ingress-dc pki

---

## Phase 8 — Import Intermediate CA

vault write pki-ingress-dc/config/ca pem_bundle=@dc-intermediate-chain.pem

---

## Phase 9 — Configure PKI URLs

vault write pki-ingress-dc/config/urls issuing_certificates="https://vault-dc:8200/v1/pki-ingress-dc/ca"

---

## Phase 10 — Policies

KV policy:
path "kv-dc/data/*" { capabilities = ["read"] }

PKI policy:
path "pki-ingress-dc/sign/role-istio-gateway-dc" { capabilities = ["update"] }

---

## Phase 11 — Roles

ESO role and cert-manager role creation

---

## Phase 12 — PKI Role

vault write pki-ingress-dc/roles/role-istio-gateway-dc allowed_domains="dc.bank.example.com"

---

## Phase 13 — Validation

vault status

---

# DR Setup

Repeat with kv-dr, pki-ingress-dr

---

# KV Flow

```mermaid
flowchart LR
    A[Vault KV] --> B[External Secrets Operator]
    B --> C[Kubernetes Secret]
    C --> D[Application Pod]
```

---

# Key Rules

- KV = secrets  
- PKI = certificates  
- ESO = KV  
- cert-manager = PKI  
- Istio CA = mTLS  

---

# Summary

Secure, production-grade Vault setup for DC/DR.
