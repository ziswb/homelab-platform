# 0004 — Releases are git tags; SemVer follows the argument specs

- Status: accepted 2026-11-17. **Amended 2026-11-25:** release tags are
  signed by the maintainer, after `scripts/sign-release.sh` has checked them.
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

## Amendment 2026-11-25: signed tags

A consuming site may apply releases unattended, with its own credentials, and
accept only tags signed by the maintainer. A tag is then the step where the
maintainer vouches for the release, so it is signed (`git tag -s`, an SSH
signing key) and never set by CI, and the signature is only given after a
check: `scripts/sign-release.sh vX.Y.Z` refuses a dirty tree, a commit not on
`main`, a mismatched `galaxy.yml` or missing CHANGELOG section; reproduces
every vendored file at the version its header names with
`scripts/refresh-vendored.sh` and refuses one that differs; and shows the
full diff since the last signed tag for anything beyond vendored files,
NOTICE, the changelog and version lines, which must be confirmed by typing
the version. Tags before v1.7.0 are unsigned.

Since 2026-11-26 CI may prepare a routine release as a PR (ADR-0016); the
tag stays the maintainer's, signed as above.

