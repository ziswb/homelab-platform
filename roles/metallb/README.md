# metallb

MetalLB in L2 mode: the vendored upstream release (`files/metallb-native.yaml`,
namespace `metallb-system`, Apache-2.0, see NOTICE), one IPAddressPool
`default-pool` and an L2Advertisement for it, all applied server-side.

The pool has `autoAssign: false`: a Service gets an address only when it asks for
one with the annotation `metallb.io/loadBalancerIPs` (the platform keeps those
addresses in `homelab_lb_ips`, see `docs/variables.md`). A LoadBalancer Service
without one stays pending instead of taking a random address.

Playbook: `ziswb.homelab_platform.metallb` (runs on `localhost` against the
cluster in the current kubeconfig context). k3s's own ServiceLB must be off
(`--disable servicelb`).

## Variables

| Variable | Required | Meaning |
|---|---|---|
| `metallb_addresses` | yes | The pool, as ranges or CIDRs, e.g. `["192.0.2.10-192.0.2.50"]`. |
