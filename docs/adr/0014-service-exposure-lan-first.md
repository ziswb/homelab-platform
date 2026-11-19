# 0014 — Expose services LAN-first, Tailscale selectively

- Status: accepted (recorded retroactively; decision visible in the code)
- Date: 2026-08-06
- Originally: infrastructure ADR-0003

## Context

All services run on a private LAN with no port forwarding. Some services are
useful away from home (photos, a dashboard, home automation, media); others are
admin surfaces that should not be one stolen laptop away from the internet.

## Decision

- Default: every web UI is exposed **LAN-only** via a Traefik IngressRoute on
  `<name>.<homelab_domain>` with a `homelab-ca` certificate (ADR-0007) and an
  HTTP→HTTPS redirect (`traefik_install`).
- Services that need remote access additionally get a **Tailscale ingress**
  (`<name>.<tailnet>.ts.net` via the Tailscale Kubernetes operator). The
  operator and the ingresses are the site's own; the collection ships no
  Tailscale role.
- Tailscale exposure is deliberately *removed* where it existed and is not
  needed (admin surfaces).

## Consequences

- Adding a workload means: IngressRoute + Certificate always; Tailscale ingress
  only with a reason.
- Open: the criterion for "gets Tailscale" is inferred from the current set
  ("family-facing / needed on the road"); it still has to be stated.
- Services that bypass the model (a raw MetalLB address, plain HTTP, their own
  TLS) are deviations to resolve, not alternatives.

## Amendment 2026-11-19: unauthenticated admin surfaces on the LAN

The LAN is the trust boundary. Two platform surfaces have no authentication on
purpose, are LAN-only and never get a Tailscale ingress:

- the Traefik dashboard and API (`traefik_install`): HTTPS with a `homelab-ca`
  certificate, read-only, but it lists every router, host name and backend;
- Loki on the central host (`central_loki`): plain HTTP on port 3100 on every
  interface; whoever reaches it can read and push logs and file delete requests.

They are not deviations in the sense above. A site whose LAN is not trusted
restricts them at the network (firewall, VLAN). An optional access restriction
in the roles may come later; it would not change the default.
