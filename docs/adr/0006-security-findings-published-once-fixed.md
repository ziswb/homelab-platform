# 0006 — Security findings are published once fixed

- Status: accepted 2026-11-17
- Date: 2026-11-17

## Context

Security findings about the roles (a weak default, a missing check, a secret that
can reach a log) are worth tracking in the open: users of the collection learn
what was wrong and which release fixed it. An open finding published before its
fix, though, points at a weakness in every site that runs the affected release.
Findings about one site's configuration are not about the collection at all.

## Decision

- Code-level findings in this collection's roles are tracked in
  `docs/SECURITY-FINDINGS.md`.
- **An open finding stays private until it is fixed;** it is published together
  with the fix, closed, naming the release that fixes it. Older closed findings
  may be published, with site details removed.
- Findings about a site's configuration stay with that site.
- Vulnerabilities are reported through GitHub's private vulnerability reporting
  (`.github/SECURITY.md`), not in public issues.

## Consequences

- The public list only ever shows fixed findings; users compare their release
  with the fix version.
- Between discovery and fix, the finding lives outside this repository, with the
  maintainer.
