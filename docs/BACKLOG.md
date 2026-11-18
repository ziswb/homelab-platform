# Backlog

Known improvements that wait for a release of their own. Role moves from the
reference site's infrastructure repository change nothing but what the move
needs (no improvements during a move, zero-diff acceptance on the consuming
side); what they find goes here.

## Open

1. **Deployed files still name the infrastructure repository's ADRs and roles.**
   Comments inside files the roles deploy as they are (`files/`, rendered
   `templates/`) refer to infrastructure ADR numbers (e.g. ADR-0029 for this
   collection's ADR-0013) and roles that are not in the collection
   (`central_node_exporter`, `central_syslog`, `node_os_updates`). Changing
   them during a move would change the deployed bytes; fix them in one release
   that accepts the restart. Found in 0.2.0 (`central_loki`, `central_os_updates`).
   0.4.0 adds `k3s_etcd_snapshot_offload` (unit and script: infrastructure
   ADR-0018 for ADR-0009, the central host by its address' last octet, an SD
   card) and `ssh_access` (sshd drop-in: an infrastructure backlog number;
   changing it reloads sshd on every host).

2. **No refresh script for vendored manifests.** ADR-0012 replaces vendored
   release YAML only through a script that downloads the release and makes the
   checked edits (`prometheus_operator`: namespace `monitoring`). The reference
   site's script is not in the collection yet. Found in 0.3.0; 0.4.0 adds
   `k3s_upgrader`'s system-upgrade-controller release (checked edit to the
   Deployment); 1.1.0 `metallb`'s release manifest and `traefik_install`'s
   CRDs (a verbatim copy from the chart, steps in its README).
4. **No Molecule scenario for `update_ubuntu`.** P8 planned one for v1.0.0
   (without the health gate), but every step after the first needs a cluster:
   the gate, the node lookup by InternalIP, cordon/drain. Testing it needs the
   tier-3 k3d cluster, or a switch that skips the Kubernetes parts (a feature).
   Found in 0.4.0.
6. **`k3s_agent` reports changed on every run.** The install script empties
   `k3s-agent.service.env` each time and the role writes `K3S_TOKEN` back, so
   that task is never idempotent (no restart follows: the file ends up the
   same). Moving the token into the agent's `config.yaml`, as `k3s_server`
   does, would fix it but changes the deployed files. Found in 0.4.0.

## Done

- **Post-update container smoke test in `central_podman`.** Decided
  2026-11-18 after the netavark 2 outage (0.4.1): package updates keep
  installing everything; instead, a oneshot unit ordered after the package
  update service and run at boot starts a throwaway container with a
  published port and writes `central_podman_smoketest_success` and a
  timestamp to node-exporter's textfile directory. The alert on it belongs to
  the site. Done in 1.2.0.

- **`central_podman`: warning on the smoke test root file system links.**
  The link task sets owner and group, and with the file module's default
  `follow: true` Ansible tries to apply them to the targets, which exist
  only inside the container: "Cannot set fs attributes on a non-existent
  symlink target" on every run. `follow: false` on that task. Found in
  1.2.0 on the reference host. Done in 1.2.1.

- **Monitoring order on a fresh cluster.** The reference site applies
  `node_exporter`, `kube_state_metrics`, `kubelet` and
  `traefik_service_monitor` before `prometheus_operator`; on a fresh cluster
  their ServiceMonitors would fail without the CRD. The bring-up doc names the
  working order; a `k3s`-level playbook bundling monitoring should enforce it.
  Found in 0.3.0. Done in 1.3.0: playbook `monitoring`.

- **Host names stand in for addresses.** `update_ubuntu` maps an inventory
  host to its Kubernetes node by InternalIP and `ssh_access`'s login test
  connects to `inventory_hostname`, so both expect the inventory host names
  to be the nodes' addresses (the reference site's inventory). Falling back
  to `ansible_host` would make them work with named hosts too. Found in 0.4.0.
  Done in 1.3.0.
