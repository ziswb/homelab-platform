# prereq

Prepares an Ubuntu 24.04 node for k3s: asserts Ubuntu and ansible-core 2.15 or
later, installs `policycoreutils` (the k3s install script restores SELinux
contexts with it), enables IPv4 forwarding and, on hosts with IPv6 addresses,
IPv6 forwarding. While UFW is active it opens the k3s ports (API, etcd between
servers, Spegel, Flannel VXLAN and WireGuard, kubelet) and allows the cluster
and service CIDRs; an inactive UFW is left alone.

Trimmed copy of k3s-ansible's `prereq` (see
[`k3s_server`'s README](../k3s_server/README.md)).

Playbooks: `ziswb.homelab_platform.k3s_cluster` (first play) or
`ziswb.homelab_platform.prereq`.

## Variables

None required. `api_port`, `server_group`, `manage_firewall` and
`server_config_yaml` (for the CIDRs) are optional; see
`meta/argument_specs.yml`.
