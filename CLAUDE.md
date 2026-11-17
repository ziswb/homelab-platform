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

Molecule scenarios use the **Docker driver** (Ubuntu 24.04 systemd container) and
nothing else: never the `delegated` driver, never an inventory that reaches a real host
or cluster. Do not run playbooks against real hosts from this repo; `--syntax-check` and
`--list-*` against the example inventory are fine.

## Collection rules

- Releases are git tags `vX.Y.Z` (the maintainer tags); `galaxy.yml`'s `version` must
  equal the tag. SemVer is tied to the argument specs: a new required variable, a renamed
  variable or a changed inventory group is a major release. `CHANGELOG.md` is written by
  hand.
- Inventory groups `server`, `agent`, `central_server` are contract.
- Every role ships `meta/argument_specs.yml` and a README; every role has a component
  playbook `playbooks/<role>.yml` (`ziswb.homelab_platform.<role>`).
- Customization is composition: list inputs `<role>_extra_*`, optional features
  `<role>_*_enabled`, no hooks. One owner per Kubernetes resource.
- **No improvements while moving a role** in from `infrastructure`: the move must
  render the same result (zero-diff check on the consuming side). Improvements go to
  the backlog and come in a later release.
- Supported: Ubuntu 24.04, arm64 + amd64, k3s only. No Raspberry Pi assumptions.
