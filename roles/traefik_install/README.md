# traefik_install

Traefik as the cluster's ingress (ADR-0014: every web UI is an IngressRoute on
`<name>.<homelab_domain>` with a `homelab-ca` certificate):

1. the Traefik CRDs, vendored verbatim from the chart (`files/crds/`, see its
   README), applied server-side before the release: Helm installs a chart's
   CRDs on first install only, never on upgrade;
2. the `traefik/traefik` chart in namespace `traefik` (`files/values.yaml`:
   HTTP redirected to HTTPS, cross-namespace IngressRoutes, the Prometheus
   metrics Service that `traefik_service_monitor` scrapes); its LoadBalancer
   Service asks MetalLB for `homelab_lb_ips.traefik`;
3. the dashboard on `https://<traefik_install_dashboard_host>/dashboard/`
   with a certificate from the `homelab-ca` ClusterIssuer.

The dashboard and API have **no authentication, by design**: they are read-only
but list every router, host name and backend, to anyone on the LAN. This is
intended for a trusted LAN
([ADR-0014](../../docs/adr/0014-service-exposure-lan-first.md), amendment);
otherwise restrict access at the network.

Needs `cert_manager` (the issuer) and `metallb` first; k3s's bundled Traefik
must be off (`--disable traefik`). Depends on `helm_preflight`.

Playbook: `ziswb.homelab_platform.traefik_install` (runs on `localhost` against
the cluster in the current kubeconfig context).

## Variables

| Variable | Required | Default | Meaning |
|---|---|---|---|
| `homelab_domain` | yes | | The site's domain. |
| `homelab_lb_ips` | yes | | LoadBalancer addresses by service; this role reads `traefik`. |
| `traefik_install_dashboard_host` | no | `traefik.{{ homelab_domain }}` | Dashboard host name. |
| `traefik_install_chart_version` | no | `43.0.0` | Chart version; re-vendor the CRDs with it. |
