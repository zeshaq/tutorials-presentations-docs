path "kv-dc/data/platform/*" {
  capabilities = ["read"]
}

path "kv-dc/metadata/platform/*" {
  capabilities = ["read", "list"]
}

path "kv-dc/data/apps/*" {
  capabilities = ["read"]
}

path "kv-dc/metadata/apps/*" {
  capabilities = ["read", "list"]
}
