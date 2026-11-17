# central_loki

Grafana Loki on the central host (`central_server`) as a rootful Podman Quadlet
(ADR-0008): `templates/loki.container.j2` becomes `loki.service`, listening on
port 3100. Single binary, filesystem storage, 30 days retention, log level
`warn`. Podman comes from the `central_podman` meta dependency.

Playbook: `ziswb.homelab_platform.central_loki`. Logs reach it from the cluster
through `alloy`.

## Variables

| Variable | Required | Meaning |
|---|---|---|
| `central_loki_dir` | yes | Directory for the config file and the data tree |
| `central_loki_owner` | yes | Owner of `central_loki_dir` |
| `central_loki_group` | yes | Group of `central_loki_dir` (mode 0750) |

## Notes

- **SELinux:** the tree is labelled `container_file_t` by policy
  (`semanage fcontext`), not by `:Z`. A `:Z` mount gets new MCS categories on
  every container start and relabels the whole tree each time, which on a large
  tree runs into systemd's start timeout. When the policy rule is new, one
  `restorecon -RF` applies it to the existing tree.
- **Missing disk:** Quadlet derives `RequiresMountsFor=` from the volume
  sources, so if `central_loki_dir` is on a disk mounted `nofail` and that disk
  is missing, the unit fails instead of starting Loki on an empty tree.
- **Stop timeout:** 60 s for Podman, 90 s for systemd; Loki flushes its index
  on shutdown, and Podman's 10 s default ended in SIGKILL mid-flush.
