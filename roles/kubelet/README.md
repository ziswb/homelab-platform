# kubelet

A ServiceMonitor in namespace `monitoring` for the kubelet's `/metrics`, `/metrics/cadvisor` and `/metrics/probes` endpoints. k3s serves the API server's, scheduler's and controllers' metrics on the same endpoint; their latency-histogram buckets are dropped (the largest series sets, unused), `_sum` and `_count` stay.

Playbook: `ziswb.homelab_platform.kubelet` (runs on `localhost` against the
cluster in the current kubeconfig context).

## Variables

None.
