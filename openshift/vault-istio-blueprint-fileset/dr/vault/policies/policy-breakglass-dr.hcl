path "kv-dr/data/platform/*" {
  capabilities = ["read", "list"]
}

path "kv-dr/data/apps/*" {
  capabilities = ["read", "list"]
}

path "pki-ingress-dr/cert/*" {
  capabilities = ["read", "list"]
}

path "sys/health" {
  capabilities = ["read"]
}
