from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
import tomllib

ROOT = Path(__file__).resolve().parents[1]
INSTALLER = ROOT / "scripts" / "install_to_project.py"
REPO_URL = "https://github.com/example/codex-model-team.git"


class InstallerTests(unittest.TestCase):
    def test_installs_project_local_agents_marketplace_and_config(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp) / "sample-project"
            project.mkdir()
            result = subprocess.run(
                [sys.executable, str(INSTALLER), str(project), "--repo-url", REPO_URL],
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr + result.stdout)

            config = tomllib.loads((project / ".codex/config.toml").read_text())
            self.assertEqual(config["model"], "gpt-6.2-sol")
            self.assertEqual(config["model_reasoning_effort"], "medium")
            self.assertEqual(config["agents"]["max_concurrent_threads_per_session"], 4)
            self.assertTrue(config["plugins"]["codex-model-team@codex-model-team"]["enabled"])
            self.assertTrue((project / ".codex/agents/advisor.toml").is_file())
            self.assertTrue((project / ".codex/agents/explorer.toml").is_file())

            marketplace = json.loads(
                (project / ".agents/plugins/marketplace.json").read_text()
            )
            plugin = marketplace["plugins"][0]
            self.assertEqual(plugin["name"], "codex-model-team")
            self.assertEqual(plugin["source"]["source"], "git-subdir")
            self.assertEqual(plugin["source"]["url"], REPO_URL)

    def test_preserves_existing_model_and_merges_marketplace(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp) / "sample-project"
            (project / ".codex").mkdir(parents=True)
            (project / ".agents/plugins").mkdir(parents=True)
            (project / ".codex/config.toml").write_text(
                'model = "gpt-6.1-sol"\n\n[agents]\n'
                "max_concurrent_threads_per_session = 2\n"
            )
            (project / ".agents/plugins/marketplace.json").write_text(
                json.dumps(
                    {
                        "name": "team-marketplace",
                        "plugins": [
                            {
                                "name": "existing-plugin",
                                "source": {"source": "local", "path": "./plugins/existing"},
                                "policy": {
                                    "installation": "AVAILABLE",
                                    "authentication": "ON_INSTALL",
                                },
                                "category": "Productivity",
                            }
                        ],
                    }
                )
            )

            result = subprocess.run(
                [sys.executable, str(INSTALLER), str(project), "--repo-url", REPO_URL],
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
            config = tomllib.loads((project / ".codex/config.toml").read_text())
            self.assertEqual(config["model"], "gpt-6.1-sol")
            self.assertEqual(config["agents"]["max_concurrent_threads_per_session"], 2)
            self.assertTrue(
                config["plugins"]["codex-model-team@team-marketplace"]["enabled"]
            )
            marketplace = json.loads(
                (project / ".agents/plugins/marketplace.json").read_text()
            )
            self.assertEqual(marketplace["name"], "team-marketplace")
            names = [entry["name"] for entry in marketplace["plugins"]]
            self.assertIn("existing-plugin", names)
            self.assertIn("codex-model-team", names)

    def test_second_run_does_not_duplicate_marketplace_entry(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp) / "sample-project"
            project.mkdir()
            command = [sys.executable, str(INSTALLER), str(project), "--repo-url", REPO_URL]
            first = subprocess.run(command, check=False, capture_output=True, text=True)
            second = subprocess.run(command, check=False, capture_output=True, text=True)
            self.assertEqual(first.returncode, 0, first.stderr + first.stdout)
            self.assertEqual(second.returncode, 0, second.stderr + second.stdout)
            marketplace = json.loads(
                (project / ".agents/plugins/marketplace.json").read_text()
            )
            self.assertEqual(
                sum(entry["name"] == "codex-model-team" for entry in marketplace["plugins"]),
                1,
            )
            tomllib.loads((project / ".codex/config.toml").read_text())


if __name__ == "__main__":
    unittest.main()
