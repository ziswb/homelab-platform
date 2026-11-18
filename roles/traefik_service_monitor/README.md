# traefik_service_monitor

A ServiceMonitor in namespace `monitoring` for Traefik's metrics Service in namespace `traefik` (labels `app.kubernetes.io/name: traefik`, `app.kubernetes.io/component: metrics`).

Playbooks: `ziswb.homelab_platform.monitoring` (all monitoring roles, in order)
or `ziswb.homelab_platform.traefik_service_monitor` (runs on `localhost` against the cluster in the
current kubeconfig context).

## Variables

None.
