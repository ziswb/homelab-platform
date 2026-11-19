# homelab-platform

Ansible collection `ziswb.homelab_platform`: a **reference platform** for a small
k3s homelab. It is the architecture one homelab actually runs, written down as
roles and playbooks: k3s on small Ubuntu nodes, a central host running services
as Podman Quadlets, CloudNativePG for databases, a private CA with cert-manager,
Traefik and MetalLB for ingress, Prometheus Operator, Loki and Alloy for
monitoring. It is opinionated, not a general-purpose library; the decisions
behind it are documented as [ADRs](docs/adr/).

> **Status:** in production on the reference site: the k3s install, the nodes'
> trust in the private root CA, the central host's Podman base and Loki,
> cert-manager with the private CA chain, MetalLB and Traefik, the CloudNativePG
> operator, monitoring and log shipping, node maintenance (24 roles). The current
> release and what changed are in the [CHANGELOG](CHANGELOG.md).

## Supported

| | |
|---|---|
| k3s nodes (`server`, `agent`) | Ubuntu 24.04 LTS |
| Central host (`central_server`) | Rocky Linux 10 (RHEL 10 family) |
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

Details: [docs/variables.md](docs/variables.md) (the variable vocabulary),
[docs/bring-up.md](docs/bring-up.md) (the order a new site applies the
playbooks), [examples/inventory/](examples/inventory/) (an inventory skeleton).

## Install

There is no Galaxy release; install a tagged version from git:

```yaml
# requirements.yml
collections:
  - name: https://github.com/ziswb/homelab-platform.git
    type: git
    version: v1.5.0   # the latest vX.Y.Z tag, see CHANGELOG.md
```

```bash
ansible-galaxy collection install -r requirements.yml
```

Releases follow [SemVer](https://semver.org/): a new required variable, a
renamed variable or a changed inventory group is a major release.

## Development

CI (`.github/workflows/ci.yml`) runs on every push and PR:

- **Tier 1:** yamllint, ansible-lint (production profile), a structure check
  (`scripts/check-structure.py`: README and argument specs per role, Docker-only
  Molecule), the collection build, and `--syntax-check` of every playbook
  against the example inventory.
- **Tier 2:** Molecule scenarios in `extensions/molecule/`, Docker driver, on
  systemd test images (Ubuntu 24.04 for node roles, Rocky Linux 10 for central
  host roles).

Locally:

```bash
python3 -m venv .venv && .venv/bin/pip install -r .github/requirements-ci.txt
. .venv/bin/activate
# A project-local collections path: nothing goes into ~/.ansible.
export ANSIBLE_COLLECTIONS_PATH="$PWD/.cache/collections"
ansible-galaxy collection build --force --output-path .cache
ansible-galaxy collection install --force .cache/ziswb-homelab_platform-*.tar.gz
ansible-galaxy collection install -r extensions/molecule/requirements.yml

yamllint --strict . && ansible-lint --strict && scripts/check-structure.py
scripts/molecule-images.sh
molecule test -s platform_smoke
```

With a Docker context other than the default socket (Rancher Desktop, Colima),
set `DOCKER_HOST=$(docker context inspect --format '{{.Endpoints.docker.Host}}')`
for Molecule.

### Vendored manifests

Upstream release YAML in `roles/*/files/` changes only through
`scripts/refresh-vendored.sh <component> <version>` (ADR-0012): it downloads the
release, makes the checked edits, writes the version header and updates NOTICE.
Run without arguments for the component list.

## Security

See [SECURITY.md](.github/SECURITY.md).

## License

[Apache License 2.0](LICENSE). Vendored upstream manifests and charts keep their
own licenses, listed in [NOTICE](NOTICE).
