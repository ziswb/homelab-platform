# Variables

The platform's shared vocabulary and the rules every role's inputs follow. Each
role documents its own inputs in `roles/<role>/meta/argument_specs.yml` (checked
before the role runs) and its README; this page lists the variables that more
than one role reads.

## Rules

- **Site values have no defaults.** Anything that differs between two homelabs
  (domain, addresses, paths on a file server, user and group IDs) is a required
  variable. A role that is missing one fails at its argument spec check, before
  it changes anything.
- **Non-site values have defaults:** versions, timeouts, feature flags.
- **Secrets arrive as variables.** Roles never look secrets up; your inventory
  resolves them (Ansible Vault, a password manager lookup, ...). Lookups in
  `group_vars` are templated lazily, only when a role reads the variable. Roles
  use secrets with `no_log: true`.
- **Names:** `homelab_*` for the platform-wide variables below; `<role>_*` for a
  role's own inputs; `k3s_*` for an input both k3s roles read (e.g.
  `k3s_registry_mirrors`), apart from k3s-ansible's own names below. List-like inputs a site extends are `<role>_extra_*`;
  optional features are switched with `<role>_*_enabled`.
- **Host names** are variables defaulting to `<service>.{{ homelab_domain }}`.
- **Compatibility:** a new required variable, a renamed variable or a changed
  inventory group is a major release (see [CHANGELOG](../CHANGELOG.md)).

## Inventory groups

| Group | Hosts |
|---|---|
| `server` | k3s server nodes (control plane, etcd) |
| `agent` | k3s agent nodes |
| `central_server` | the central host (file server, logs, databases) |

The names are fixed; the roles and playbooks refer to them.

## Platform variables

| Variable | Type | Required | Used by | Meaning |
|---|---|---|---|---|
| `homelab_domain` | str | yes | host name defaults (`traefik_install`) | The site's DNS domain, e.g. `home.arpa` or `lab.example.com`. |
| `homelab_lb_ips` | dict | yes | `traefik_install` | LoadBalancer addresses by service, from the MetalLB pool, e.g. `{traefik: 192.0.2.10}`; each role names the keys it reads, a site adds its own. |
| `homelab_loki_url` | str | yes | `alloy` | Base URL of Loki (`central_loki` listens on 3100), e.g. `http://loki.example.com:3100`. |
| `homelab_nfs_server` | str | yes | `k3s_etcd_snapshot_offload` | Address of the NFS server on the central host. |
| `homelab_nfs_paths` | dict | yes | `k3s_etcd_snapshot_offload` | Exported paths by purpose, e.g. `{etcd_snapshots: /srv/nfs/etcd-snapshots}`; each role names the keys it reads. |

## k3s variables

The k3s roles (`prereq`, `k3s_server`, `k3s_agent`) are a trimmed copy of
[k3s-ansible](https://github.com/k3s-io/k3s-ansible) and keep its variable
names, so an inventory written for it works here. The shared ones:

| Variable | Type | Required | Used by | Meaning |
|---|---|---|---|---|
| `token` | str (secret) | yes | `k3s_server`, `k3s_agent` | The cluster token. |
| `api_endpoint` | str | yes | `k3s_server`, `k3s_agent` | Address the nodes join through and the kubeconfig points to (a load balancer in front of the servers). |
| `k3s_version` | str | yes | `k3s_server`, `k3s_agent` | k3s version a new node gets; upgrades are `k3s_upgrader`'s job. |
| `api_port` | int | no (6443) | `prereq`, `k3s_server`, `k3s_agent` | Port of the Kubernetes API. |
| `server_config_yaml` | str | no | `prereq`, `k3s_server` | Extra k3s server config (YAML text). |
| `k3s_registry_mirrors` | dict | no (`{}`) | `k3s_server`, `k3s_agent` | containerd registry mirrors, written to `registries.yaml` (not a k3s-ansible name; `k3s_server` README "Registry mirrors"). |

Rows are added with the roles that read them; each role move decides the
public form of the variables it needs.
