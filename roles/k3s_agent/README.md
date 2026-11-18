# k3s_agent

A k3s agent joined through `api_endpoint`. Trimmed copy of k3s-ansible's agent
role; what was left out and the deviations (restart only on change, the install
script on every run so the unit's `--server` follows `api_endpoint`) are in
[`k3s_server`'s README](../k3s_server/README.md).

Playbooks: `ziswb.homelab_platform.k3s_cluster` or
`ziswb.homelab_platform.k3s_agent` (agents only).

## Variables

Required: `token` (secret), `api_endpoint`, `k3s_version` (k3s-ansible's
names). Optional: `agent_config_yaml`, `extra_agent_args`, `extra_service_envs`,
`extra_install_envs`, `api_port`, `k3s_agent_config_mode` (`0600`); see
`meta/argument_specs.yml`.

The token and `agent_config_yaml` go to `/etc/rancher/k3s/config.yaml` (mode
0600), as on the servers; upstream writes the token to
`k3s-agent.service.env`, which the install script empties on every run.
