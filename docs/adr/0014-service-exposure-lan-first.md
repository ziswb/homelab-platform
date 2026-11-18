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
