# Vault Policy Notes

## Principles
- Keep KV access and PKI access separate
- Bind roles to service accounts and namespaces
- Avoid broad wildcard write permissions
- Keep break-glass separate and audited

## Policy sets in this repo
- ESO KV read-only policy
- cert-manager PKI issue/sign policy
- break-glass read policy

## Mount assumptions
- DC: `kv-dc`, `pki-ingress-dc`, `auth/kubernetes-dc`
- DR: `kv-dr`, `pki-ingress-dr`, `auth/kubernetes-dr`
