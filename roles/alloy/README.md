# alloy

Grafana Alloy as a DaemonSet in namespace `logging` (also on control-plane
nodes): tails every pod log under `/var/log/pods`, parses the CRI format, joins
multi-line entries (a new entry starts with a date or a `{`), labels each line
with `namespace`, `pod`, `container`, `job="kubernetes-pods"` and `node`, and
pushes to Loki at `homelab_loki_url`. Read positions persist on the host in
`/var/lib/alloy/data`.

Playbook: `ziswb.homelab_platform.alloy` (on `localhost`).

## Variables

| Variable | Required | Meaning |
|---|---|---|
| `homelab_loki_url` | yes | Loki base URL, e.g. `http://loki.example.com:3100` |
