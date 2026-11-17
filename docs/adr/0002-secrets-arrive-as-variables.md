# 0002 — Secrets arrive as variables

- Status: accepted 2026-11-17
- Date: 2026-11-17

## Context

Before the move into this collection, the roles looked secrets up themselves
from the operator's password manager, by item title, at deploy time. That ties
every role to one secret store and one way of naming items, and a public role
that names a site's secret items leaks the site's structure.

## Decision

**Roles take secret values as variables.** Every secret a role needs is a
required variable without a default, declared in the role's argument specs. The
site resolves it, from whatever store it uses: Ansible Vault, a password manager
lookup, an environment variable.

- A lookup in the site's `group_vars` (e.g. `"{{ lookup('...') }}"`) is templated
  lazily: it runs only when a role reads the variable, so a play that does not
  need a secret does not touch the store.
- Roles keep secret-bearing Kubernetes objects as inline `definition:`s in the
  task, with `no_log: true`, so the value never appears in output or in a file.
- Roles never call a secret lookup themselves.

## Consequences

- The collection works with any secret store and names none.
- A role that gains a secret gains a required variable: a major release
  (ADR-0004).
- Argument specs check that a secret is set, not that it is right; a wrong value
  shows up when the service uses it.
