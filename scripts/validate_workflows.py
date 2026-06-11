#!/usr/bin/env python3

from __future__ import annotations

import sys
from pathlib import Path

import yaml


class GithubActionsLoader(yaml.SafeLoader):
    pass


for first_letter, resolvers in list(GithubActionsLoader.yaml_implicit_resolvers.items()):
    GithubActionsLoader.yaml_implicit_resolvers[first_letter] = [
        (tag, regexp)
        for tag, regexp in resolvers
        if tag != "tag:yaml.org,2002:bool"
    ]


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: python3 scripts/validate_workflows.py <workflow...>", file=sys.stderr)
        return 1

    for raw_path in sys.argv[1:]:
        path = Path(raw_path)
        if not path.is_file():
            print(f"Workflow file not found: {path}", file=sys.stderr)
            return 1

        with path.open("r", encoding="utf-8") as handle:
            try:
                data = yaml.load(handle, Loader=GithubActionsLoader)
            except yaml.YAMLError as exc:
                print(f"Invalid YAML in {path}: {exc}", file=sys.stderr)
                return 1

        if not isinstance(data, dict):
            print(f"Workflow root must be a mapping: {path}", file=sys.stderr)
            return 1

        if "name" not in data:
            print(f"Workflow missing name field: {path}", file=sys.stderr)
            return 1

        if "on" not in data:
            print(f"Workflow missing on field: {path}", file=sys.stderr)
            return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
