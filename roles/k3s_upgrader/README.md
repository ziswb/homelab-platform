# k3s_upgrader

k3s upgrades by the
[system-upgrade-controller](https://docs.k3s.io/upgrades/automated) (ADR-0010).
Applies the vendored controller release and its Plan CRD (`files/`, namespace
`system-upgrade`) and two Plans that follow the k3s `stable` channel:

- `control-node-plan`: the servers, one at a time, cordoned;
- `worker-node-plan`: the agents, one at a time, cordoned, after the servers.

All objects are applied server-side (field manager `ansible`). Runs on the
control node against the cluster in the current kubeconfig context.

Playbooks: `ziswb.homelab_platform.k3s_cluster` (last play) or
`ziswb.homelab_platform.k3s_upgrader`.

The files in `files/` are upstream release YAML (Apache-2.0, see NOTICE); their
header names the version and URL.

## Variables

None.
