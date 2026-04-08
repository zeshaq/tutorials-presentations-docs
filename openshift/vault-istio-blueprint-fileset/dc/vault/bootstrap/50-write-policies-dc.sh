#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env-dc.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
POLICY_DIR="${SCRIPT_DIR%/bootstrap}/policies"

vault policy write policy-eso-kv-readonly-dc "$POLICY_DIR/policy-eso-kv-readonly-dc.hcl"
vault policy write policy-cert-manager-pki-dc "$POLICY_DIR/policy-cert-manager-pki-dc.hcl"
vault policy write policy-breakglass-dc "$POLICY_DIR/policy-breakglass-dc.hcl"

vault policy list
