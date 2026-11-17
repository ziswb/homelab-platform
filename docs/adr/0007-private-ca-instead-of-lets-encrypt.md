# 0007 — Use a private CA instead of Let's Encrypt

- Status: accepted (recorded retroactively; decision visible in the code)
- Date: 2026-08-06
- Originally: infrastructure ADR-0002

## Context

Nothing in the homelab is reachable from the internet and names under
`home.arpa` are not publicly resolvable, so ACME HTTP-01 challenges are
impossible and DNS-01 would require owning and wiring up a public domain. An
earlier Let's Encrypt ClusterIssuer existed; the `cert_manager` role deleted it.

## Decision

cert-manager runs a fully private chain: a self-signed bootstrap issuer signs a
10-year ECDSA root CA ("Homelab Root CA"), which backs the `homelab-ca`
ClusterIssuer. Every application Certificate references `homelab-ca` (1-year
duration, renewed 30 days early).

## Consequences

- No external dependency, works for any internal hostname.
- Every client device must trust the root CA manually; the reference site
  documents the steps per device type and deliberately does not automate them.
  The cluster nodes trust it through a role that installs the root certificate
  before k3s starts (`homelab_root_ca_trust`, planned for v1.1.0).
- The root CA private key lives only in the `homelab-root-ca-secret` in the
  cluster. Back it up outside the cluster (the reference site keeps it in its
  password manager, re-saved after a CA rotation), so losing the cluster does not
  mean re-issuing everything and re-trusting a new CA.
- No exceptions: services outside the usual ingress path, such as a container
  registry, also take their certificate from `homelab-ca`, and the cluster nodes
  trust the root CA before k3s starts. A service that reads its certificate only
  at start needs a restart after renewal (e.g. a hash of the certificate in its
  pod template). cert-manager's metrics are scraped, with alerts for expiring and
  not-Ready certificates.
