# pushgateway

Prometheus Pushgateway in namespace `monitoring`: Deployment, ClusterIP Service `pushgateway:9091` and a ServiceMonitor with `honorLabels: true`. For batch jobs' domain metrics; job health itself comes from kube-state-metrics.

Playbooks: `ziswb.homelab_platform.monitoring` (all monitoring roles, in order)
or `ziswb.homelab_platform.pushgateway` (runs on `localhost` against the cluster in the
current kubeconfig context).

## Variables

None.
