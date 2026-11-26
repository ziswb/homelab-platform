#!/usr/bin/env bash
# Re-vendor the components a Renovate PR bumps (ADR-0016). Renovate changes
# only the version a vendored component is pinned by (a file header, or the
# Traefik chart version); this rewrites the component with
# scripts/refresh-vendored.sh at that version, starting from the base's files,
# and commits the result onto the PR branch. The PR then shows the upstream
# diff, and main never holds a header that does not match its file.
#
# Usage: scripts/revendor-pr.sh <base sha> <head branch> <head sha>
#   Run from a checkout of the base (.github/workflows/revendor.yml). Refuses a
#   head that changes anything beyond the paths re-vendoring writes: scripts/
#   in the worktree are then the base's, and nothing of the PR runs as code.
#   Prints `pushed=<true|false>` to $GITHUB_OUTPUT when set.
# Needs git, curl, python3, helm (for the Traefik CRDs).
set -euo pipefail

[[ $# -eq 3 ]] || { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 1; }
BASE="$1" BRANCH="$2" HEAD="$3"
die() { echo "revendor: $*" >&2; exit 1; }
out() { [[ -n "${GITHUB_OUTPUT:-}" ]] && echo "$1" >>"${GITHUB_OUTPUT}"; echo "$1"; }

# The paths a vendor-only change may touch (scripts/sign-release.sh keeps the
# same list for a vendor-only release, plus CHANGELOG.md and galaxy.yml).
ROUTINE='^(NOTICE|roles/metallb/files/metallb-native\.yaml|roles/prometheus_operator/files/bundle\.yaml|roles/k3s_upgrader/files/(system-upgrade-controller|crd)\.yaml|roles/traefik_install/files/crds/.*|roles/traefik_install/(defaults/main\.yml|meta/argument_specs\.yml|README\.md))$'

git fetch -q origin "+refs/heads/${BRANCH}:refs/remotes/origin/${BRANCH}"
[[ "$(git rev-parse "origin/${BRANCH}")" == "${HEAD}" ]] || die "${BRANCH} moved past ${HEAD:0:10}; the next run takes it"
MB=$(git merge-base "${BASE}" "${HEAD}")

header() { # <rev> <path>: the version in a vendored file's header
    git show "$1:$2" | sed -n '1s/^# Vendored by scripts\/refresh-vendored.sh: [^ ]* \(.*\)$/\1/p'
}
chart() { # <rev>: the Traefik chart version
    git show "$1:roles/traefik_install/defaults/main.yml" | sed -n 's/^traefik_install_chart_version: "\(.*\)"$/\1/p'
}
version_of() { # <component> <rev>
    case "$1" in
    metallb) header "$2" roles/metallb/files/metallb-native.yaml ;;
    prometheus-operator) header "$2" roles/prometheus_operator/files/bundle.yaml ;;
    system-upgrade-controller) header "$2" roles/k3s_upgrader/files/system-upgrade-controller.yaml ;;
    traefik-crds) chart "$2" ;;
    esac
}
paths_of() { # <component>: what refresh-vendored.sh writes for it
    case "$1" in
    metallb) echo roles/metallb/files/metallb-native.yaml ;;
    prometheus-operator) echo roles/prometheus_operator/files/bundle.yaml ;;
    system-upgrade-controller) echo roles/k3s_upgrader/files/system-upgrade-controller.yaml roles/k3s_upgrader/files/crd.yaml ;;
    traefik-crds) echo roles/traefik_install/files/crds roles/traefik_install/defaults/main.yml \
        roles/traefik_install/meta/argument_specs.yml roles/traefik_install/README.md ;;
    esac
}

changed=()
for c in metallb prometheus-operator system-upgrade-controller traefik-crds; do
    old=$(version_of "$c" "${MB}") new=$(version_of "$c" "${HEAD}")
    [[ -n "${old}" && -n "${new}" ]] || die "no version for ${c}"
    [[ "${old}" == "${new}" ]] && continue
    [[ "${new}" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "${c}: ${new} is not a release version"
    echo "${c}: ${old} -> ${new}"
    changed+=("${c} ${new}")
done
if [[ ${#changed[@]} -eq 0 ]]; then
    echo "No vendored component changed."
    out pushed=false
    exit 0
fi

other=$(git diff --name-only "${MB}" "${HEAD}" | grep -Ev "${ROUTINE}" || true)
[[ -z "${other}" ]] || die "the PR changes more than a vendored component's files, not re-vendored: ${other//$'\n'/ }"

WORK=$(mktemp -d)
cleanup() { git worktree remove --force "${WORK}/wt" >/dev/null 2>&1 || true; rm -rf "${WORK}"; }
trap cleanup EXIT
git worktree add -q -B "revendor-${HEAD:0:10}" "${WORK}/wt" "${HEAD}"
WT="${WORK}/wt"
# All from the base's files first, so that refresh-vendored.sh finds the old
# version where it replaces it (NOTICE, the Traefik chart version's other
# places); NOTICE once, as every component writes its own line in it.
git -C "${WT}" checkout -q "${MB}" -- NOTICE
for pair in "${changed[@]}"; do
    read -r c _ <<<"${pair}"
    # shellcheck disable=SC2046
    git -C "${WT}" checkout -q "${MB}" -- $(paths_of "$c")
done
for pair in "${changed[@]}"; do
    read -r c v <<<"${pair}"
    (cd "${WT}" && scripts/refresh-vendored.sh "$c" "$v")
done
git -C "${WT}" add -A
if git -C "${WT}" diff --cached --quiet; then
    echo "The PR already holds what refresh-vendored.sh produces."
    out pushed=false
    exit 0
fi
msg="Re-vendor with scripts/refresh-vendored.sh"$'\n'
for pair in "${changed[@]}"; do msg+=$'\n'"- ${pair}"; done
git -C "${WT}" -c user.name="github-actions[bot]" \
    -c user.email="41898282+github-actions[bot]@users.noreply.github.com" \
    commit -q -m "${msg}"
git -C "${WT}" push -q origin "HEAD:refs/heads/${BRANCH}"
echo "Pushed $(git -C "${WT}" rev-parse --short HEAD) to ${BRANCH}."
out pushed=true
