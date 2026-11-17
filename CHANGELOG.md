# Changelog

All notable changes to this collection. Versions follow [SemVer](https://semver.org/):
a new required variable, a renamed variable or a changed inventory group is a major
release. Each release is a git tag `vX.Y.Z`.

## Unreleased

## 0.2.0

First batch of roles moved in from the reference site's infrastructure
repository: the central host.

- Added `central_podman`, `central_loki`, `central_os_updates`, with argument
  specs, READMEs and the playbooks `ziswb.homelab_platform.central_loki` and
  `ziswb.homelab_platform.central_os_updates`.
- `central_loki`: `central_loki_dir`, `central_loki_owner` and
  `central_loki_group` are required (site values, no defaults).
- Fixed: `central_podman` failed on a fresh Rocky 10 host, where installing
  podman does not create `/etc/containers/containers.conf.d`.
- Molecule scenario for `central_podman` (Rocky Linux 10).

## 0.1.0

- Collection skeleton: metadata, leak guard, CI (lint, structure, syntax check,
  Molecule), example inventory, variable vocabulary and bring-up order docs.
