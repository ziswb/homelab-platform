# Changelog

All notable changes to this collection. Versions follow [SemVer](https://semver.org/):
a new required variable, a renamed variable or a changed inventory group is a major
release. Each release is a git tag `vX.Y.Z`.

## Unreleased

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

## 0.1.0

- Collection skeleton: metadata, leak guard, CI (lint, structure, syntax check,
  Molecule), example inventory, variable vocabulary and bring-up order docs.
