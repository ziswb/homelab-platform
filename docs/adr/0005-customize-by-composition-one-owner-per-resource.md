# 0005 — Customize by composition; one owner per Kubernetes resource

- Status: accepted 2026-11-17
- Date: 2026-11-17

## Context

Every site needs something the platform does not ship: an extra scrape target,
another ingress, a site-only service. Collections often offer hooks for this
(pre/post task files, template overrides), which couple the site to the role's
internals and break silently when they change. And when two roles, or a role and
a site play, write the same Kubernetes object, each run undoes the other
(server-side apply with `force_conflicts`, ADR-0011, makes the last writer win).

## Decision

- **Composition, no hooks.** Site additions are the site's own roles and plays,
  run after the collection's. Roles do not include site task files or accept
  template overrides.
- **Extension points are variables:** list-like inputs a site extends are
  `<role>_extra_*`; optional features are switched with `<role>_*_enabled`.
- **One owner per Kubernetes resource:** each object is written by exactly one
  role, in one repository. A site never patches an object a collection role
  owns; if it needs a change there, the role gets a variable (or a feature) for
  it, in a release.

## Consequences

- A role's internals can change in a minor release without breaking sites.
- A site need the roles cannot express becomes a change request to the
  collection, not a local patch.
- Who owns an object is always answerable: the role that applies it.
