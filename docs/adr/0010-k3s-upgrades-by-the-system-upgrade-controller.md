# 0010 — k3s is upgraded by the system-upgrade-controller only

- Status: accepted 2026-10-23, applied the same day
- Date: 2026-10-23
- Originally: infrastructure ADR-0025

## Context

Two upgrade mechanisms existed side by side: the system-upgrade-controller
(`k3s_upgrader`, Plans following the upstream `stable` channel), and a manual
upgrade playbook with a `k3s_upgrade` role from k3s-ansible, driven by
`k3s_version` in the inventory. The controller did all real upgrades (the live
version was already ahead of the inventory's). Nobody knew whether the manual
playbook still ran, and its role carried the same "first server gets
cluster-init" logic that had to be defused in `k3s_server`.

## Decision

**The system-upgrade-controller is the only upgrade mechanism.** The manual
upgrade playbook and its role are gone. `k3s_version` in the inventory is only
the version the install script puts on a fresh or rebuilt node; it is kept at
what the cluster runs, so a rejoining node never starts older than its peers.

## Consequences

- Upgrades arrive when the `stable` channel moves, one control-plane node at a
  time (`concurrency: 1`, cordon), then the agents. To hold a version, set
  `version:` in the Plans instead of `channel:`.
- After an upgrade, bump `k3s_version` to match (`kubectl get nodes`).
- The role set matches k3s-ansible's `site.yml` side only.
