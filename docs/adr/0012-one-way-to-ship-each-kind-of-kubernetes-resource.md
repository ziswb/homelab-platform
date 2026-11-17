# 0012 — One way to ship each kind of Kubernetes resource

- Status: accepted 2026-10-29, applied the same day
- Date: 2026-10-29
- Originally: infrastructure ADR-0028

## Context

Kubernetes resources reached the cluster in four ways, and nothing said which to
use when:

- **Upstream Helm charts** (cert-manager, Traefik, CloudNativePG, ...).
- **Upstream release YAML** (MetalLB, the Prometheus operator bundle, the
  system-upgrade-controller, Traefik's CRDs, ...).
- **Local Helm charts** for two applications.
- **Own manifests**, applied three different ways:
  - from `files/` through `with_fileglob` + `lookup('template')`;
  - from `templates/` through `lookup('template')`;
  - from `files/` with `src:`, which applies the file without templating.

So a file's folder said nothing about whether it was templated: dozens of files
with Jinja sat in `files/`, and a variable added to a `src:` file would have
reached the cluster as a literal `{{ … }}`. `with_fileglob` also skips a listed
file that does not exist, without an error. Chart folders were named three ways.

## Decision

Who wrote a resource decides how it ships:

1. **Vendor software ships in the vendor's format.**
   - If the vendor publishes a Helm chart, install it with `kubernetes.core.helm`
     at a pinned chart version. Static values go in `<role>/files/values.yaml`;
     values built from Ansible variables go inline in `values:`.
   - If the vendor publishes release YAML, keep it in `<role>/files/`, apply it
     with `src:`, and do not edit it by hand. Upgrading means replacing the file
     with the next release, through a refresh script that downloads the release,
     makes the few checked edits (a namespace, pinned images, …) and writes the
     version into the file's first line. Playbooks never download.
   - Every chart version is `<role>_chart_version` in the role's
     `defaults/main.yml`.
2. **Our own resources are Jinja manifests in `<role>/templates/*.yaml.j2`.** They
   are applied with
   `definition: "{{ lookup('template', item) | from_yaml_all | list }}"` and
   server-side apply (ADR-0011), with an explicit `loop:` list in apply order. This
   holds even for a file without variables, so there is one path and any file can
   take a variable later. Secrets stay inline `definition:`s in the task, where
   `no_log` covers them (ADR-0002).
3. **Own Helm charts** are allowed only for an app with many components switched
   on and off by values. A new one needs its reason added here. The chart lives in
   `<role>/chart/`.

`files/` therefore holds only files used as they are (vendor YAML, upstream chart
values, dashboard JSON), and `templates/` holds everything that is rendered.

## Consequences

- A file missing from a `loop:` list fails the run instead of being skipped.
- Prometheus rule annotations that use Prometheus templating (`{{ $labels.x }}`)
  must be wrapped in `{% raw %}`, because the rule files go through Jinja.
- The original change moved files only: the rendered objects stayed the same,
  which a dry run confirmed.
