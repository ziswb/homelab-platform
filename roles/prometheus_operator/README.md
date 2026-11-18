# prometheus_operator

The prometheus-operator (CRDs and operator) from its upstream `bundle.yaml`, vendored unchanged in `files/` except for the namespace (`monitoring` instead of `default`); the first line names the version (ADR-0012). Applied server-side with its own field manager `ansible/force` (ADR-0011). The Prometheus and Alertmanager instances are the site's own.

Playbooks: `ziswb.homelab_platform.monitoring` (all monitoring roles, in order)
or `ziswb.homelab_platform.prometheus_operator` (runs on `localhost` against the cluster in the
current kubeconfig context).

## Variables

None.
