#!/usr/bin/env python3
"""Structure checks for the collection (tier 1 CI; runs locally too).

- every role under roles/ has README.md and meta/argument_specs.yml;
- every playbook under playbooks/ is a .yml file;
- every Molecule scenario (extensions/molecule/*/molecule.yml) uses the Docker
  driver: never `delegated`, which would run against a real host.

Run from the repository root: scripts/check-structure.py
"""
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent


def check_roles(errors):
    roles = ROOT / "roles"
    for role in sorted(p for p in roles.iterdir() if p.is_dir()) if roles.is_dir() else []:
        for required in ("README.md", "meta/argument_specs.yml"):
            if not (role / required).is_file():
                errors.append(f"roles/{role.name}: missing {required}")


def check_playbooks(errors):
    playbooks = ROOT / "playbooks"
    for path in sorted(playbooks.iterdir()) if playbooks.is_dir() else []:
        if path.is_file() and path.name != ".gitkeep" and path.suffix != ".yml":
            errors.append(f"playbooks/{path.name}: playbooks end in .yml")


def check_molecule(errors):
    for path in sorted((ROOT / "extensions" / "molecule").glob("*/molecule.yml")):
        rel = path.relative_to(ROOT)
        with path.open(encoding="utf-8") as fh:
            config = yaml.safe_load(fh) or {}
        driver = (config.get("driver") or {}).get("name")
        if driver != "docker":
            errors.append(f"{rel}: driver is {driver!r}; only the Docker driver is allowed")
        for platform in config.get("platforms") or []:
            if not platform.get("image"):
                errors.append(f"{rel}: platform {platform.get('name')!r} has no image")


def main():
    errors = []
    check_roles(errors)
    check_playbooks(errors)
    check_molecule(errors)
    for error in errors:
        print(f"check-structure: {error}", file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
