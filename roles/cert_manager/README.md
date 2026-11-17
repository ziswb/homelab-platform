# cert_manager

cert-manager from the jetstack chart (namespace `cert-manager`; CRDs installed
and kept when the release is removed) and a private CA chain (ADR-0007):

1. ClusterIssuer `selfsigned-bootstrap`;
2. Certificate `homelab-root-ca` (CN "Homelab Root CA", ECDSA P-256, 10 years,
   renewed a year early) in Secret `cert-manager/homelab-root-ca-secret`;
3. ClusterIssuer `homelab-ca` backed by that Secret, for every Certificate.

Playbook: `ziswb.homelab_platform.cert_manager` (on `localhost`, against the
current kubeconfig context). Depends on `helm_preflight`.

## Variables

| Variable | Default | Meaning |
|---|---|---|
| `cert_manager_chart_version` | `v1.21.3` | chart version |
| `helm_binary` | `helm` | from `helm_preflight` |

## Notes

- Back up `homelab-root-ca-secret` outside the cluster: without it, losing the
  cluster means a new CA that every client has to trust again.
- Clients (and the k3s nodes, before k3s starts) must trust the root CA.
