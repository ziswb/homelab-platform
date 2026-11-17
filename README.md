# homelab-platform

Ansible collection `ziswb.homelab_platform`: a **reference platform** for a small
k3s homelab. It is the architecture one homelab actually runs, written down as
roles and playbooks: k3s on small Ubuntu nodes, a central host running services
as Podman Quadlets, CloudNativePG for databases, a private CA with cert-manager,
Traefik and MetalLB for ingress, Prometheus Operator, Loki and Alloy for
monitoring. It is opinionated, not a general-purpose library; the decisions
behind it are documented as ADRs.

> **Status:** pre-1.0, no roles yet. The roles move in from a private
> infrastructure repository; v1.0.0 is the first usable release.

## Supported

| | |
|---|---|
| Operating system | Ubuntu 24.04 LTS |
| Architectures | arm64, amd64 |
| Kubernetes | k3s only |
| Ansible | ansible-core 2.15 or later |
| Collections | `kubernetes.core` >= 6.5.0, < 7.0.0; `community.general`; `ansible.posix` |

## Contracts

- **Inventory groups** are fixed: `server` (k3s control plane), `agent` (k3s
  workers), `central_server` (the central host). The roles and playbooks refer
  to these names.
- **Site values have no defaults.** The platform's own variables (`homelab_*`,
  e.g. the required `homelab_domain`) and every role's site inputs are required;
  each role declares them in `meta/argument_specs.yml`, so a missing one fails
  before anything runs. Versions and feature flags have defaults.
- **Secrets arrive as variables.** Roles never look secrets up themselves; your
  inventory resolves them (from a vault, a password manager lookup, ...).
- **Customize by composition.** Site-specific additions are your own roles or
  plays that run after the collection's; list-like inputs are
  `<role>_extra_*`, optional features `<role>_*_enabled`. Each Kubernetes
  resource is owned by exactly one role.

## Install

There is no Galaxy release; install a tagged version from git:

```yaml
# requirements.yml
collections:
  - name: https://github.com/ziswb/homelab-platform.git
    type: git
    version: v1.0.0
```

```bash
ansible-galaxy collection install -r requirements.yml
```

Releases follow [SemVer](https://semver.org/): a new required variable, a
renamed variable or a changed inventory group is a major release.

## Security

See [SECURITY.md](.github/SECURITY.md).

## License

[Apache License 2.0](LICENSE). Vendored upstream manifests and charts keep their
own licenses, listed in [NOTICE](NOTICE).
