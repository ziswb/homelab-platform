# node_exporter

node-exporter on every node (`tolerations: Exists`) in namespace `monitoring`, listening on 127.0.0.1 and exposed on port 9100 through kube-rbac-proxy (TLS, bearer token). Its textfile collector reads `/var/lib/node-exporter-textfile` on the host, so a site can add metrics there (e.g. disk health); the directory may be missing.

Playbooks: `ziswb.homelab_platform.monitoring` (all monitoring roles, in order)
or `ziswb.homelab_platform.node_exporter` (runs on `localhost` against the cluster in the
current kubeconfig context).

## Variables

None.
