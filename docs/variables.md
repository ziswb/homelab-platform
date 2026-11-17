# Variables

The platform's shared vocabulary and the rules every role's inputs follow. Each
role documents its own inputs in `roles/<role>/meta/argument_specs.yml` (checked
before the role runs) and its README; this page lists the variables that more
than one role reads.

## Rules

- **Site values have no defaults.** Anything that differs between two homelabs
  (domain, addresses, paths on a file server, user and group IDs) is a required
  variable. A role that is missing one fails at its argument spec check, before
  it changes anything.
- **Non-site values have defaults:** versions, timeouts, feature flags.
- **Secrets arrive as variables.** Roles never look secrets up; your inventory
  resolves them (Ansible Vault, a password manager lookup, ...). Lookups in
  `group_vars` are templated lazily, only when a role reads the variable. Roles
  use secrets with `no_log: true`.
- **Names:** `homelab_*` for the platform-wide variables below; `<role>_*` for a
  role's own inputs. List-like inputs a site extends are `<role>_extra_*`;
  optional features are switched with `<role>_*_enabled`.
- **Host names** are variables defaulting to `<service>.{{ homelab_domain }}`.
- **Compatibility:** a new required variable, a renamed variable or a changed
  inventory group is a major release (see [CHANGELOG](../CHANGELOG.md)).

## Inventory groups

| Group | Hosts |
|---|---|
| `server` | k3s server nodes (control plane, etcd) |
| `agent` | k3s agent nodes |
| `central_server` | the central host (file server, logs, databases) |

The names are fixed; the roles and playbooks refer to them.

## Platform variables

| Variable | Type | Required | Used by | Meaning |
|---|---|---|---|---|
| `homelab_domain` | str | yes | host name defaults | The site's DNS domain, e.g. `home.arpa` or `lab.example.com`. |

Rows are added with the roles that read them; each role move decides the
public form of the variables it needs.
