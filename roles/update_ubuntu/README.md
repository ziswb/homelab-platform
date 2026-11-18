# update_ubuntu

Package upgrades on the k3s nodes, one node at a time: the agents first, then
the servers. Runs on the control node against the cluster API and reaches each
node over SSH (`delegate_to`, `ansible_connection: ssh`).

Per node:

1. **Health gate**, before each node and after the last: k3s active for at
   least `update_ubuntu_k3s_settle_seconds` on every server, `/readyz/etcd`
   answering, at most `update_ubuntu_etcd_slow_warnings_max` slow-etcd lines in
   the last minute; every node Ready; every CloudNativePG cluster healthy. Each
   check retries for up to 5 minutes, then the play stops.
2. `apt` full upgrade in place (autoremove, purge, clean). A plain upgrade does
   not touch running pods (k3s and its containerd are not apt packages).
3. Only if `/var/run/reboot-required` exists: cordon, wait a minute for the
   CloudNativePG operator to move primaries away and switch the rest over to a
   ready replica on another schedulable node, drain, reboot, wait for Ready,
   uncordon (also on failure).

Automatic daily updates without reboots are a different job (ADR-0013); this
role is the manual run that also reboots.

Playbook: `ziswb.homelab_platform.update_ubuntu` (runs on `localhost` against
the cluster in the current kubeconfig context; the nodes need the SSH access
the inventory gives them, and `become`).

**Inventory host names must be the nodes' InternalIP** (as `kubectl get nodes
-o wide` shows it): the role maps each host to its Kubernetes node by that
address, and fails before touching a host it cannot map.

## Variables

None required. `update_ubuntu_k3s_settle_seconds` (120) and
`update_ubuntu_etcd_slow_warnings_max` (1) tune the health gate.
