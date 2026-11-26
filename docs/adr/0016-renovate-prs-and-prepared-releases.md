# 0016 — Renovate opens the PRs; CI re-vendors and prepares releases; the maintainer signs

- Status: accepted 2026-11-26
- Date: 2026-11-26

## Context

The collection pins about a dozen upstream versions: container images and Helm
charts in the roles, and four vendored upstream files (ADR-0012) that only
`scripts/refresh-vendored.sh` may write. Keeping them current was a manual
survey before every release. A consuming site may apply this collection's
patch releases unattended and accept only tags the maintainer signed
(ADR-0004, amended), so whatever automates the updates must stop short of the
tag, and a release must contain nothing but what the maintainer can check.

Dependabot already keeps the GitHub Actions, the CI tools and the test images
current (ADR-0015); it has no way to follow a version in a comment-marked line
or a vendored file's header.

## Decision

- **Renovate's GitHub app opens a PR per upstream update** of the role pins and
  the vendored components (`renovate.json5`). Each pin carries a marker on the
  line above it, `# renovate: datasource=… depName=… [registryUrl=…]`, or in a
  template the Jinja comment `{# renovate: … #}`, which renders to nothing and
  so leaves every rendered file unchanged. Vendored components are found by
  their header (the Traefik CRDs by `traefik_install_chart_version`). Renovate
  never merges; majors wait on its Dependency Dashboard and carry the label
  `update:major`. Dependabot keeps its three ecosystems; Renovate runs only its
  regex managers, so the two never overlap.
- **A vendored component is re-vendored on its PR by CI.** Renovate changes
  only the version a component is pinned by. `.github/workflows/revendor.yml`
  (`pull_request_target`: workflow and scripts from `main`) runs
  `scripts/revendor-pr.sh`, which refuses a PR that changes anything beyond the
  paths re-vendoring writes, restores those from the base, runs
  `refresh-vendored.sh` at the new version and pushes the result onto the PR.
  The review sees the upstream diff, and `main` never holds a header that does
  not match its file. Renovate stops rebasing a branch someone else pushed to;
  the Dependency Dashboard's rebase box starts it over (CI then re-vendors
  again).
- **CI prepares the release, the maintainer makes it.** After each merge to
  `main`, `.github/workflows/prepare-release.yml` runs
  `scripts/prepare-release.sh`: when every commit since the last tag came from
  a Renovate (or Dependabot) PR and CHANGELOG.md has no Unreleased notes, it
  opens or updates the PR `release/next` with `galaxy.yml`'s version raised
  and a CHANGELOG section listing the updates. A patch release; a minor one if
  a merged PR carries `update:major`, so that a consumer who takes patches
  unattended does not take an upstream major. It never tags. The maintainer
  merges the release PR, runs `scripts/sign-release.sh vX.Y.Z` (which
  reproduces every vendored file and shows anything else since the last
  signed tag in full) and pushes the signed tag; `release.yml` builds the
  release as before.
- Any other commit since the last tag (a fix, a feature, Unreleased notes)
  means the maintainer releases by hand, as before.
- A commit either workflow pushes with `GITHUB_TOKEN` runs CI and Gitleaks
  on its PR like any other (`pull_request`). GitHub counts its author,
  `github-actions[bot]`, as an outside contributor: with the approval policy
  at *all outside contributors* those runs wait for an approval, and the PR
  stays blocked even with the required checks passed from a dispatched run.
  The policy is *first-time contributors* (amended 2026-11-26; the first
  version dispatched the checks instead, on the assumption that such a push
  starts no workflow).

## Consequences

- Upstream updates arrive as reviewable PRs, a vendored one with its real
  diff; a routine release is three steps for the maintainer (merge, sign,
  push).
- The signature still is the only release gate: nothing CI or Renovate does
  reaches a consumer that accepts signed tags only.
- Repository settings this needs: the Renovate app installed for this
  repository (with Mend's *Scan and Alert*; *Scan Only* silences Renovate);
  GitHub Actions allowed to create pull requests, for the release PR; the
  approval policy for outside contributors at first-time contributors. As
  API calls (the web UI moves):
  `gh api -X PUT repos/{owner}/{repo}/actions/permissions/workflow -f default_workflow_permissions=read -F can_approve_pull_request_reviews=true`,
  `gh api -X PUT repos/{owner}/{repo}/actions/permissions/fork-pr-contributor-approval -f approval_policy=first_time_contributors`.
- `revendor.yml` runs with write access on Renovate's PRs. It executes nothing
  from the PR: `scripts/` must be unchanged there, and the vendored files are
  rewritten from upstream, not taken from the branch.
- A PR re-vendored by CI is no longer rebased by Renovate on its own; on a
  conflict, tick its rebase box on the Dependency Dashboard.
