# central_podman

Installs Podman on the central host (`central_server`, Rocky Linux 10) for
containers that run as rootful Podman Quadlets (ADR-0008): `podman` and
`slirp4netns`, and netavark's firewall driver pinned to `iptables`.

There is no playbook for it: roles that run Quadlets list it as a meta
dependency (`ziswb.homelab_platform.central_podman`), in this collection
(`central_loki`) and in a site's own roles. Ansible runs a shared dependency
once per play.

## Variables

None.

## Notes

- Containers are rootful: `podman ps` as an unprivileged user shows nothing.
  Use `sudo podman ps` or `systemctl status <unit>`.
- The iptables pin is deliberate (ADR-0008); moving to the nftables default is
  a reboot-verified change, not a cleanup.
