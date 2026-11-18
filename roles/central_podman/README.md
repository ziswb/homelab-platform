# central_podman

Installs Podman on the central host (`central_server`, Rocky Linux 10) for
containers that run as rootful Podman Quadlets (ADR-0008): `podman` and
`slirp4netns`, and netavark's firewall driver pinned to `nftables`.

There is no playbook for it: roles that run Quadlets list it as a meta
dependency (`ziswb.homelab_platform.central_podman`), in this collection
(`central_loki`) and in a site's own roles. Ansible runs a shared dependency
once per play.

## Variables

None.

## Notes

- Containers are rootful: `podman ps` as an unprivileged user shows nothing.
  Use `sudo podman ps` or `systemctl status <unit>`.
- The `nftables` pin replaced `iptables` in 0.4.1: netavark 2.0 removed the
  iptables driver, and published-port containers no longer started (ADR-0008,
  amendment 2026-11-18). On a host with an older netavark from before 0.4.1,
  apply this release before the netavark 2 upgrade or the next reboot.
