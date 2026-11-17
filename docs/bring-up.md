# Bring-up order

The order in which a new site applies the collection's playbooks. Each step
depends on the ones before it. The playbooks are `ziswb.homelab_platform.<name>`
and run standalone; `k3s_cluster` bundles the k3s install.

> **Status:** the playbooks arrive with their roles until v1.0.0. Available
> since 0.2.0: `central_loki`, `central_os_updates`.

## 0. Before: your site's own preparation

Anything your hardware or network needs before k3s starts, as your own play:
for example board-specific tuning, or trusting a private root CA. Run it before
step 2: k3s' containerd reads the system CA store once at start, so a node that
trusts the CA only later fails every pull from a registry with that CA until k3s
restarts.

## 1. Central host (`central_server`)

The cluster reaches logs and other shared services through it, so it comes
first.

1. `central_loki`: Loki as a Podman Quadlet (installs Podman through the
   `central_podman` dependency).
2. `central_os_updates`: automatic package updates, no reboots.
3. `ssh_access`: authorized keys, no password or root login.

## 2. k3s cluster (`server`, `agent`)

`k3s_cluster` runs, in this order:

1. `prereq` on all nodes;
2. `k3s_server`, one server at a time (each joins etcd as a voter before the
   next one restarts);
3. `k3s_agent`;
4. `k3s_upgrader` (system-upgrade-controller) and `k3s_node_taints`, from the
   control node against the API.

## 3. Cluster services

1. `k3s_etcd_snapshot_offload`: etcd snapshots to the central host.
2. `cert_manager`.
3. Monitoring: `node_exporter`, `kube_state_metrics`, `kubelet`,
   `traefik_service_monitor`, `prometheus_operator`, `pushgateway` (Helm
   prerequisites are checked by `helm_preflight`, a dependency).
4. `cnpg_operator`: the CloudNativePG operator (database clusters are your own).
5. `alloy`: log shipping to `central_loki`.
6. `ssh_access` on the nodes.

## Maintenance (not part of bring-up)

- `update_ubuntu`: OS updates on the nodes, one at a time.
