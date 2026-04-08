#!/usr/bin/env bash
set -euo pipefail

export VAULT_ADDR="https://vault-dc.bank.example.com:8200"
export VAULT_TOKEN="REPLACE_ME_BOOTSTRAP_TOKEN"

export K8S_HOST="https://api.dc.bank.example.com:6443"
export K8S_CA_CERT_FILE="./cluster-ca-dc.crt"
export TOKEN_REVIEW_JWT_FILE="./token-review-jwt-dc.jwt"

export DC_INTERMEDIATE_CERT_FILE="./dc-intermediate.crt"
export DC_INTERMEDIATE_KEY_FILE="./dc-intermediate.key"
export DC_INTERMEDIATE_CHAIN_FILE="./dc-intermediate-chain.pem"

export PKI_DEFAULT_TTL="720h"
export PKI_MAX_TTL="8760h"

echo "DC environment loaded"
