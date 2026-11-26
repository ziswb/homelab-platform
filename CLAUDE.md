# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## This repository is public

Everything committed here (code, docs, examples, commit messages) is public. Site specifics
stay in the private `infrastructure` repo, which consumes this collection: host names,
FQDNs, IPs, subnets, tailnet name, MACs, coordinates, serial numbers, e-mail addresses,
people's names, and credentials of any kind.

- Roles take site values as **required variables without defaults** (declared in
  `meta/argument_specs.yml`) and secrets as variables (`no_log: true` where they are
  used). Never hard-code a site value as a default, example or comment.
- The bare domain `home.arpa` is fine; a host name under it is not. Hostnames are
  variables defaulting to `<svc>.{{ homelab_domain }}`.
- In docs and examples use documentation values: IPs from RFC 5737 (`192.0.2.0/24`,
  `198.51.100.0/24`, `203.0.113.0/24`), `example.com`; or placeholders `<domain>`,
  `<lan-host>`, `<central-host>`, `<registry-host>`, `<tailnet>`, `<lan-ip>`,
  `<lan-subnet>`, `<email>`.
- Do not copy values from `infrastructure`, from cluster or host output (`kubectl`,
  logs, facts) or from 1Password into this repo, also not as examples in docs or
  commit messages. When moving a role in from `infrastructure`, every site value in it
  becomes a variable.
- The hooks in `.githooks/` (gitleaks + a private blocklist) must stay enabled
  (`core.hooksPath .githooks`, `homelab.blocklist` set). Never commit with
  `--no-verify`; if a hook flags a line, replace the value with a variable or a
  placeholder.

## Testing: Molecule with the Docker driver only

Molecule scenarios use the **Docker driver** and nothing else: never the `delegated`
driver, never an inventory that reaches a real host or cluster
(`scripts/check-structure.py` enforces the driver in CI). Do not run playbooks against
real hosts from this repo; `--syntax-check` and `--list-*` against the example inventory
are fine.

- Scenarios live in `extensions/molecule/<role>/` (Molecule's collection layout, run
  from the repo root: `molecule test -s <role>`). Platforms use the prebuilt systemd
  images from `scripts/molecule-images.sh` (`extensions/molecule/images/`: Ubuntu 24.04
  for node roles, Rocky Linux 10 for `central_*`); copy the platform block from
  `platform_smoke`, including `override_command: false` (otherwise the driver replaces
  systemd with a sleep loop).
- Driver collections: `extensions/molecule/requirements.yml`. Every scenario sets
  `prerun: false` and `.ansible-lint` sets `offline: true`: neither tool may install
  collections into `~/.ansible`, where the infrastructure workstation resolves them. With Rancher Desktop set
  `DOCKER_HOST` from the Docker context (README "Development").

## CI

`.github/workflows/ci.yml`: tier 1 (yamllint, ansible-lint production profile, the
structure check, collection build + install, `--syntax-check` of every playbook by FQCN
against `examples/inventory/`) and tier 2 (one Molecule job per scenario); `ci-ok` is the
required check. `gitleaks.yml` scans every branch; `release.yml` on a `v*` tag checks
`galaxy.yml`'s version and the CHANGELOG section and builds the tarball. Tool versions
are pinned in `.github/requirements-ci.txt`, actions by commit SHA with the tag as a
comment, test-image bases by digest; Dependabot bumps all three weekly.

Renovate (`renovate.json5`, ADR-0016) opens PRs for the role pins, each marked by a
`# renovate:` line above it (in templates `{# renovate: … #}`, which renders to
nothing), and for the vendored components. `revendor.yml` re-vendors a component on
its Renovate PR with `refresh-vendored.sh`; `prepare-release.yml` opens the PR
`release/next` after Renovate merges. Neither tags: sign with `sign-release.sh`. A new
pin gets a marker.

## Collection rules

- Releases are git tags `vX.Y.Z` (the maintainer signs them, ADR-0004; CI may prepare a
  routine one as a PR, ADR-0016); `galaxy.yml`'s `version` must
  equal the tag. SemVer is tied to the argument specs: a new required variable, a renamed
  variable or a changed inventory group is a major release. `CHANGELOG.md` is written by
  hand.
- Inventory groups `server`, `agent`, `central_server` are contract.
- Every role ships `meta/argument_specs.yml` and a README; every role has a component
  playbook `playbooks/<role>.yml` (`ziswb.homelab_platform.<role>`), except the
  dependency-only roles `central_podman` and `helm_preflight` (meta dependencies of
  other roles; their READMEs say so).
- Customization is composition: list inputs `<role>_extra_*`, optional features
  `<role>_*_enabled`, no hooks. One owner per Kubernetes resource.
- **No improvements while moving a role** in from `infrastructure`: the move must
  render the same result (zero-diff check on the consuming side). Improvements go to
  the backlog and come in a later release.
- Supported: k3s nodes on Ubuntu 24.04, the central host on Rocky Linux 10 (RHEL 10
  family); arm64 + amd64; k3s only. No Raspberry Pi assumptions.
- `docs/variables.md` lists the platform variables (`homelab_*`) and
  `docs/bring-up.md` the playbook order; update both when a role moves in.
- Decisions are in `docs/adr/` (check them before introducing a new pattern). An
  infrastructure ADR moves here iff it constrains a public role or the architecture,
  with an "Originally: infrastructure ADR-NNNN" line, site details removed, decision
  unchanged; the infrastructure copy is marked moved and frozen.
