# cnpg_operator

The CloudNativePG operator from its chart, straight from the repository URL
(no `helm repo add`, so `--check` works on a fresh workstation), in namespace
`cnpg-system`. The chart's CRDs carry `helm.sh/resource-policy: keep`, so
removing the release leaves Clusters and their data in place. The role waits
until the webhook answers: Clusters are rejected before that.

Database Clusters (and their PostgreSQL image pins) are the site's own.

Playbook: `ziswb.homelab_platform.cnpg_operator` (on `localhost`). Depends on
`helm_preflight`.

## Variables

| Variable | Default | Meaning |
|---|---|---|
| `cnpg_operator_chart_version` | `"0.29.1"` | chart version (operator 1.30.1) |
| `helm_binary` | `helm` | from `helm_preflight` |

After an operator bump, install the matching `kubectl cnpg` plugin.
