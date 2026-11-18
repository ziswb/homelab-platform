# homelab_root_ca_trust

The k3s nodes trust the private root CA behind cert-manager's `homelab-ca`
issuer (ADR-0007) through the system CA store: the certificate goes to
`/usr/local/share/ca-certificates/homelab-root-ca.crt` and
`update-ca-certificates` links it into `/etc/ssl/certs`. k3s's embedded
containerd uses the system roots, so image pulls from a registry with a
`homelab-ca` certificate verify against it. No key and no
`/etc/rancher/k3s/registries.yaml` are needed on a node.

**Run it before k3s** (`docs/bring-up.md`, step 0): containerd reads the store
only at start, so a node that trusts the CA only later fails every pull from
such a registry until k3s restarts.

Playbook: `ziswb.homelab_platform.homelab_root_ca_trust` (hosts `server`,
`agent`, with `become`).

## Variables

| Variable | Required | Meaning |
|---|---|---|
| `homelab_root_ca_trust_certificate` | yes | The root CA certificate (PEM). Resolve it in your inventory from your backup of the root CA (a vault, a password manager lookup): a fresh node needs it before the cluster exists. |
