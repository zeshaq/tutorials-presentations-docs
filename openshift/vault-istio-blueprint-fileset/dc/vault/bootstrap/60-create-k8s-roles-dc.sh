#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env-dc.sh"

vault write auth/kubernetes-dc/role/eso-kv-readonly-dc   bound_service_account_names="external-secrets"   bound_service_account_namespaces="external-secrets"   policies="policy-eso-kv-readonly-dc"   ttl="1h"

vault write auth/kubernetes-dc/role/cert-manager-pki-issuer-dc   bound_service_account_names="cert-manager"   bound_service_account_namespaces="cert-manager"   policies="policy-cert-manager-pki-dc"   ttl="1h"
