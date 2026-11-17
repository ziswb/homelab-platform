# central_os_updates

Automatic package updates on the central host (`central_server`, Rocky Linux
10), without reboots (ADR-0013):

- dnf-automatic installs every available update (or only security errata) each
  morning at a fixed time, `reboot = never`, output to the journal;
- a systemd drop-in records each successful run;
- an hourly script writes node_exporter textfile metrics with the same names
  the k3s nodes use: `os_reboot_required`, `os_reboot_required_since_timestamp_seconds`,
  `os_upgrades_pending`, `os_security_upgrades_pending`,
  `os_auto_update_last_success_timestamp_seconds`,
  `os_updates_textfile_last_run_timestamp_seconds`.

Alerts on these metrics (e.g. a reboot pending for a week, no successful run
for three days, metrics missing) belong to the site's monitoring.

Playbook: `ziswb.homelab_platform.central_os_updates`.

## Variables

All optional; see `meta/argument_specs.yml`.

| Variable | Default | Meaning |
|---|---|---|
| `central_os_updates_upgrade_type` | `default` | `default` (everything) or `security` |
| `central_os_updates_start_time` | `"04:30"` | Daily start, local time |
| `central_os_updates_textfile_dir` | `/var/lib/node_exporter/textfile` | node_exporter textfile directory |
| `central_os_updates_textfile_on_calendar` | `hourly` | When the metrics are written |
| `central_os_updates_success_stamp` | `/var/lib/os-updates-textfile/auto-update-success` | Last-success stamp |

## Notes

- Check mode: the package is not installed in `--check`, so the timer tasks
  are skipped there.
- The success stamp is created once with the role's first run, so a host that
  never succeeds shows a stale last success three days later.
