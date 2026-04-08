path "kv-dr/data/platform/*" {
  capabilities = ["read"]
}

path "kv-dr/metadata/platform/*" {
  capabilities = ["read", "list"]
}

path "kv-dr/data/apps/*" {
  capabilities = ["read"]
}

path "kv-dr/metadata/apps/*" {
  capabilities = ["read", "list"]
}
