#!/usr/bin/env python3
"""Install Codex Model Team into one target repository, without global changes."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from pathlib import Path
from typing import Any

PLUGIN_NAME = "codex-model-team"
PLUGIN_SUBDIR = "./plugins/codex-model-team"
DEFAULT_MODEL = "gpt-6.2-sol"
DEFAULT_REASONING = "medium"
DEFAULT_PLAN_REASONING = "high"
DEFAULT_MAX_AGENTS = 4


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Add the Codex Model Team repo marketplace and project-local agents "
            "to an existing project. No user-level Codex files are modified."
        )
    )
    parser.add_argument("target", type=Path, help="Path to the target project directory")
    parser.add_argument(
        "--repo-url",
        required=True,
        help="Git URL of the published codex-model-team repository",
    )
    parser.add_argument(
        "--ref",
        default="main",
        help="Git branch, tag, or commit reference for the plugin source (default: main)",
    )
    parser.add_argument(
        "--model",
        default=DEFAULT_MODEL,
        help=f"Default main-session model, added only when absent (default: {DEFAULT_MODEL})",
    )
    parser.add_argument(
        "--reasoning-effort",
        default=DEFAULT_REASONING,
        choices=["low", "medium", "high", "xhigh", "max"],
        help="Default main-session reasoning effort, added only when absent",
    )
    parser.add_argument(
        "--plan-reasoning-effort",
        default=DEFAULT_PLAN_REASONING,
        choices=["low", "medium", "high", "xhigh", "max"],
        help="Default plan-mode reasoning effort, added only when absent",
    )
    parser.add_argument(
        "--max-agents",
        type=int,
        default=DEFAULT_MAX_AGENTS,
        help="Maximum concurrent subagent threads, added only when absent",
    )
    return parser.parse_args()


def validate_repo_url(repo_url: str) -> None:
    allowed = repo_url.startswith(("https://", "ssh://", "git@"))
    if not allowed:
        raise ValueError(
            "--repo-url must be an HTTPS or SSH Git URL, for example "
            "https://github.com/OWNER/codex-model-team.git"
        )
    if any(char in repo_url for char in "\n\r\t"):
        raise ValueError("--repo-url contains invalid whitespace")


def load_marketplace(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {
            "name": PLUGIN_NAME,
            "interface": {"displayName": "Codex Model Team"},
            "plugins": [],
        }

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"Existing marketplace JSON is invalid: {path}: {exc}") from exc

    if not isinstance(data, dict) or not isinstance(data.get("name"), str):
        raise ValueError(f"Existing marketplace must be a JSON object with a string 'name': {path}")
    if not isinstance(data.get("plugins", []), list):
        raise ValueError(f"Existing marketplace 'plugins' must be an array: {path}")
    data.setdefault("interface", {})
    if not isinstance(data["interface"], dict):
        data["interface"] = {}
    data.setdefault("plugins", [])
    return data


def update_marketplace(target: Path, repo_url: str, ref: str) -> str:
    marketplace_path = target / ".agents" / "plugins" / "marketplace.json"
    marketplace_path.parent.mkdir(parents=True, exist_ok=True)
    marketplace = load_marketplace(marketplace_path)
    marketplace_name = marketplace["name"]

    entry = {
        "name": PLUGIN_NAME,
        "source": {
            "source": "git-subdir",
            "url": repo_url,
            "path": PLUGIN_SUBDIR,
            "ref": ref,
        },
        "policy": {
            "installation": "AVAILABLE",
            "authentication": "ON_INSTALL",
        },
        "category": "Productivity",
    }

    plugins = marketplace["plugins"]
    matching_indices = [
        index
        for index, plugin in enumerate(plugins)
        if isinstance(plugin, dict) and plugin.get("name") == PLUGIN_NAME
    ]
    if matching_indices:
        # Replace only our own named marketplace entry; leave other plugins intact.
        first = matching_indices[0]
        plugins[first] = entry
        for index in reversed(matching_indices[1:]):
            del plugins[index]
    else:
        plugins.append(entry)

    interface = marketplace["interface"]
    interface.setdefault("displayName", "Codex Model Team")
    marketplace["plugins"] = plugins
    marketplace_path.write_text(
        json.dumps(marketplace, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    return marketplace_name


def first_table_start(text: str) -> int:
    match = re.search(r"(?m)^\s*\[\[?[^\]]+\]\]?\s*(?:#.*)?$", text)
    return match.start() if match else len(text)


def add_missing_root_defaults(text: str, defaults: dict[str, str]) -> tuple[str, list[str]]:
    boundary = first_table_start(text)
    preamble = text[:boundary]
    additions: list[str] = []
    added: list[str] = []

    for key, value in defaults.items():
        if re.search(rf"(?m)^\s*{re.escape(key)}\s*=", preamble):
            continue
        additions.append(f'{key} = "{value}"')
        added.append(key)

    if additions:
        prefix = "\n".join(additions) + "\n\n"
        text = prefix + text
    return text, added


def ensure_table_settings(
    text: str,
    table_header: str,
    settings: dict[str, str],
) -> tuple[str, list[str], dict[str, str]]:
    """Add missing key/value settings to a TOML table without rewriting existing values."""
    header_re = re.compile(r"(?m)^" + re.escape(table_header) + r"\s*(?:#.*)?$")
    match = header_re.search(text)
    added: list[str] = []
    existing: dict[str, str] = {}

    if match:
        next_table = re.search(r"(?m)^\s*\[\[?[^\]]+\]\]?\s*(?:#.*)?$", text[match.end():])
        table_end = match.end() + next_table.start() if next_table else len(text)
        body = text[match.end():table_end]
        additions: list[str] = []
        for key, value in settings.items():
            key_match = re.search(rf"(?m)^\s*{re.escape(key)}\s*=\s*(.*?)\s*(?:#.*)?$", body)
            if key_match:
                existing[key] = key_match.group(1).strip()
            else:
                additions.append(f"{key} = {value}")
                added.append(key)
        if additions:
            insertion = "\n" + "\n".join(additions) + "\n"
            text = text[:match.end()] + insertion + text[match.end():]
        return text, added, existing

    block = "\n".join([table_header, *[f"{key} = {value}" for key, value in settings.items()]])
    text = text.rstrip() + "\n\n" + block + "\n"
    added.extend(settings.keys())
    return text, added, existing


def update_project_config(target: Path, marketplace_name: str, args: argparse.Namespace) -> list[str]:
    config_path = target / ".codex" / "config.toml"
    config_path.parent.mkdir(parents=True, exist_ok=True)
    text = config_path.read_text(encoding="utf-8") if config_path.exists() else ""
    changes: list[str] = []

    # Defaults are added only when a project has not already chosen values.
    text, root_added = add_missing_root_defaults(
        text,
        {
            "model": args.model,
            "model_reasoning_effort": args.reasoning_effort,
            "plan_mode_reasoning_effort": args.plan_reasoning_effort,
        },
    )
    if root_added:
        changes.append("added project defaults: " + ", ".join(root_added))

    text, agent_added, _agent_existing = ensure_table_settings(
        text,
        "[agents]",
        {"max_concurrent_threads_per_session": str(args.max_agents)},
    )
    if agent_added:
        changes.append("added [agents]." + ", [agents].".join(agent_added))

    plugin_table = f'[plugins."{PLUGIN_NAME}@{marketplace_name}"]'
    text, plugin_added, plugin_existing = ensure_table_settings(
        text,
        plugin_table,
        {"enabled": "true"},
    )
    if plugin_added:
        changes.append(f"enabled {PLUGIN_NAME} for this project")
    elif plugin_existing.get("enabled", "").lower() == "false":
        changes.append(
            f"WARNING: {plugin_table} is explicitly disabled; set enabled = true to activate it"
        )

    # Validate TOML before writing when this Python has tomllib available.
    try:
        import tomllib  # Python 3.11+

        tomllib.loads(text)
    except ImportError:
        pass
    except tomllib.TOMLDecodeError as exc:
        raise ValueError(
            f"Refusing to write invalid TOML to {config_path}. Resolve the existing config first: {exc}"
        ) from exc

    config_path.write_text(text, encoding="utf-8")
    return changes


def copy_agents(source_root: Path, target: Path) -> tuple[list[str], list[str]]:
    source_agents = source_root / ".codex" / "agents"
    target_agents = target / ".codex" / "agents"
    target_agents.mkdir(parents=True, exist_ok=True)

    copied: list[str] = []
    skipped: list[str] = []
    for source_file in sorted(source_agents.glob("*.toml")):
        destination = target_agents / source_file.name
        if destination.exists():
            if destination.read_bytes() == source_file.read_bytes():
                skipped.append(f"{source_file.name} (already current)")
            else:
                skipped.append(f"{source_file.name} (already exists; preserved, review manually)")
            continue
        shutil.copy2(source_file, destination)
        copied.append(source_file.name)
    return copied, skipped


def main() -> int:
    args = parse_args()
    try:
        validate_repo_url(args.repo_url)
        if args.max_agents < 1:
            raise ValueError("--max-agents must be at least 1")

        source_root = Path(__file__).resolve().parents[1]
        target = args.target.expanduser().resolve()
        if not target.exists() or not target.is_dir():
            raise ValueError(f"Target project directory does not exist: {target}")
        if target == source_root:
            raise ValueError("Target cannot be the Model Team source repository itself")

        copied, skipped = copy_agents(source_root, target)
        marketplace_name = update_marketplace(target, args.repo_url, args.ref)
        config_changes = update_project_config(target, marketplace_name, args)

        print("Codex Model Team project installation complete.\n")
        print(f"Target:      {target}")
        print(f"Marketplace: {target / '.agents/plugins/marketplace.json'}")
        print(f"Plugin ref:  {args.repo_url} @ {args.ref}")
        print(f"Plugin key:  {PLUGIN_NAME}@{marketplace_name}")
        print(f"Agents copied: {', '.join(copied) if copied else 'none'}")
        if skipped:
            print("Agents preserved:")
            for item in skipped:
                print(f"  - {item}")
        print("Config:")
        for item in config_changes or ["no changes needed; existing settings preserved"]:
            print(f"  - {item}")
        print("\nNext: open Codex from this project, trust it, and check:")
        print("  codex plugin marketplace list")
        print("Then ask Codex to use the Model Team skill.")
        print("\nNote: Codex maintains its plugin package cache under the user Codex directory;")
        print("the marketplace declaration, enablement, and custom agents are project-scoped.")
        return 0
    except (OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
