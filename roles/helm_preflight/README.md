# helm_preflight

Asserts that the helm the Helm-based roles will run is supported, before any
chart task starts: resolves `helm_binary` from PATH (and prints the path),
checks its version against `[helm_version_min, helm_version_max)` and, with
Helm 4, that the helm-diff plugin is at least `helm_diff_version_min`. Without
helm-diff, chart tasks still run but `--check` shows no diffs and `changed`
is unreliable, so a missing plugin warns.

No playbook: `cert_manager`, `cnpg_operator` and `traefik_install` (and a site's
own Helm roles)
list it as a meta dependency, `ziswb.homelab_platform.helm_preflight`.

## Variables

| Variable | Default | Meaning |
|---|---|---|
| `helm_binary` | `helm` | helm executable (name or path); the Helm roles use it too |
| `helm_version_min` | `"4.2.0"` | lowest supported version |
| `helm_version_max` | `"5.0.0"` | first unsupported version |
| `helm_diff_version_min` | `"3.14.0"` | lowest helm-diff with Helm 4 |

To try another helm once: `-e helm_binary=/path/to/helm -e helm_version_min=...`.
