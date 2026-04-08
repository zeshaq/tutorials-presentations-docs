#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env-dc.sh"

vault secrets enable -path=kv-dc -version=2 kv || true

vault kv put kv-dc/platform/example appConfig="replace-me" sharedSecret="replace-me"
vault kv put kv-dc/apps/payments/prod username="payments-user" password="replace-me"
