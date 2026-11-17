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

2. **No refresh script for vendored manifests.** ADR-0012 replaces vendored
   release YAML only through a script that downloads the release and makes the
   checked edits (`prometheus_operator`: namespace `monitoring`). The reference
   site's script is not in the collection yet. Found in 0.3.0.
3. **Monitoring order on a fresh cluster.** The reference site applies
   `node_exporter`, `kube_state_metrics`, `kubelet` and
   `traefik_service_monitor` before `prometheus_operator`; on a fresh cluster
   their ServiceMonitors would fail without the CRD. The bring-up doc names the
   working order; a `k3s`-level playbook bundling monitoring should enforce it.
   Found in 0.3.0.

## Done
