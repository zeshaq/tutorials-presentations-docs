#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env-dr.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
POLICY_DIR="${SCRIPT_DIR%/bootstrap}/policies"

vault policy write policy-eso-kv-readonly-dr "$POLICY_DIR/policy-eso-kv-readonly-dr.hcl"
vault policy write policy-cert-manager-pki-dr "$POLICY_DIR/policy-cert-manager-pki-dr.hcl"
vault policy write policy-breakglass-dr "$POLICY_DIR/policy-breakglass-dr.hcl"

vault policy list
