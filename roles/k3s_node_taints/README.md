# k3s_node_taints

Taints on existing nodes, through the API. K3s applies `node-taint` from its
config only when a node first registers; this role covers nodes that are
already in the cluster. It never removes a taint: a dropped entry must also be
removed from the node by hand.

Playbooks: `ziswb.homelab_platform.k3s_cluster` (last play) or
`ziswb.homelab_platform.k3s_node_taints`; both run on the control node against
the cluster in the current kubeconfig context.

## Variables

`k3s_node_taints` (default `[]`):

```yaml
k3s_node_taints:
  - node: node-01
    taints:
      - key: example.com/slow-disk
        effect: PreferNoSchedule
```
