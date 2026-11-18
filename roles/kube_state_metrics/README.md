# kube_state_metrics

kube-state-metrics v2.20.0 in namespace `monitoring`: ClusterRole and binding, Deployment, headless Service, ServiceAccount and a ServiceMonitor (label `prometheus-enabled: "true"`). Manifests based on kube-prometheus.

The Deployment's selector carries three labels (since 2.13.0); selectors are immutable, so it stays as it is.

Playbooks: `ziswb.homelab_platform.monitoring` (all monitoring roles, in order)
or `ziswb.homelab_platform.kube_state_metrics` (runs on `localhost` against the cluster in the
current kubeconfig context).

## Variables

None.
