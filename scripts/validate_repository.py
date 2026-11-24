#!/usr/bin/env python3
"""Validate the generated Codex Model Team repository structure."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def main() -> int:
    marketplace_path = ROOT / ".agents/plugins/marketplace.json"
    plugin_path = ROOT / "plugins/codex-model-team/plugin.json"
    compatibility_path = ROOT / "plugins/codex-model-team/.codex-plugin/plugin.json"
    skill_path = ROOT / "plugins/codex-model-team/skills/model-team/SKILL.md"
    config_path = ROOT / ".codex/config.toml"

    for required in [marketplace_path, plugin_path, compatibility_path, skill_path, config_path]:
        if not required.is_file():
            fail(f"missing required file: {required.relative_to(ROOT)}")

    marketplace = json.loads(marketplace_path.read_text(encoding="utf-8"))
    plugin = json.loads(plugin_path.read_text(encoding="utf-8"))
    compatibility = json.loads(compatibility_path.read_text(encoding="utf-8"))

    if marketplace.get("name") != "codex-model-team":
        fail("unexpected marketplace name")
    entries = [item for item in marketplace.get("plugins", []) if item.get("name") == "codex-model-team"]
    if len(entries) != 1:
        fail("marketplace must contain exactly one codex-model-team entry")
    if entries[0].get("source", {}).get("source") != "local":
        fail("source repository marketplace should point to its local plugin folder")
    if plugin.get("name") != "codex-model-team" or plugin.get("version") != "0.1.0":
        fail("plugin root manifest identity/version mismatch")
    if compatibility.get("name") != plugin.get("name"):
        fail("compatibility manifest name mismatch")
    if "name: model-team" not in skill_path.read_text(encoding="utf-8"):
        fail("skill frontmatter must declare name: model-team")

    try:
        import tomllib
    except ImportError:
        print("NOTE: TOML validation skipped (requires Python 3.11+ tomllib).")
    else:
        tomllib.loads(config_path.read_text(encoding="utf-8"))
        for agent_file in sorted((ROOT / ".codex/agents").glob("*.toml")):
            data = tomllib.loads(agent_file.read_text(encoding="utf-8"))
            for key in ("name", "description", "developer_instructions"):
                if key not in data:
                    fail(f"{agent_file.name} is missing required key {key}")

    print("PASS: marketplace JSON, plugin manifests, skill layout, project TOML, and agent TOML files are valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
