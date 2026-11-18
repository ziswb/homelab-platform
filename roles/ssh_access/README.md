# ssh_access

SSH login by public key only, for one user, on Ubuntu and RHEL-family hosts:

- the user's `authorized_keys` holds exactly `ssh_access_authorized_keys`
  (other keys are removed);
- the sshd drop-in `/etc/ssh/sshd_config.d/10-homelab.conf` turns on public key
  authentication and turns off password, keyboard-interactive and root login
  (first value wins in sshd_config, and `10-` sorts before the distributions'
  `50-*.conf`);
- `sshd -t`, a reload, the effective settings (`sshd -T`) asserted, and a new
  login from the control machine (`ssh … <user>@<inventory_hostname> true`,
  with the agent's keys, not Ansible's multiplexed connection).

If any of it fails, the previous `authorized_keys` and drop-in are put back over
the connection Ansible still holds, sshd is reloaded and the play stops. Run it
with `serial: 1` so a failure stops before the next host.

Playbook: `ziswb.homelab_platform.ssh_access` (hosts `server`, `agent`,
`central_server`, `serial: 1`; narrow it with `--limit`).

## Variables

| Variable | Required | Meaning |
|---|---|---|
| `ssh_access_user` | yes | The login user. |
| `ssh_access_authorized_keys` | yes | The complete list of public keys. |
| `ssh_access_verify_login` | no (`true`) | Try a fresh login after the change. |
