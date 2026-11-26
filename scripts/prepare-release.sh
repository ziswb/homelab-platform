#!/usr/bin/env bash
# Prepare a release PR from the Renovate PRs merged since the last tag
# (ADR-0016): branch release/next from main with galaxy.yml's version raised
# and a CHANGELOG section listing the updates. It never tags: the maintainer
# merges the PR, runs scripts/sign-release.sh vX.Y.Z on main and pushes the
# signed tag (ADR-0004).
#
# A patch release, or a minor one if a merged PR carries the label
# `update:major` (an upstream major). Nothing is prepared when a commit since
# the last tag came from anyone but Renovate or Dependabot (the maintainer
# releases by hand), when CHANGELOG.md's Unreleased section is not empty, or
# when main already holds a version that has no tag yet.
#
# Usage: scripts/prepare-release.sh   (in CI: .github/workflows/prepare-release.yml)
# Needs git, gh (GH_TOKEN), python3; GITHUB_REPOSITORY=<owner>/<repo>.
set -euo pipefail

: "${GITHUB_REPOSITORY:?}"
BRANCH=release/next
note() { echo "prepare-release: $*"; }

git fetch -q origin main --tags
LAST=$(git describe --tags --abbrev=0 --match 'v[0-9]*' origin/main)
on_main=$(git show origin/main:galaxy.yml | sed -n 's/^version: *//p')
if [[ "v${on_main}" != "${LAST}" ]]; then
    note "main holds ${on_main}, the last tag is ${LAST}: v${on_main} awaits its signed tag"
    exit 0
fi
commits=$(git rev-list --reverse --first-parent "${LAST}..origin/main")
[[ -n "${commits}" ]] || { note "nothing since ${LAST}"; exit 0; }

entries="" bump=patch
for c in ${commits}; do
    pr=$(gh api "repos/${GITHUB_REPOSITORY}/commits/${c}/pulls" \
        --jq '[.[] | select(.merged_at != null)][0] // empty | [(.number | tostring), .user.login, ([.labels[].name] | join(",")), .title] | join("\u001f")')
    # Fields split by the unit separator: an empty field (no labels) stays one.
    IFS=$'\x1f' read -r n user labels title <<<"${pr:-}"
    case "${user:-}" in
    "renovate[bot]")
        # "Update dependency foo to v2" -> "foo to v2"
        title=${title#Update }; title=${title#dependency }
        entries+="- Updated: ${title} (#${n})"$'\n'
        [[ ",${labels}," == *",update:major,"* ]] && bump=minor
        ;;
    "dependabot[bot]") ;;  # CI tools, actions, test images: nothing that ships
    *)
        note "${c:0:10} is not from a Renovate or Dependabot PR: the maintainer releases by hand"
        exit 0
        ;;
    esac
done
[[ -n "${entries}" ]] || { note "no Renovate PR since ${LAST}"; exit 0; }

unreleased=$(git show origin/main:CHANGELOG.md | python3 -c '
import re, sys
m = re.search(r"^## Unreleased\n(.*?)(?=^## )", sys.stdin.read(), re.M | re.S)
print(m.group(1).strip() if m else "missing")')
[[ -z "${unreleased}" ]] || { note "CHANGELOG.md has Unreleased notes: the maintainer releases by hand"; exit 0; }

IFS=. read -r major minor patch <<<"${LAST#v}"
if [[ "${bump}" == minor ]]; then VERSION="${major}.$((minor + 1)).0"; else VERSION="${major}.${minor}.$((patch + 1))"; fi
note "preparing ${VERSION} (${bump}) from ${LAST}"

git checkout -q -B "${BRANCH}" origin/main
sed -i "s/^version: ${on_main}\$/version: ${VERSION}/" galaxy.yml
grep -qx "version: ${VERSION}" galaxy.yml || { echo "galaxy.yml: version line not replaced" >&2; exit 1; }
# The install example names the latest tag.
sed -i "s/^\(    version: \)v[0-9.]*\(   # the latest vX.Y.Z tag\)/\1v${VERSION}\2/" README.md
grep -q "^    version: v${VERSION}   # the latest" README.md || { echo "README.md: version line not replaced" >&2; exit 1; }
summary="Dependency updates, prepared by CI from the merged Renovate PRs (ADR-0016)."
[[ "${bump}" == minor ]] && summary+=" Contains an upstream major: read its release notes before applying."
ENTRY="## ${VERSION}"$'\n\n'"${summary}"$'\n\n'"${entries}" python3 - <<'PY'
import os
path = "CHANGELOG.md"
s = open(path).read()
head = "## Unreleased\n\n"
assert s.count(head) == 1, "CHANGELOG.md: no single '## Unreleased' heading"
open(path, "w").write(s.replace(head, head + os.environ["ENTRY"] + "\n", 1))
PY
git -c user.name="github-actions[bot]" \
    -c user.email="41898282+github-actions[bot]@users.noreply.github.com" \
    commit -q -am "${VERSION}: dependency updates"
git push -q --force origin "HEAD:refs/heads/${BRANCH}"

body="Prepared by CI (ADR-0016). Not a release until the tag is signed:

1. Approve the waiting CI and Gitleaks runs (*Approve workflows to run*), then
   review and merge this PR (squash).
2. On main: \`git pull && scripts/sign-release.sh v${VERSION}\`
3. \`git push origin v${VERSION}\`

${entries}"
n=$(gh pr list --head "${BRANCH}" --state open --json number --jq '.[0].number // empty')
if [[ -n "${n}" ]]; then
    gh pr edit "${n}" --title "Release v${VERSION}" --body "${body}"
else
    gh pr create --base main --head "${BRANCH}" --title "Release v${VERSION}" --body "${body}"
fi
