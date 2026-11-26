# Changelog

All notable changes to this collection. Versions follow [SemVer](https://semver.org/):
a new required variable, a renamed variable or a changed inventory group is a major
release. Each release is a git tag `vX.Y.Z`.

## Unreleased

## 1.7.6

Deployed resources unchanged: the same charts at the same versions.

- Fixed: `cert_manager` and `traefik_install` install their chart straight
  from the repository URL (`chart_repo_url`), as `cnpg_operator` does, no
  longer with `helm repo add` and `helm repo update`. Under `--check` the add
  only pretended, so the update failed with "no repositories found" wherever
  the repository was never added: a fresh workstation, a deployer's dry run.
  A repository added by earlier runs stays and is no longer used.

## 1.7.5

Dependency updates, prepared by CI from the merged Renovate PRs (ADR-0016).

- Updated: grafana/alloy Docker tag to v1.22.0 (#14)
- Updated: Helm release traefik to v42.4.3 (#15)

## 1.7.4

Dependency updates, prepared by CI from the merged Renovate PRs (ADR-0016).

- Updated: prometheus-operator/prometheus-operator to v0.95.2 (#12)
- Updated: prom/pushgateway Docker tag to v1.11.5 (#11)
- Updated: quay.io/prometheus/node-exporter Docker tag to v1.13.1 (#9)
- Updated: Helm release cloudnative-pg to v0.29.2 (#10)
- Fixed (docs): 1.7.3's note was wrong. CI and Gitleaks on a commit that
  `revendor.yml` or `prepare-release.yml` pushes wait for the maintainer's
  approval on the PR whatever the approval policy (ADR-0016, amended again).

## 1.7.3

No deployed file changes; applying it changes nothing on the hosts.

- Fixed: the commits `revendor.yml` and `prepare-release.yml` push run CI and
  Gitleaks on their PR by themselves; the extra dispatched runs are gone. This
  needs the repository's approval policy for outside contributors at
  first-time contributors (ADR-0016, amended).
- Fixed: the release PR updates the README's install example to the new tag,
  and its CHANGELOG lines no longer read "Updated: Update …".

## 1.7.2

Dependency updates, prepared by CI from the merged Renovate PRs (ADR-0016).

- Updated: Update dependency rancher/system-upgrade-controller to v0.21.1 (#4)
- Updated: Update docker.io/grafana/loki Docker tag to v3.7.10 (#5)

## 1.7.1

No deployed file changes; applying it changes nothing on the hosts.

- Added: Renovate (`renovate.json5`, ADR-0016) opens a PR per upstream update of
  the role pins and the vendored components. Each pin carries a marker on the
  line above it; in templates a Jinja comment, so every rendered file stays
  byte-identical.
- Added: `revendor.yml` / `scripts/revendor-pr.sh` re-vendor a component on its
  Renovate PR with `refresh-vendored.sh`; `prepare-release.yml` /
  `scripts/prepare-release.sh` open a release PR after Renovate merges. Neither
  tags: the maintainer signs with `sign-release.sh` (ADR-0004).
- CI and Gitleaks can be dispatched (`workflow_dispatch`), for branches the
  two workflows push.

## 1.7.0

Deployed files change only where `alloy_extra_log_files` is set; with its
default, applying it changes nothing on the hosts. The first signed tag.

- Added: `alloy` takes `alloy_extra_log_files` (default `[]`), log files on the
  node to ship besides the pod logs, each `{path, job}`, e.g. the API server's
  audit log. With the default the rendered manifests are unchanged.
- Added: `scripts/sign-release.sh vX.Y.Z`: checks a release (clean tree, on
  `main`, version and CHANGELOG, vendored files reproduced byte for byte by
  `refresh-vendored.sh`, the diff since the last signed tag) and signs its
  tag. From this release on, tags are signed (ADR-0004, amended).

## 1.6.0

No deployed file changes; applying it changes nothing on the hosts.

- Tested: `update_ubuntu`'s health gate script is now a template
  (`templates/cluster_health_gate.sh.j2`), still rendered and run inline on
  each server. The Molecule scenario runs it against stub `systemctl`, `k3s`
  and `journalctl`: every check fails the gate on its own (backlog 11).
- Docs: the `k3s_version` example in `examples/inventory` and in
  `k3s_server`'s argument spec is v1.36.5+k3s1, the tested version
  (backlog 12).
- Changed: the collection dependencies are bounded to the major CI tests:
  `community.general` 14.x, `ansible.posix` 2.x (were unbounded). ADR-0015
  records how dependencies are pinned.
- Docs: the Loki port and the Traefik dashboard have no authentication by
  design (LAN-only; ADR-0014 amendment), now stated in both READMEs. README:
  role table, overview diagram, how the collection relates to the private site
  repository.

## 1.5.1

No deployed file changes; applying it changes nothing on the hosts. On the
control node, the first `k3s_server` run sets the fetched kubeconfig to 0600.
The next `update_ubuntu` run waits for every server's k3s settle time.

- Fixed: `update_ubuntu`'s health gate only enforced its last check (slow
  etcd warnings). The script had no `set -e`, so k3s being inactive, a k3s
  that had not been running for `update_ubuntu_k3s_settle_seconds`, or a
  failing `/readyz/etcd` passed the gate. Now every check must pass, as the
  README and ADR-0013 describe. A server that just restarted k3s now holds
  the play until the settle time is over.
- Security (see [docs/SECURITY-FINDINGS.md](docs/SECURITY-FINDINGS.md)):
  `k3s_server`'s tasks that build the server config (it holds the cluster
  token) are `no_log`, so `-v` or an error no longer prints the token. The
  kubeconfig fetched to the control node is set to 0600 on every run, also
  when it was fetched by an earlier release (it holds the cluster-admin key;
  it used to follow the control node's umask).
- Fixed: `k3s_server` under `--check` failed on a server without k3s (new
  or rebuilt): the kubeconfig checks waited a minute for a `k3s.yaml` that
  only the skipped install would create. They and the copies after them are
  now skipped there.
- Fixed: `k3s_server` with `user_kubectl` (the default) failed with an
  undefined `ansible_user` when the inventory does not set it, after k3s
  had already restarted on the first server. The step is skipped then, like
  the `.bashrc` lines before it.

## 1.5.0

New optional feature; with its default nothing changes on the hosts.

- New `k3s_registry_mirrors` (`k3s_server`, `k3s_agent`, default `{}`):
  containerd registry mirrors, written as the `mirrors` key of
  `/etc/rancher/k3s/registries.yaml`. k3s restarts when the file
  changes (servers one at a time). Empty writes no file and leaves an
  existing one alone. containerd keeps the upstream as fallback, so a mirror
  that is down or answers 404 does not stop a pull. README "Registry
  mirrors" in `k3s_server`; tested end to end with k3s v1.36 and a zot
  pull-through cache in Docker (prefix rewrite, cache hits, fallback with
  the cache stopped).
- New Molecule scenario `k3s_registries`: the rendered file from both roles
  (identical, idempotent) and an untouched hand-made file with no mirrors.
  The writing task is in its own file (`tasks/registries.yml`) in both roles.

## 1.4.2

No deployed file changes; applying it changes nothing on the hosts.

- Fixed: `update_ubuntu` failed with "No first item, sequence was empty"
  when a host had no Kubernetes node with its address as InternalIP, instead
  of its own message naming the host and address (since 0.4.0). The
  outcome was the same (the play stopped before touching the host).
- New Molecule scenario `update_ubuntu` (docs/BACKLOG.md 4): tests the node
  lookup by InternalIP and the choice of the CloudNativePG switchover target
  on fixture API results. Both moved into task files of their own
  (`tasks/node_name.yml`, `tasks/cnpg_target.yml`), imported where they
  were, so the role runs the same tasks. The health gate, the
  upgrade and the drain still need a cluster and stay untested.
- New `scripts/refresh-vendored.sh` (not part of the built collection): the
  one way to replace vendored upstream YAML (ADR-0012), for MetalLB, the
  prometheus-operator bundle, the system-upgrade-controller and Traefik's
  CRDs. It also updates every place that names the version (NOTICE, and the
  Traefik chart version) (docs/BACKLOG.md 2). Run at the vendored versions,
  it reproduces the committed files byte for byte.

## 1.4.1

- Fixed: `ssh_access`'s fresh login (1.3.0, 1.4.0) connected to the control
  machine itself when a host had no `ansible_host`: the task runs delegated
  to localhost, where `ansible_host` is the delegate's. The login test failed
  and the role rolled the host back. Address and port are now taken from the
  host's own variables before the delegated task (the port had the same flaw
  since 0.4.0, unnoticed with port 22). Molecule asserts the login target.

## 1.4.0

Changes deployed files. Applying it restarts `k3s-agent` on every agent
(running pods stay), Loki and the dnf-automatic timer on the central host,
reloads sshd on every host `ssh_access` runs on, and reloads systemd on the
servers for the etcd snapshot copy unit.

- `k3s_agent`: the token goes into `/etc/rancher/k3s/config.yaml` (mode
  0600, new optional variable `k3s_agent_config_mode`), as on the servers,
  instead of `k3s-agent.service.env`. The install script empties the env file
  on every run, so writing the token back made the role report a change every
  time (docs/BACKLOG.md 6). `agent_config_yaml` is now merged over the token
  and rendered as YAML (was copied verbatim, mode 0644). The role asserts
  that `token` is set.
- Comments in deployed files name this collection's ADRs (ADR-0009,
  ADR-0013) instead of the reference site's, and no longer refer to roles
  outside the collection or to the reference site's hardware
  (docs/BACKLOG.md 1): `central_loki`, `central_os_updates`,
  `k3s_etcd_snapshot_offload`, `ssh_access`.

## 1.3.0

- New playbook `ziswb.homelab_platform.monitoring`: the monitoring roles in
  the order a fresh cluster needs, `prometheus_operator` first (its CRDs),
  then `node_exporter`, `kube_state_metrics`, `kubelet`,
  `traefik_service_monitor`, `pushgateway` (docs/BACKLOG.md 3). The component
  playbooks stay.
- `update_ubuntu` and `ssh_access` use a host's `ansible_host` when it is set
  and fall back to the inventory host name (docs/BACKLOG.md 5):
  `update_ubuntu` maps a host to its Kubernetes node by that address,
  `ssh_access`'s fresh login connects to it. Inventories that name hosts by
  their address and set no `ansible_host` behave as before.

## 1.2.1

- Fixed: `central_podman` warned "Cannot set fs attributes on a non-existent
  symlink target" on every run after the first: the task linking the smoke
  test's root file system set owner and group through the links, whose
  targets exist only inside the container. It sets `follow: false` now
  (docs/BACKLOG.md 8). Nothing on the host changes.

## 1.2.0

- `central_podman`: post-update smoke test (docs/BACKLOG.md 7, ADR-0008
  follow-up to the 2026-11-18 amendment). A oneshot unit,
  `central-podman-smoketest.service`, runs after each dnf-automatic run and at
  boot, starts a throwaway container with a published port (no image, nothing
  pulled) and writes `central_podman_smoketest_success` and
  `central_podman_smoketest_last_run_timestamp_seconds` to node_exporter's
  textfile directory. On by default; new optional variables
  `central_podman_smoketest_enabled`, `central_podman_smoketest_textfile_dir`,
  `central_podman_smoketest_port`. The role runs the test once when the unit
  is installed, and fails the play if the test fails. The site adds the alert.
- `central_podman`: the argument spec description named the old `iptables`
  pin; it says `nftables` now.
- Molecule `central_podman`: runs the smoke test unit, then sets the old
  `iptables` pin again and expects the unit to fail and report 0. A prepare
  step selects vfs storage through a `storage.conf.d` drop-in (podman 6's
  vendor drop-in overrides `/etc/containers/storage.conf`).

## 1.1.0

The three roles a cluster needs first, deferred from 1.0.0 for their
hostname and secret rework.

- Added `metallb`, `traefik_install`, `homelab_root_ca_trust`, with argument
  specs, READMEs and one playbook each.
- `metallb`: `metallb_addresses` (the pool) is required.
- `traefik_install`: `homelab_domain` and `homelab_lb_ips` (platform
  variables, key `traefik`) are required; the dashboard host is
  `traefik_install_dashboard_host`, default `traefik.{{ homelab_domain }}`.
  Internal `traefik_chart_url` renamed `traefik_install_chart_url`.
- `homelab_root_ca_trust`: the certificate arrives as
  `homelab_root_ca_trust_certificate` (required); the role no longer looks it
  up itself (ADR-0002).
- ADR-0014 (LAN-first exposure through Traefik, Tailscale selectively), moved
  from the reference site.
- `docs/bring-up.md`: the root CA trust in step 0, MetalLB and Traefik after
  `cert_manager`. NOTICE lists MetalLB and the Traefik chart.
- Molecule scenario for `homelab_root_ca_trust` (Ubuntu 24.04).

## 1.0.0

The first complete release: the 21 roles of the reference platform's
v1.0.0 scope, each with argument specs, a README and (except the meta
dependencies `helm_preflight` and `central_podman`) a playbook. From here on
the argument specs, the inventory groups `server`, `agent`, `central_server`
and the platform variables in `docs/variables.md` are the SemVer contract.

- No role changes since 0.4.1.
- README and `docs/bring-up.md`: what 1.0 covers and what is still the site's
  own until 1.1.0 (MetalLB, the Traefik install, trusting the private root CA
  on the nodes).
- Known gap (docs/BACKLOG.md 4): `update_ubuntu` has no Molecule scenario; it
  needs a cluster for everything after the package upgrade.

## 0.4.1

- Fixed: `central_podman` pinned netavark's firewall driver to `iptables`,
  which netavark 2.0 removed. After the netavark 2 upgrade (Rocky Linux 10.3),
  every Quadlet with a published port (`central_loki`, a site's PostgreSQL)
  failed to start at the next reboot with "Must provide a valid firewall
  backend, got iptables". The pin is now `nftables` (ADR-0008 amended). Apply
  this release to a central host before it reboots onto netavark 2; a host
  already on netavark 2 with `iptables` set fails on its next container start.
- Molecule `central_podman` now sets up a container with a published port
  (`podman init`), which fails with the old pin on the test image's netavark
  2.1.0.

## 0.4.0

Third batch: the k3s nodes.

- Added `prereq`, `k3s_server`, `k3s_agent` (trimmed copy of k3s-ansible),
  `k3s_upgrader`, `k3s_node_taints`, `k3s_etcd_snapshot_offload`,
  `update_ubuntu`, `ssh_access`, with argument specs, READMEs and one playbook
  each, plus `ziswb.homelab_platform.k3s_cluster` (prereq, servers one at a
  time, agents, upgrader, node taints).
- `k3s_server`/`k3s_agent`: `token`, `api_endpoint` and `k3s_version` are
  required; k3s-ansible's variable names are kept.
- `k3s_etcd_snapshot_offload`: `homelab_nfs_server` and `homelab_nfs_paths`
  are required (platform variables).
- `ssh_access`: `ssh_access_user` and `ssh_access_authorized_keys` are
  required (no defaults).
- `update_ubuntu`: internal variables renamed with the role's prefix (lint).
- Molecule scenarios for `prereq` (Ubuntu 24.04) and `ssh_access` (Ubuntu
  24.04 and Rocky Linux 10).
- NOTICE lists the third-party material: k3s-ansible, system-upgrade-controller
  and prometheus-operator.

## 0.3.0

Second batch: the cluster add-ons.

- Added `helm_preflight` (meta dependency), `cert_manager`, `cnpg_operator`,
  `prometheus_operator`, `kube_state_metrics`, `pushgateway`,
  `node_exporter`, `kubelet`, `traefik_service_monitor`, `alloy`, with
  argument specs, READMEs and one playbook each (except `helm_preflight`).
- `alloy`: `homelab_loki_url` is required (platform variable).
- `helm_preflight`: `helm_binary`, `helm_version_min`, `helm_version_max`,
  `helm_diff_version_min` have defaults (`helm`, 4.2.0, 5.0.0, 3.14.0).
- Internal variables renamed with their role's prefix:
  `cert_manager_chart_url`, `cnpg_operator_chart_url`,
  `cnpg_operator_namespace`.
- `docs/bring-up.md`: `prometheus_operator` before the roles that create
  ServiceMonitors.

## 0.2.0

First batch of roles moved in from the reference site's infrastructure
repository: the central host.

- Added `central_podman`, `central_loki`, `central_os_updates`, with argument
  specs, READMEs and the playbooks `ziswb.homelab_platform.central_loki` and
  `ziswb.homelab_platform.central_os_updates`.
- `central_loki`: `central_loki_dir`, `central_loki_owner` and
  `central_loki_group` are required (site values, no defaults).
- Fixed: `central_podman` failed on a fresh Rocky 10 host, where installing
  podman does not create `/etc/containers/containers.conf.d`.
- Molecule scenario for `central_podman` (Rocky Linux 10).

## 0.1.0 (not tagged)

- Collection skeleton: metadata, leak guard, CI (lint, structure, syntax check,
  Molecule), example inventory, variable vocabulary and bring-up order docs.
