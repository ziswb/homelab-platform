# 0013 — OS packages update themselves; reboots stay with the operator

- Status: accepted, applied 2026-10-31
- Date: 2026-10-30
- Originally: infrastructure ADR-0029

## Context

Until then only part of the hosts' packages updated by themselves:

- The k3s nodes ran Ubuntu's default unattended-upgrades: security fixes daily,
  but not the `-updates` pocket and not third-party repositories. All nodes
  started at 06:00 plus a random hour, so the three etcd members could run dpkg at
  the same time. Once, dpkg and drained pods on the servers slowed etcd until k3s
  exited on all three.
- The central host had no automatic updates at all, only `dnf-makecache.timer`.
- Nothing rebooted for a new kernel. A playbook did it when the operator ran it,
  and nothing reminded the operator.
- k3s itself is upgraded by the system-upgrade-controller (ADR-0010) and is not
  touched here.

## Decision

- **Packages install by themselves every morning, on every host.**
  - Nodes (role `node_os_updates`, not yet in this collection):
    unattended-upgrades with Ubuntu's `-updates` and the site's third-party
    repositories added. Each node gets its own fixed start: agents
    05:00/05:10/05:20, servers 05:30/06:00/06:30, so no two etcd members ever
    upgrade together. dpkg runs at low CPU and I/O priority. needrestart never
    restarts k3s.
  - Central host (`central_os_updates`): dnf-automatic installs all updates at
    04:30. Package scripts may restart their own service (e.g. sshd), as with a
    manual `dnf upgrade`.
- **Nothing reboots by itself.** `Automatic-Reboot` stays off and dnf-automatic
  has `reboot = never`. An unattended reboot of the servers would cost etcd
  quorum; a reboot of the central host pauses everything that depends on it.
- **A reminder instead:** every host writes pending updates, a pending reboot
  (with its start) and the last successful automatic run as node-exporter
  textfile metrics, hourly. Alerts: `OsRebootPending` after a week,
  `OsAutoUpdatesStale` after three days without a successful run,
  `OsUpdatesMetricsMissing`. Nodes then reboot through `update_ubuntu` (drain
  only where needed, health gate between nodes); the central host by hand.
- **k3s is watched the same way**, since nothing else would notice (the same
  script on the nodes, every 15 minutes): `K3sRestartedByItself` (systemd
  restarted k3s after it exited; restarts caused by a system-upgrade-controller
  upgrade are counted apart as `k3s_service_upgrade_restarts_total`),
  `K3sRestartPending` (a config, unit or binary changed after k3s started, e.g. a
  k3s role run that failed between writing the config and the restart; recorded
  by an `ExecStartPre` drop-in), `K3sCertificatesExpiring` (k3s renews its
  one-year certificates only at start) and `NodeCordoned` (2 hours, e.g. a failed
  upgrade job).
- **One dashboard for all of it:** every firing alert and, per host, the update,
  reboot and k3s state.

## Not now

- **kured** (cluster-coordinated reboots: lock, drain, reboot within a time
  window, held off by firing alerts). It is the natural next step for the nodes,
  but the first drain-and-reboot under new etcd metrics should be watched, not at
  night.
- **A scheduled reboot playbook**: needs an always-on control node with Ansible,
  a kubeconfig and SSH keys to every host.

## Consequences

- Packages on all hosts are at most a day behind; `update_ubuntu` mostly finds
  nothing left to install and is used for reboots.
- Board firmware packages (where the hardware has them) arrive like any other
  package and are flashed at the next boot. A waiting firmware update does not
  set `/var/run/reboot-required`: it goes along with the next reboot that a
  package asks for, and never causes one itself.
- A package that must not move goes on hold; holds stop unattended-upgrades and
  `update_ubuntu` alike.
