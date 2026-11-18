# Architecture Decision Records

Short records of the decisions that shape this collection. One file per decision,
numbered. A decision is not rewritten after acceptance: a changed mind gets a
**new** ADR that supersedes the old one, or a dated *Amendment* section. The status
line is kept current (proposed → accepted, or rejected / superseded). Keep them
short; the point is the *why*, which the code cannot express. Check them before
introducing a new pattern.

Some ADRs were written for the private infrastructure repository that runs this
platform and moved here with the roles they constrain; they say so in an
"Originally" line and keep their original date. Site details were taken out in the
move, the decisions were not changed.

Template:

```markdown
# NNNN — Title (a statement, e.g. "Use a private CA")

- Status: proposed | accepted YYYY-MM-DD | rejected | superseded by NNNN
- Date: YYYY-MM-DD

## Context
What situation or constraint forced a decision?

## Decision
What we do.

## Consequences
What becomes easier, what becomes harder, what must be kept in mind.
```

## Index

- [0001 — A reference platform, not a generic library](0001-reference-platform-not-a-generic-library.md)
- [0002 — Secrets arrive as variables](0002-secrets-arrive-as-variables.md)
- [0003 — Inventory groups and site values are contract](0003-inventory-groups-and-site-values-are-contract.md)
- [0004 — Releases are git tags; SemVer follows the argument specs](0004-releases-are-git-tags-semver-follows-argument-specs.md)
- [0005 — Customize by composition; one owner per Kubernetes resource](0005-customize-by-composition-one-owner-per-resource.md)
- [0006 — Security findings are published once fixed](0006-security-findings-published-once-fixed.md)
- [0007 — Use a private CA instead of Let's Encrypt](0007-private-ca-instead-of-lets-encrypt.md)
- [0008 — Run central-host containers as Podman Quadlets](0008-central-host-podman-quadlets.md)
- [0009 — Copy the etcd snapshots to the central host](0009-copy-etcd-snapshots-to-the-central-host.md)
- [0010 — k3s is upgraded by the system-upgrade-controller only](0010-k3s-upgrades-by-the-system-upgrade-controller.md)
- [0011 — Kubernetes manifests are applied server-side, as field manager `ansible`](0011-kubernetes-manifests-applied-server-side.md)
- [0012 — One way to ship each kind of Kubernetes resource](0012-one-way-to-ship-each-kind-of-kubernetes-resource.md)
- [0013 — OS packages update themselves; reboots stay with the operator](0013-os-packages-update-themselves-reboots-stay-manual.md)
- [0014 — Expose services LAN-first, Tailscale selectively](0014-service-exposure-lan-first.md)
