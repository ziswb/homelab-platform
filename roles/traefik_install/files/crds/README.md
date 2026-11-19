# Vendored Traefik CRDs

Verbatim copy of `crds/` from the **traefik chart at the version pinned in
`../../defaults/main.yml`** (`traefik_install_chart_version`). Currently **42.3.1**.

## Why these are vendored

Helm applies a chart's `crds/` directory on **install only** — never on upgrade.
So bumping `chart_version` moves the Deployment and leaves the CRDs behind, with
no error and nothing to notice until a custom resource uses a field the stale
schema rejects. That is not hypothetical: the reference cluster's CRDs, created at
first install, were still generated from Traefik **v3.4** when the chart had
already reached v39 (proxy v3.6.8): five minors of schema drift, found during the
41.4.0 upgrade.

The role applies this directory *before* the Helm release, server-side, so the
schema is always at least as new as the chart being installed.

## Re-vendoring (do this in the same commit as any chart version bump)

```bash
scripts/refresh-vendored.sh traefik-crds <NEW>
```

It replaces the CRDs with the chart's and sets the version above,
`traefik_install_chart_version` (defaults, argument specs, role README) and
NOTICE.

There are **no local modifications** — keep it that way, so re-vendoring stays a
plain copy and `diff` against the chart is the whole review.

Two things worth checking on each bump:

- **Diff for removals, not just additions.** CRD changes are normally additive
  (39 → 41 removed nothing but doc strings), but a dropped property or a tightened
  validation would reject existing IngressRoutes. `kubectl diff --server-side -f crds/`
  against the live cluster shows exactly what will change.
- Chart 41.4.0 **dropped** the Gateway API bundle (`gateway-standard-install.yaml`)
  that earlier versions shipped here. Those CRDs remain in the cluster from the
  original install; nothing uses them and the `kubernetesGateway` provider is off.
  If Gateway API is ever adopted, it has to be installed on its own.
