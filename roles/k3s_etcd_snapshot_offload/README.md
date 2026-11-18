# k3s_etcd_snapshot_offload

Copies each server node's etcd snapshots to an NFS export on the central host
([ADR-0009](../../docs/adr/0009-copy-etcd-snapshots-to-the-central-host.md)).

- k3s stays on its defaults (snapshots at 00:00/12:00, 5 kept locally). Nothing
  here restarts k3s, so it is safe to apply on a two-member etcd.
- A systemd timer runs half an hour after each snapshot, with idle I/O
  priority. It mounts the export for the run only (NFS soft mount under
  `/run`), copies new snapshots with `rsync --ignore-existing`, prunes this
  node's scheduled snapshots older than the retention there (14 days), and
  unmounts. On-demand snapshots are never pruned.
- The export is the site's: create it on the central host first, writable by
  root from the server nodes (e.g. squashed to one service account). Until it
  exists the role installs cleanly and only the timer's runs fail.

Playbook: `ziswb.homelab_platform.k3s_etcd_snapshot_offload` (hosts `server`).

Check a node:

```bash
systemctl list-timers k3s-etcd-snapshot-offload.timer
journalctl -u k3s-etcd-snapshot-offload.service -n 20
sudo systemctl start k3s-etcd-snapshot-offload.service   # run it now
```

There is no metric; a failed run shows in `systemctl --failed` and in the
journal.

**Restore:** copy the snapshot back onto a server node's
`/var/lib/rancher/k3s/server/db/snapshots/` and follow
[k3s: restoring a snapshot](https://docs.k3s.io/datastore/backup-restore).

## Variables

Required (platform variables, `docs/variables.md`): `homelab_nfs_server`,
`homelab_nfs_paths` (this role reads `homelab_nfs_paths.etcd_snapshots`).
Schedule, retention and paths have defaults; see `meta/argument_specs.yml`.
