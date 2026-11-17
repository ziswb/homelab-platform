# 0003 — Inventory groups and site values are contract

- Status: accepted 2026-11-17
- Date: 2026-11-17

## Context

A role written for one site carries that site in its defaults: a domain, an
address, a path on the file server, a user ID. Published as is, the defaults leak
the site and, worse, work by accident elsewhere: a missing variable silently takes
the original site's value. The roles also address hosts by inventory group, so
the group names are part of what a user must get right.

## Decision

- **The inventory groups are fixed:** `server` (k3s control plane), `agent` (k3s
  workers), `central_server` (the central host). Roles and playbooks refer to these
  names; there is no variable to rename them.
- **Site values have no defaults.** Anything that differs between two homelabs
  (domain, addresses, paths on the file server, user and group IDs such as
  `app_uid_*` and `homelab_gid_media`) is a required variable. Values that do not
  identify a site (versions, timeouts, feature flags) keep defaults.
- **The platform-wide vocabulary is `homelab_*`**, documented in
  `docs/variables.md`; a role's own inputs are `<role>_*`. Host names default to
  `<service>.{{ homelab_domain }}`, with `homelab_domain` required.
- **Every role ships `meta/argument_specs.yml`** (mandatory from v1.0.0), so a
  missing or mistyped input fails before the role changes anything. CI refuses a
  role without one.
- Examples use documentation values only (RFC 5737 addresses, `example.com`, the
  bare `home.arpa`); `examples/inventory/` is the skeleton.

## Consequences

- A fresh site gets an early, specific error per missing value instead of a
  half-configured host.
- The argument specs are the interface: adding a required variable, renaming one
  or changing a group is a breaking change (ADR-0004).
- Inventories have more to set than with convenient defaults; the example
  inventory and `docs/variables.md` carry that cost.
