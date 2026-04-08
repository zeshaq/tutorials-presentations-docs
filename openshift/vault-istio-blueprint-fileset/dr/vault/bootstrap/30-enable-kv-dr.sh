#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env-dr.sh"

vault secrets enable -path=kv-dr -version=2 kv || true

vault kv put kv-dr/platform/example appConfig="replace-me" sharedSecret="replace-me"
vault kv put kv-dr/apps/payments/prod username="payments-user" password="replace-me"
