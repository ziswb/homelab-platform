# 0011 — Kubernetes manifests are applied server-side, as field manager `ansible`

- Status: accepted 2026-10-29, applied the same day
- Date: 2026-10-29
- Originally: infrastructure ADR-0027

## Context

Most `kubernetes.core.k8s` tasks called the module without `apply`. It then sends
a strategic merge patch as field manager `OpenAPI-Generator`. A patch adds and
changes, but a field dropped from a manifest stays live, and the run reports
`ok`. It bit twice in the reference site: an init container and a
securityContext, both removed from manifests, stayed live until removed by hand
with `kubectl patch`.

Two ways out were on the table:

- **Client-side apply** (`apply: true` alone) keeps a copy of the object in the
  `last-applied-configuration` annotation, limited to 256 KiB. A large dashboard
  ConfigMap exceeded that, so it cannot work for every object.
- **Server-side apply** removes a field when its only owner stops sending it.
  Tested on a scratch ConfigMap: on objects created by the old patch,
  `OpenAPI-Generator` keeps co-owning every field, so nothing is removed until
  that entry is dropped from `managedFields`. After that, removals work.

## Decision

Every `kubernetes.core.k8s` task that creates or updates objects uses

```yaml
apply: true
server_side_apply:
  field_manager: ansible
  force_conflicts: true
```

`force_conflicts` makes the repository win over hand edits and controllers for
the fields it sets, as the patch did. Vendored bundles that need their own field
manager (Traefik's CRDs, the Prometheus operator bundle) keep it. Helm releases
are unaffected.

Objects created by the old patch need a one-time clean-up of their
`OpenAPI-Generator` entries in `managedFields` after the first server-side run;
the fields only that entry owned are leftovers of earlier removals and are
reported first.

## Consequences

- Removing a field from a manifest removes it from the cluster on the next run.
  Check the live object anyway the first few times.
- A field set by hand (`kubectl edit/patch`) that the role also sets is taken
  back on the next run; one the role does not set is left alone.
- Objects deleted from a role are still not deleted from the cluster: that needs
  a `state: absent` task.
- New roles copy the block above. A task without it is a review finding.
- Leftover fields stay until removed by hand or the object is recreated; nobody
  owns them any more.
