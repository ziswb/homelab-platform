#!/usr/bin/env bash
# Sign a release tag, after checking what it contains. A consumer may run this
# collection's roles unattended and accept only tags signed by the maintainer;
# a signature is then only worth what was checked before it. This script:
#
#   1. refuses a dirty tree, a commit not on origin/main, a tag that exists,
#      a galaxy.yml version that differs from the tag, a CHANGELOG without
#      the version's section;
#   2. reproduces every vendored file at the version its header (or, for the
#      Traefik CRDs, traefik_install_chart_version) names, in a throwaway
#      worktree, with scripts/refresh-vendored.sh: the result must be
#      byte-identical to the commit;
#   3. shows what changed since the last signed tag. Only vendored files,
#      NOTICE, CHANGELOG.md and version lines: confirm with y. Anything else
#      is shown in full and must be confirmed by typing the version;
#   4. signs (`git tag -s`, the key in user.signingkey) and verifies the tag.
#
# It does not push. Usage: scripts/sign-release.sh vX.Y.Z [<commit>]
# Needs git, curl, python3, helm (for the Traefik CRDs).
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT}"

die() { echo "sign-release: $*" >&2; exit 1; }

[[ $# -ge 1 && $# -le 2 ]] || { sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 1; }
TAG="$1"
[[ "${TAG}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "the tag must look like vX.Y.Z"
VERSION="${TAG#v}"

# --- 1. the commit ---------------------------------------------------------------
[[ -z "$(git status --porcelain)" ]] || die "the working tree is not clean"
git fetch -q origin main --tags
COMMIT=$(git rev-parse --verify "${2:-HEAD}^{commit}")
git merge-base --is-ancestor "${COMMIT}" origin/main || die "${COMMIT:0:10} is not on origin/main (push it first)"
git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null && die "tag ${TAG} exists"
galaxy=$(git show "${COMMIT}:galaxy.yml" | python3 -c 'import sys, yaml; print(yaml.safe_load(sys.stdin)["version"])')
[[ "${galaxy}" == "${VERSION}" ]] || die "galaxy.yml says ${galaxy}, the tag ${VERSION}"
git show "${COMMIT}:CHANGELOG.md" | grep -qx "## ${VERSION}" || die "CHANGELOG.md has no section ## ${VERSION}"

# --- 2. vendored files, reproduced ---------------------------------------------------
WORK=$(mktemp -d)
cleanup() { git worktree remove --force "${WORK}/wt" >/dev/null 2>&1 || true; rm -rf "${WORK}"; }
trap cleanup EXIT
git worktree add -q --detach "${WORK}/wt" "${COMMIT}"

header_version() { # <file>: the version in a vendored file's header
    sed -n '1s/^# Vendored by scripts\/refresh-vendored.sh: [^ ]* \(.*\)$/\1/p' "$1"
}
WT="${WORK}/wt"
# component and version, one pair per line (bash 3.2 has no associative arrays)
components="metallb $(header_version "${WT}/roles/metallb/files/metallb-native.yaml")
prometheus-operator $(header_version "${WT}/roles/prometheus_operator/files/bundle.yaml")
system-upgrade-controller $(header_version "${WT}/roles/k3s_upgrader/files/system-upgrade-controller.yaml")
traefik-crds $(sed -n 's/^traefik_install_chart_version: "\(.*\)"$/\1/p' "${WT}/roles/traefik_install/defaults/main.yml")"
while read -r c v; do
    [[ -n "${v:-}" ]] || die "no version found for ${c}"
    echo "Reproducing ${c} ${v}"
    (cd "${WT}" && scripts/refresh-vendored.sh "${c}" "${v}" >/dev/null)
done <<< "${components}"
if [[ -n "$(git -C "${WT}" status --porcelain)" ]]; then
    git -C "${WT}" status --short >&2
    die "the vendored files at ${COMMIT:0:10} are not what refresh-vendored.sh produces at their versions"
fi
echo "Vendored files: reproduced byte for byte."

# --- 3. what changed since the last signed tag ---------------------------------------------
PREV=""
for t in $(git tag --merged "${COMMIT}" --sort=-v:refname 'v*'); do
    if git verify-tag "$t" >/dev/null 2>&1; then PREV="$t"; break; fi
done
if [[ -z "${PREV}" ]]; then
    PREV=$(git describe --tags --abbrev=0 "${COMMIT}" 2>/dev/null || true)
    echo "No signed tag before ${TAG}; comparing with ${PREV:-the first commit} (unsigned)."
fi
RANGE="${PREV:+${PREV}..}${COMMIT}"
echo
git --no-pager diff --stat "${RANGE}"
# Paths that change in a vendor-only release.
routine='^(NOTICE|CHANGELOG\.md|galaxy\.yml|roles/metallb/files/metallb-native\.yaml|roles/prometheus_operator/files/bundle\.yaml|roles/k3s_upgrader/files/(system-upgrade-controller|crd)\.yaml|roles/traefik_install/files/crds/.*|roles/traefik_install/(defaults/main\.yml|meta/argument_specs\.yml|README\.md))$'
other=$(git diff --name-only "${RANGE}" | grep -Ev "${routine}" || true)
echo
if [[ -z "${other}" ]]; then
    echo "Only vendored files, NOTICE, CHANGELOG.md and version lines changed since ${PREV:-the start}."
    read -r -p "Sign ${TAG} at ${COMMIT:0:10}? [y/N] " answer
    [[ "${answer}" == y ]] || die "not signed"
else
    echo "Changed beyond vendored files since ${PREV:-the start}:"
    # shellcheck disable=SC2086
    printf '  %s\n' ${other}
    echo
    # shellcheck disable=SC2086
    git --no-pager diff "${RANGE}" -- ${other}
    echo
    read -r -p "Read the diff above. Type ${TAG} to sign it: " answer
    [[ "${answer}" == "${TAG}" ]] || die "not signed"
fi

# --- 4. sign -------------------------------------------------------------------------------
git tag -s "${TAG}" -m "${TAG}" "${COMMIT}"
git verify-tag "${TAG}"
echo "Signed ${TAG}. Push it with: git push origin ${TAG}"
