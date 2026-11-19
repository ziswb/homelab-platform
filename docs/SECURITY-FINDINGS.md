# Security findings

Code-level security findings in this collection's roles, per
[ADR-0006](adr/0006-security-findings-published-once-fixed.md): a finding is
listed here once it is fixed, with the release that fixes it. Open findings stay
private until then; report a new one as described in
[SECURITY.md](../.github/SECURITY.md). Findings about a particular site's
configuration are not tracked here.

If you run a release older than the one that fixes a finding, upgrade.

| Finding | Affected | Fixed in |
|---|---|---|
| `k3s_server`: the tasks that build the server config printed it, cluster token included, at `-v` and above and on an error in them. | 0.4.0 to 1.5.0 | 1.5.1 |
| `k3s_server`: the admin kubeconfig fetched to the control node got the control node's umask (often world-readable) instead of 0600. | 0.4.0 to 1.5.0 | 1.5.1 |
