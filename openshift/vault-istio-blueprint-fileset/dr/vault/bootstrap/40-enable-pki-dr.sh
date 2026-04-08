#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env-dr.sh"

vault secrets enable -path=pki-ingress-dr pki || true

vault secrets tune -max-lease-ttl="$PKI_MAX_TTL" pki-ingress-dr

vault write pki-ingress-dr/config/urls   issuing_certificates="$VAULT_ADDR/v1/pki-ingress-dr/ca"   crl_distribution_points="$VAULT_ADDR/v1/pki-ingress-dr/crl"

vault write pki-ingress-dr/config/ca   pem_bundle@"$DR_INTERMEDIATE_CHAIN_FILE"

echo "Edit this script if you need a different import flow for your certificate material."
