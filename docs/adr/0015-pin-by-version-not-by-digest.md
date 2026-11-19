# 0015 — Pin by version; digests and hashes only where a bot keeps them current

- Status: accepted 2026-11-19
- Date: 2026-11-19

## Context

Everything this collection installs or runs with comes from somewhere else:
container images in the vendored manifests and Quadlets, the k3s install script,
Helm charts, the Ansible collections it depends on, and the Python tools CI runs.
Each can be pinned by a mutable name (a tag, a version) or by content (a digest,
a hash). Content pins defeat a re-pushed tag, but they are unreadable in a
review and go stale unless something updates them.

## Decision

- **Content pins where Dependabot maintains them:** GitHub Actions by commit SHA
  (tag as a comment) and the Molecule test-image bases by digest.
- **Version pins everywhere else:**
  - deployed images by tag, as upstream's release manifests ship them; they
    change only through `scripts/refresh-vendored.sh` (ADR-0012), which shows
    the version in every diff;
  - Helm charts by chart version;
  - k3s by `k3s_version` (`INSTALL_K3S_VERSION`): the install script from
    `get.k3s.io` is not checksum-verified, the k3s binary it installs is checked
    by the script against the release's own checksums;
  - CI's Python tools by exact version (`.github/requirements-ci.txt`, Dependabot),
    without `--require-hashes`;
  - collection dependencies by a range bounded to one major version
    (`galaxy.yml`), the major CI tests; the Molecule driver collections by exact
    version.

## Consequences

- Trust rests on the upstream registries and release pages not re-pushing a
  released tag. A site that needs more mirrors the images (for example through
  its own registry, see `k3s_registry_mirrors`) or pins digests in its own
  overrides.
- A new major of a collection dependency needs a deliberate bump of the upper
  bound in `galaxy.yml`, after CI passed with it.
- Revisit if Dependabot (or the refresh script) can maintain digests for the
  deployed images.
