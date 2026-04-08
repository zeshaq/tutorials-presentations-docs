#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env-dr.sh"

vault auth enable -path=kubernetes-dr kubernetes || true

vault write auth/kubernetes-dr/config   kubernetes_host="$K8S_HOST"   kubernetes_ca_cert=@"$K8S_CA_CERT_FILE"   token_reviewer_jwt="$(cat "$TOKEN_REVIEW_JWT_FILE")"

vault auth list
