# 0008 — Run central-host containers as Podman Quadlets

- Status: accepted; migration complete 2026-08-27 (recorded retroactively);
  amended 2026-11-18 (firewall driver, see below)
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
- The netavark firewall driver is pinned to **`nftables`** (since 0.4.1; see the
  amendment). Before that it was pinned to `iptables`, a Docker-coexistence
  measure kept as the ruleset the published ports were verified against.

## Amendment 2026-11-18: `nftables`, forced by netavark 2

Netavark 2.0 removed the iptables firewall driver; the remaining drivers are
`nftables`, `firewalld` and `none`. On the reference host, unattended package
updates installed netavark 2.1.0 (from 1.17.2) on 2026-11-17 and podman 6.1.1
the next night. Running containers were unaffected, because netavark acts only
when a container starts. At the next reboot (2026-11-18) every Quadlet that
publishes a port (PostgreSQL, Loki) failed to start with `netavark: Must provide
a valid firewall backend, got iptables`; the host-network ones (Alloy,
node-exporter) kept running. Setting the driver to `nftables` brought both back
within about five minutes.

Decision: `central_podman` pins `firewall_driver = "nftables"`. It is still a
pin rather than the distribution default, so a later default change does not
alter the host's ruleset unnoticed. The earlier rule that changing the driver is
"a deliberate, reboot-verified change" no longer applies to this switch: the
upgrade forced it, and the reboot verified it. Firewalld stays inactive on the
reference host, so netavark's table is the only ruleset; a site that runs
firewalld should consider the `firewalld` driver instead.

Follow-up, same day: unattended updates keep installing everything
(ADR-0013); no container packages are held back. Instead `central_podman`
(1.2.0) runs a **post-update smoke test**: a oneshot unit, pulled in by
`dnf-automatic.service` and ordered after it, and run at boot, starts a
throwaway container with a published port on the default bridge network. It
needs no image (the host's `/usr`, mounted read-only, on an empty root file
system), so it does not depend on a registry. The result goes to
node_exporter's textfile collector as `central_podman_smoketest_success` (0/1)
and `central_podman_smoketest_last_run_timestamp_seconds`; the alert on a
failure or a stale timestamp belongs to the site. A change like netavark 2 then
shows the morning of the update instead of at the next reboot.
