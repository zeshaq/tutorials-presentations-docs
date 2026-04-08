#!/usr/bin/env bash
set -euo pipefail

export VAULT_ADDR="https://vault-dr.bank.example.com:8200"
export VAULT_TOKEN="REPLACE_ME_BOOTSTRAP_TOKEN"

export K8S_HOST="https://api.dr.bank.example.com:6443"
export K8S_CA_CERT_FILE="./cluster-ca-dr.crt"
export TOKEN_REVIEW_JWT_FILE="./token-review-jwt-dr.jwt"

export DR_INTERMEDIATE_CERT_FILE="./dr-intermediate.crt"
export DR_INTERMEDIATE_KEY_FILE="./dr-intermediate.key"
export DR_INTERMEDIATE_CHAIN_FILE="./dr-intermediate-chain.pem"

export PKI_DEFAULT_TTL="720h"
export PKI_MAX_TTL="8760h"

echo "DR environment loaded"
