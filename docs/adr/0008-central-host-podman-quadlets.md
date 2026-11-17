# 0008 — Run central-host containers as Podman Quadlets

- Status: accepted; migration complete 2026-08-27 (recorded retroactively)
- Date: 2026-08-06
- Originally: infrastructure ADR-0005

## Context

The central host historically ran containers under Docker (docker-compose). A
vendor product installed with its own Podman-based installer moved the host
toward Podman; systemd-native Quadlets fit a single pet server better than
compose files.

## Decision

Containers on the central host run as **rootful Podman Quadlets**
(`templates/*.container.j2` → `/etc/containers/systemd/`), with `central_podman`
as the shared meta-dependency role. In the reference site: PostgreSQL, Loki
(`central_loki`), Alloy and node-exporter. The units are templates, not static
files.

## Consequences

- Host services are managed uniformly via systemd (`systemctl status <unit>`).
- **Containers are rootful**, so they are invisible to an unprivileged
  `podman ps`: that queries the calling user's own rootless store, which on this
  host is always empty. Inspect them with `sudo podman ps` or, better,
  `systemctl status <unit>`. A plain `podman ps` returning nothing is not an
  outage (it read as one after a reboot).
- The Docker→Podman migration on the reference host is complete (no
  docker/containerd packages, no `/var/lib/docker`), so the roles carry no Docker
  coexistence guards.
- The netavark `firewall_driver = "iptables"` pin **stays**. It began as a
  Docker-coexistence measure but is now the ruleset the host's published ports are
  verified against, and firewalld is inactive there; moving to the Rocky 10
  nftables default would be a deliberate, reboot-verified change.
