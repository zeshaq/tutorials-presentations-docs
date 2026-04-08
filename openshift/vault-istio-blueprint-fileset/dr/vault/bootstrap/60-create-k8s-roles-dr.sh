#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env-dr.sh"

vault write auth/kubernetes-dr/role/eso-kv-readonly-dr   bound_service_account_names="external-secrets"   bound_service_account_namespaces="external-secrets"   policies="policy-eso-kv-readonly-dr"   ttl="1h"

vault write auth/kubernetes-dr/role/cert-manager-pki-issuer-dr   bound_service_account_names="cert-manager"   bound_service_account_namespaces="cert-manager"   policies="policy-cert-manager-pki-dr"   ttl="1h"
