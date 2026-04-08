path "kv-dc/data/platform/*" {
  capabilities = ["read", "list"]
}

path "kv-dc/data/apps/*" {
  capabilities = ["read", "list"]
}

path "pki-ingress-dc/cert/*" {
  capabilities = ["read", "list"]
}

path "sys/health" {
  capabilities = ["read"]
}
