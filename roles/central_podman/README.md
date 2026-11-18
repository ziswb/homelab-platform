# central_podman

Installs Podman on the central host (`central_server`, Rocky Linux 10) for
containers that run as rootful Podman Quadlets (ADR-0008): `podman` and
`slirp4netns`, and netavark's firewall driver pinned to `nftables`.

Since 1.2.0 it also installs a post-update smoke test (ADR-0008, amendment
2026-11-18): `central-podman-smoketest.service`, a oneshot unit that runs after
each `dnf-automatic.service` run (`central_os_updates`) and at boot. It starts a
throwaway container with a published port on the default bridge network, as
the Quadlets do, and writes node_exporter textfile metrics to
`central-podman-smoketest.prom`:

- `central_podman_smoketest_success`: 1 if the container ran, 0 if not (the
  unit then fails too, with podman's error in its journal);
- `central_podman_smoketest_last_run_timestamp_seconds`.

The alert on these (a 0, or a timestamp older than a bit more than a day)
belongs to the site's monitoring. The test needs no image: the container's
root file system is an empty directory with the host's `/usr` mounted
read-only, so nothing is pulled.

There is no playbook for it: roles that run Quadlets list it as a meta
dependency (`ziswb.homelab_platform.central_podman`), in this collection
(`central_loki`) and in a site's own roles. Ansible runs a shared dependency
once per play.

## Variables

All optional; see `meta/argument_specs.yml`.

| Variable | Default | Meaning |
|---|---|---|
| `central_podman_smoketest_enabled` | `true` | Install and enable the smoke test |
| `central_podman_smoketest_textfile_dir` | `/var/lib/node_exporter/textfile` | node_exporter textfile directory |
| `central_podman_smoketest_port` | `18080` | Host port the test container publishes on 127.0.0.1 |

## Notes

- Containers are rootful: `podman ps` as an unprivileged user shows nothing.
  Use `sudo podman ps` or `systemctl status <unit>`.
- The `nftables` pin replaced `iptables` in 0.4.1: netavark 2.0 removed the
  iptables driver, and published-port containers no longer started (ADR-0008,
  amendment 2026-11-18). On a host with an older netavark from before 0.4.1,
  apply this release before the netavark 2 upgrade or the next reboot.
- The role runs the smoke test once when it installs or changes the unit, so
  the metrics exist right away; a failing test then fails the play. Setting
  `central_podman_smoketest_enabled: false` skips the tasks but does not
  remove a unit installed earlier.
- The smoke test container runs without SELinux labelling
  (`--security-opt label=disable`): it tests networking and the runtime, not
  the policy.
