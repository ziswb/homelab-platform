# 0004 — Releases are git tags; SemVer follows the argument specs

- Status: accepted 2026-11-17
- Date: 2026-11-17

## Context

The collection is consumed by at least one production site, which must know what
it runs and must not pick up unreviewed changes. Ansible Galaxy would add an
account, an upload step and a second place where versions live, for a collection
with one known consumer so far.

## Decision

- **A release is a git tag `vX.Y.Z`**, set by the maintainer. `galaxy.yml`'s
  `version` must equal the tag; CI refuses a tag that does not match, or one
  without a section in the hand-written `CHANGELOG.md`. Consumers install from
  git at a tag. No Galaxy for now.
- **SemVer is tied to the argument specs** (ADR-0003): a new required variable, a
  renamed or removed variable, or a changed inventory group is a **major**
  release. A new optional variable or feature is minor; a fix is a patch.
- **Production applies only a tagged release.** A consuming site pins the tag in
  its requirements. For development, a checkout of the collection is linked into
  a dev collections path; the consuming site's playbooks refuse to run against an
  untagged collection unless explicitly overridden (`-e
  allow_dev_collection=true`).

## Consequences

- What runs in production is always a named, reviewed version; rolling back is
  pinning the previous tag.
- Breaking changes are visible in the version number and the changelog.
- No Galaxy discovery; adding Galaxy later is an upload step, not a redesign.
