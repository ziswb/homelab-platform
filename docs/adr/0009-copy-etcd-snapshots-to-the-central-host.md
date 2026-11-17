# 0009 — Copy the etcd snapshots to the central host

- Status: accepted, applied 2026-10-17; restore drilled 2026-10-23
- Date: 2026-10-17
- Originally: infrastructure ADR-0018

## Context

k3s takes its embedded-etcd snapshots on defaults: 00:00 and 12:00, 5 kept, on
each server node's own disk. They protect against a bad upgrade or etcd
corruption, not against losing the disk.

That stopped being theoretical in October 2026. One server node's SD card logged
write errors and the node hung; after it was removed from etcd, the two remaining
members had no fault tolerance, and both crashed the same night with "no leader"
(slow fdatasync on their cards). From then on every snapshot in existence sat on
one of two SD cards.

## Decision

**A systemd timer on each server node copies its snapshots into a directory on
the central host.** Role `k3s_etcd_snapshot_offload`.

- **k3s is not reconfigured.** Snapshot schedule and local retention stay on
  defaults. Changing k3s's `config.yaml` restarts k3s, and on two etcd members a
  restart is an outage. This only reads finished files.
- **Transport: NFS**, the way the nodes reach the central host's storage anyway.
  The export is squashed to its own identity, `app_uid_etcd_snapshots`, and goes
  to the **server nodes only**. A snapshot holds every Secret in the cluster in
  plaintext. Directory 0700, files 0600.
- **Mounted per run**, soft, under `/run`, and unmounted afterwards. The node has
  no permanent dependency on the central host, and an unreachable central host
  fails one run, nothing else.
- **Schedule:** 00:30 and 12:30 (plus up to 10 min jitter), `Persistent=true`,
  idle I/O priority so the copy yields to etcd on the same disk.
- **Retention on the central host:** 14 days of scheduled snapshots per node,
  pruned by each node for its own files. On-demand snapshots are kept until
  deleted by hand.
- **Offsite:** the reference site's encrypted offsite copy of the central host
  includes the directory, so the snapshots leave the house too.

## Alternatives rejected

- **k3s's built-in S3 upload (`etcd-s3`).** It would need an S3 service on the
  central host, one more thing to run and secure, and a k3s restart on every
  server to switch on.
- **A pull from the central host over SSH.** The snapshots are root-only on the
  nodes, so the central host would need root SSH (or a sudo rule) on the control
  plane.
- **A Kubernetes CronJob with a hostPath mount.** Backing up the cluster through
  the cluster, as a root pod with the etcd data directory mounted.

## Consequences

- A restore from the central host means copying the snapshot back onto a server
  node first.
- No metric: a failed run is visible only in `systemctl --failed` and the
  journal (the reference site's nodes have no node-exporter textfile collector).
- Space on the central host: about 2 GB at three servers and the reference
  site's snapshot size.
