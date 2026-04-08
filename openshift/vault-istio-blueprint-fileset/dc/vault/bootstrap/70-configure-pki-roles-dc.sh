#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env-dc.sh"

vault write pki-ingress-dc/roles/role-istio-gateway-dc   allowed_domains="dc.bank.example.com,apps.dc.bank.example.com"   allow_subdomains=true   allow_wildcard_certificates=false   max_ttl="$PKI_DEFAULT_TTL"   key_type="rsa"   key_bits=2048   server_flag=true   client_flag=false   require_cn=false

vault read pki-ingress-dc/roles/role-istio-gateway-dc
