#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env-dc.sh"

vault audit enable file file_path=/vault/audit/vault_audit.log || true
vault audit list
