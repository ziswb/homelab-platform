# k3s_server

A k3s server with embedded etcd, joined through `api_endpoint`. Run it with
`serial: 1` (the `ziswb.homelab_platform.k3s_cluster` playbook does): each
server waits until it has joined and is an etcd voter before the next one may
restart.

Playbooks: `ziswb.homelab_platform.k3s_cluster` (prereq, servers, agents,
upgrader, taints) or `ziswb.homelab_platform.k3s_server` (servers only).

## Variables

Required: `token` (secret), `api_endpoint`, `k3s_version`. The names are
k3s-ansible's, kept so that an inventory written for it works here. Optional
inputs and defaults are in `meta/argument_specs.yml`; the most used are
`server_config_yaml` (extra k3s config as YAML text), `extra_server_args` and
`cluster_context`.

## Trimmed copy of k3s-ansible

`prereq`, `k3s_server` and `k3s_agent` come from
[k3s-ansible](https://github.com/k3s-io/k3s-ansible) (Apache-2.0), last synced
with **5f06791 (2026-10-08)**. To sync again: clone upstream,
`git diff 5f06791 HEAD -- roles playbooks/site.yml`, and port what fits the
lists below.

### What was left out

- Every OS but Ubuntu (RHEL/Oracle/Rocky, SUSE, Debian, Raspbian, Arch), with
  firewalld, nftables, the br_netfilter and AppArmor workarounds; `prereq`
  asserts Ubuntu. The UFW tasks stay; they act only while UFW is active.
- Raspberry Pi preparation (`raspberrypi`): board-specific, a site's own play
  before `k3s_cluster` (`docs/bring-up.md`, step 0).
- airgap, openrc, IPv6 (`ansible.utils.ipwrap`), external datastore and the
  single-server path: the platform runs several servers with embedded etcd.
- The randomly generated token: `token` is required.
- `k3s_upgrade` and `playbooks/upgrade.yml`: upgrades are the
  system-upgrade-controller's job (`k3s_upgrader`, ADR-0010).
- `extra_manifests`, `registries_config_yaml`.

### Deviations from upstream

- **No cluster-init by inventory order.** Every server, the first included,
  joins through `api_endpoint`. Only `k3s_server_bootstrap_host` starts a new
  cluster, and the role refuses it when any server has etcd data or the host is
  not the first of the play. Upstream gives the first server cluster-init, so a
  plain run against a reinstalled first server starts a second, separate
  cluster.
- **Kubeconfig checks**: `k3s.yaml` must authenticate against the server's own
  API before it is fetched or copied for the user, and the fetched file against
  `api_endpoint` before it is merged into `~/.kube/config` (with a backup in
  `~/.kube/config.bak-ansible`). A stale `k3s.yaml` from a retired cluster
  generation must never become the operator's credentials.
- **Restart only on change**: upstream restarts k3s on every run. Here a server
  or agent restarts only when its `config.yaml`, unit, env file or binary
  changed, so re-running the playbook stays harmless.
- **`config.yaml` mode 0600** (it holds the token; upstream default 0644).
  Agents get their token there too (`k3s_agent_config_mode`), not in
  `k3s-agent.service.env`.
  The k3s CLI reads that file on every call, so the user's `.bashrc` gets
  `export K3S_CONFIG_FILE=/dev/null` before the completion lines (tag
  `user-shell`); without it every login prints `permission denied` and
  `k3s completion` aborts. `kubectl` as the user goes through
  `~/.kube/config`; `sudo k3s …` still reads `config.yaml`.
- `tls-san` always contains `api_endpoint`, merged as a list with
  `server_config_yaml`.

### Taken from upstream (sync of 2026-10)

- The server is configured through `/etc/rancher/k3s/config.yaml` (token,
  `server`, `tls-san`) and k3s's own install script writes the unit.
- The install script runs on every play (with the existing binary unless a new
  one is needed), so the units follow `extra_server_args`/`api_endpoint`.
- Servers run one at a time (`serial: 1`), each waiting until it has joined and
  is an etcd voter before the next one goes.
- Waiting for the control plane falls back to localhost when `api_endpoint`
  is down.
- Check mode works (`--check --diff`).
