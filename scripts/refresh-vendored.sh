#!/usr/bin/env bash
# Refresh the vendored upstream release YAML (ADR-0012). Playbooks only apply
# the committed files; this script is the one way to change them. Each
# component is downloaded at an explicit version, edited only by the checked
# steps below, and written in place together with every place that names its
# version (NOTICE; for traefik-crds also the chart version). Review with
# `git diff`, then commit and release.
#
# Usage: scripts/refresh-vendored.sh <component> <version>
#   metallb                    e.g. v0.16.2  roles/metallb/files/metallb-native.yaml
#   prometheus-operator        e.g. v0.94.2  roles/prometheus_operator/files/bundle.yaml
#   system-upgrade-controller  e.g. v0.21.0  roles/k3s_upgrader/files/{system-upgrade-controller,crd}.yaml
#   traefik-crds               e.g. 42.3.1   roles/traefik_install/files/crds/ (chart version;
#                                            also sets traefik_install_chart_version)
# Single-file components get a two-line header naming version and source;
# the Traefik CRDs are copied verbatim (needs helm).
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
ROLES="${ROOT}/roles"

usage() {
    sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
    exit 1
}

need() {
    command -v "$1" >/dev/null || { echo "ERROR: $1 not found" >&2; exit 1; }
}

[[ $# -eq 2 ]] || usage
COMPONENT="$1"
VERSION="$2"
need curl
need python3
WORK=$(mktemp -d)
trap 'rm -rf "${WORK}"' EXIT

fetch() { # url dest
    echo "Downloading $1"
    curl -fsSL "$1" -o "$2"
}

# vendored_version <file>: the version in a vendored file's header.
vendored_version() {
    sed -n '1s/^# Vendored by scripts\/refresh-vendored.sh: [^ ]* \(.*\)$/\1/p' "$1"
}

# edit <file> <url> <python edits>: run checked edits on a downloaded file and
# prepend the provenance header. Edits get the text as `s` and must assign it
# back; `once(old, new)` replaces a string that must occur exactly once.
edit() {
    FILE="$1" URL="$2" EDITS="$3" VERSION="${VERSION}" COMPONENT="${COMPONENT}" python3 - <<'PY'
import os, re, sys
path = os.environ["FILE"]
s = open(path).read()

def once(old, new):
    global s
    if s.count(old) != 1:
        sys.exit(f"ERROR: expected exactly one {old!r}, found {s.count(old)}; upstream layout may have changed")
    s = s.replace(old, new, 1)

exec(os.environ["EDITS"])
header = (f"# Vendored by scripts/refresh-vendored.sh: {os.environ['COMPONENT']} "
          f"{os.environ['VERSION']}\n# from {os.environ['URL']}\n")
open(path, "w").write(header + s)
PY
}

# set_version <old> <new> <file>:<text before the version> ...: replace
# "<text><old>" by "<text><new>" exactly once in each file.
set_version() {
    local old="$1" new="$2"
    shift 2
    [[ "${old}" == "${new}" ]] && return 0
    OLD="${old}" NEW="${new}" python3 - "$@" <<'PY'
import os, sys
old, new = os.environ["OLD"], os.environ["NEW"]
for spec in sys.argv[1:]:
    path, prefix = spec.split(":", 1)
    s = open(path).read()
    if s.count(prefix + old) != 1:
        sys.exit(f"ERROR: expected exactly one {prefix + old!r} in {path}, found {s.count(prefix + old)}")
    open(path, "w").write(s.replace(prefix + old, prefix + new, 1))
PY
}

case "${COMPONENT}" in
metallb)
    DEST="${ROLES}/metallb/files/metallb-native.yaml"
    OLD=$(vendored_version "${DEST}")
    URL="https://raw.githubusercontent.com/metallb/metallb/${VERSION}/config/manifests/metallb-native.yaml"
    fetch "${URL}" "${WORK}/f.yaml"
    edit "${WORK}/f.yaml" "${URL}" ""
    mv "${WORK}/f.yaml" "${DEST}"
    set_version "${OLD}" "${VERSION}" "${ROOT}/NOTICE:- MetalLB "
    ;;
prometheus-operator)
    DEST="${ROLES}/prometheus_operator/files/bundle.yaml"
    OLD=$(vendored_version "${DEST}")
    URL="https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/refs/tags/${VERSION}/bundle.yaml"
    fetch "${URL}" "${WORK}/f.yaml"
    # The bundle installs into `default`; the role runs it in `monitoring`.
    # The two quoting fixes keep YAML parsers from reading `=`/`=~` as values.
    edit "${WORK}/f.yaml" "${URL}" '
s = re.sub(r"(\s+)namespace: default(\s+.*)?$", r"\1namespace: monitoring\2", s, flags=re.M)
q = chr(34)
s = re.sub(r"(\s+)- =(\s+.*)?$", lambda m: m.group(1) + "- " + q + "=" + q + (m.group(2) or ""), s, flags=re.M)
s = re.sub(r"(\s+)- =~(\s+.*)?$", lambda m: m.group(1) + "- " + q + "=~" + q + (m.group(2) or ""), s, flags=re.M)
'
    mv "${WORK}/f.yaml" "${DEST}"
    set_version "${OLD}" "${VERSION}" "${ROOT}/NOTICE:- prometheus-operator "
    ;;
system-upgrade-controller)
    DEST="${ROLES}/k3s_upgrader/files"
    OLD=$(vendored_version "${DEST}/system-upgrade-controller.yaml")
    BASE="https://github.com/rancher/system-upgrade-controller/releases/download/${VERSION}"
    fetch "${BASE}/system-upgrade-controller.yaml" "${WORK}/suc.yaml"
    fetch "${BASE}/crd.yaml" "${WORK}/crd.yaml"
    # Keep two old ReplicaSets, like the collection's other workloads.
    edit "${WORK}/suc.yaml" "${BASE}/system-upgrade-controller.yaml" '
h = "kind: Deployment\nmetadata:\n  name: system-upgrade-controller\n  namespace: system-upgrade\nspec:\n"
once(h, h + "  revisionHistoryLimit: 2\n")
'
    edit "${WORK}/crd.yaml" "${BASE}/crd.yaml" ""
    mv "${WORK}/suc.yaml" "${DEST}/system-upgrade-controller.yaml"
    mv "${WORK}/crd.yaml" "${DEST}/crd.yaml"
    set_version "${OLD}" "${VERSION}" "${ROOT}/NOTICE:- system-upgrade-controller "
    ;;
traefik-crds)
    need helm
    ROLE="${ROLES}/traefik_install"
    DEST="${ROLE}/files/crds"
    OLD=$(sed -n 's/^traefik_install_chart_version: "\(.*\)"$/\1/p' "${ROLE}/defaults/main.yml")
    # A throwaway Helm home: no repo is added to the user's Helm configuration.
    export HELM_CONFIG_HOME="${WORK}/helm/config" HELM_CACHE_HOME="${WORK}/helm/cache" \
        HELM_DATA_HOME="${WORK}/helm/data"
    helm pull traefik --repo https://traefik.github.io/charts --version "${VERSION}" \
        --untar --untardir "${WORK}"
    # Verbatim copy, no header: `diff` against the chart stays the whole review.
    rm -f "${DEST}"/*.yaml
    cp "${WORK}"/traefik/crds/*.yaml "${DEST}/"
    set_version "${OLD}" "${VERSION}" \
        "${ROLE}/defaults/main.yml:traefik_install_chart_version: \"" \
        "${ROLE}/meta/argument_specs.yml:default: \"" \
        "${ROLE}/README.md:| no | \`" \
        "${DEST}/README.md:Currently **" \
        "${ROOT}/NOTICE:- Traefik Helm chart "
    ;;
*)
    usage
    ;;
esac

echo
echo "Done. Review: git diff --stat; then a dry run of the playbook that applies it."
