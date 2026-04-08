#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env-dr.sh"

vault write pki-ingress-dr/roles/role-istio-gateway-dr   allowed_domains="dr.bank.example.com,apps.dr.bank.example.com"   allow_subdomains=true   allow_wildcard_certificates=false   max_ttl="$PKI_DEFAULT_TTL"   key_type="rsa"   key_bits=2048   server_flag=true   client_flag=false   require_cn=false

vault read pki-ingress-dr/roles/role-istio-gateway-dr
