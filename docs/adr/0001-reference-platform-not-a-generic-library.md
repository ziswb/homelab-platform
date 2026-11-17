# 0001 — A reference platform, not a generic library

- Status: accepted 2026-11-17
- Date: 2026-11-17

## Context

The roles in this collection were written for one homelab and run it: k3s on
small nodes, a central host with storage, logs and databases, CloudNativePG, a
private CA with cert-manager, Traefik and MetalLB, Prometheus monitoring. Making
them public raises the question every shared Ansible collection answers
implicitly: does it adapt to any environment (every OS, every distribution, every
ingress controller, all choices behind variables), or does it describe one
architecture well?

A generic library needs a variable for every choice and tests for every
combination. The roles' value is the opposite: the choices were made, tried in
operation and written down (the ADRs here).

## Decision

**The collection is a reference platform:** one opinionated architecture, its
decisions documented as ADRs, its roles built to run together. The central host
and its roles (`central_*`) belong to it as much as the cluster roles.

Supported, and tested, is exactly that architecture:

- k3s nodes (`server`, `agent`) on Ubuntu 24.04 LTS; the central host
  (`central_server`) on Rocky Linux 10 (RHEL 10 family);
- arm64 and amd64, with no assumption about the board (no Raspberry Pi specifics
  in public roles);
- k3s only.

Variables exist for what differs between sites (names, addresses, paths, secrets,
versions), not for alternative architectures.

## Consequences

- A request to support another OS, distribution or component is a change of the
  architecture, decided in an ADR, not a variable added on the side.
- Site-specific additions stay outside, as the site's own roles (ADR-0005).
- Documentation explains the platform as a whole (bring-up order, variable
  vocabulary), not each role as a standalone product.
