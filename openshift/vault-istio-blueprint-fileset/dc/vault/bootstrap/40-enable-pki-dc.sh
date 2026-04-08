#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env-dc.sh"

vault secrets enable -path=pki-ingress-dc pki || true

vault secrets tune -max-lease-ttl="$PKI_MAX_TTL" pki-ingress-dc

vault write pki-ingress-dc/config/urls   issuing_certificates="$VAULT_ADDR/v1/pki-ingress-dc/ca"   crl_distribution_points="$VAULT_ADDR/v1/pki-ingress-dc/crl"

vault write pki-ingress-dc/config/ca   pem_bundle@"$DC_INTERMEDIATE_CHAIN_FILE"

echo "Edit this script if you need a different import flow for your certificate material."
