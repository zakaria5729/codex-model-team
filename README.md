# Codex Model Team

A reusable **project-local Codex setup** consisting of:

1. A real Codex plugin that packages the `model-team` workflow skill.
2. A repository marketplace entry that points to the plugin in this repository.
3. Project-local custom agent definitions under `.codex/agents/`.
4. An installer that adds the marketplace entry and agents to another project without installing agent configuration globally or overwriting existing settings.

## Model routing

| Role | Model | Reasoning |
|---|---|---|
| Main implementation | GPT-6.2 Sol | Medium; High for broader refactors |
| Architecture advisor | GPT-6.2 Astra | High |
| Local project explorer | GPT-6 Luna | High |
| Independent code reviewer | GPT-6.2 Astra | High |
| UI / screenshot reviewer | GPT-6.1 Terra | Medium |
| Documentation researcher | GPT-6 Luna | High |

Model IDs and recommendations follow current OpenAI model guidance. Availability depends on the Codex client, plan, and workspace settings. The installer preserves a project's already-configured primary model rather than replacing it.

## What is and is not inside the plugin

The plugin packages the reusable skill in:

```text
plugins/codex-model-team/
├── plugin.json
├── .codex-plugin/plugin.json   # compatibility fallback
└── skills/model-team/SKILL.md
```

Custom Codex agents are **not currently a portable plugin component**. They are separate project-local TOML files in `.codex/agents/`. This repository includes those files as templates, and the installer copies them into the target repository. This split follows Codex's current plugin and subagent formats.

## Install into a project (no Python or Git required on the target PC)

The Bash installer asks for the GitHub username/organization that owns the `codex-model-team` repository. It does **not** require you to edit `install.sh` or hardcode your username in the script.

Run it from the root of the project you want to configure:

```bash
./install.sh
```

The installer prompts:

```text
GitHub username or organization that owns the codex-model-team repository:
```

It then downloads the repository, installs the project-local agents, registers the marketplace, and saves the selected repository coordinates in:

```text
.codex/model-team.env
```

This file contains only public source information (owner, repository, and branch), not credentials. Commit it with the project if you want the same source coordinates remembered on other PCs.

### One-command remote installation (GitHub only; no Gist required)

The installer is hosted directly in this same GitHub repository. From the root of any target project, run:

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/codex-model-team/main/install.sh | bash
```

Replace `OWNER` with the GitHub username or organization that owns the `codex-model-team` repository. The script itself then asks which owner/repository should supply the full toolkit, and saves the selected owner, repository, and ref in `.codex/model-team.env`.

The URL owner identifies where the bootstrap installer is downloaded from. The interactive prompt selects the repository from which the full toolkit archive is downloaded. In the usual setup, both owners will be the same.

The installer opens `/dev/tty` for the prompt, so username input works even though the script itself is piped from `curl`. No Gist, Python, Node.js, Git, or separate toolkit clone is required on the target PC.

You can also provide the toolkit owner without an interactive prompt:

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/codex-model-team/main/install.sh | bash -s -- --username OWNER
```

### Change the GitHub owner at any time

Run the same GitHub Raw install command again from the target project. The installer reads the previously saved owner and shows it as the default:

```text
GitHub username or organization that owns the codex-model-team repository [old-owner]:
```

- Press **Enter** to keep the current owner.
- Type a new GitHub username/organization to change the source repository.

You can also change it without an interactive prompt:

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/codex-model-team/main/install.sh | bash -s -- --username NEW_GITHUB_OWNER
```

Or, when running the local script:

```bash
./install.sh --username NEW_GITHUB_OWNER
```

The installer downloads from the new owner, updates the Model Team marketplace source URL, and updates `.codex/model-team.env`. If the project already has a marketplace containing other plugins and `jq` is not installed, the installer safely refuses to rewrite that marketplace rather than risk damaging other entries. In that case, install `jq` and rerun the installer.

### Other options

```bash
./install.sh --help
./install.sh --username OWNER --repo codex-model-team --ref main
./install.sh --target /path/to/project --username OWNER
```

The installer requires Bash, `curl`, `tar`, and standard Unix utilities. It does not require Python, Git, Node.js, or a separate clone of this toolkit on the target PC. On Windows, use WSL or Git Bash.

The installer:

- copies custom agent TOML files into the target project's `.codex/agents/`;
- creates or updates `.agents/plugins/marketplace.json` to point to this repository's plugin through a Git-backed `git-subdir` source;
- enables the project-local plugin in `.codex/config.toml`;
- adds Sol / Medium main-model defaults only when the target project has not already configured them; and
- preserves existing agent files and existing project settings.

After installation, open Codex from the target project and trust it when prompted:

```bash
cd /path/to/your/project
codex
codex plugin marketplace list
```

Then ask Codex to use the Model Team skill:

```text
Use the Model Team skill for this task.
Have explorer investigate the current code, advisor assess the plan,
implement the agreed change, and reviewer inspect the final diff.
Use ui-reviewer only if visual inspection is relevant.
```

## Use on another PC

There are two separate pieces:

- The **target project's** `.agents/plugins/marketplace.json`, `.codex/config.toml`, and `.codex/agents/` are committed to the target project's Git repository. They travel with the project when cloned on another PC.
- The plugin package is fetched from the Git URL in that marketplace entry. It is cached by Codex under its local plugin cache on each PC. The project-scoped marketplace and enablement keep it associated with the project; the plugin cache itself is maintained by Codex in the user's home directory.

On another PC, install Codex CLI, sign in, clone the target project, trust it, and start Codex from the project directory. No global agent installation is needed. If the plugin needs refreshing, run the marketplace upgrade command shown by `codex plugin marketplace --help` / current Codex documentation.

## Update the toolkit

1. Update this repository and push the change to GitHub.
2. In the target project, refresh its marketplace source (Codex CLI supports `codex plugin marketplace upgrade`).
3. To update custom agents, rerun the installer. Existing agent files are not overwritten automatically; compare the generated update with your local files and merge intentionally.

## Uninstall from one project

- Remove the `codex-model-team@<marketplace-name>` plugin table from that project's `.codex/config.toml`.
- Remove the `codex-model-team` marketplace entry from `.agents/plugins/marketplace.json` (remove the marketplace file only if it becomes empty and the project does not use it for other plugins).
- Remove the agent TOML files from `.codex/agents/` after confirming they are the Model Team copies.

This does not remove Codex's user-level plugin cache. Codex manages that cache separately.

## Important permissions note

The explorer, advisor, reviewer, UI reviewer, and docs researcher are instructed not to modify files where appropriate. Custom agent instructions are not a security boundary: subagents inherit the parent session's sandbox and approval settings. Set the parent session's permission level appropriately before delegating.

## Repository marketplace for this toolkit itself

This repository already contains a local repo marketplace at `.agents/plugins/marketplace.json` and project settings in `.codex/config.toml`. That lets you test the plugin in this repository before distributing it.

## Validation

Maintainers can run the optional repository validation suite with Python 3:

```bash
python3 scripts/validate_repository.py
python3 -m unittest discover -s tests -v
```

Python is used only for repository-maintainer tests; end users installing Model Team do not need Python.

## References

- [Build Codex plugins](https://developers.openai.com/plugins/build/plugins)
- [Codex subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents)
- [Codex configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference)
- [OpenAI model catalog](https://developers.openai.com/api/docs/models)

## License

MIT. See [LICENSE](LICENSE).

## Public Plugins Directory submission

This repository marketplace is for source-based testing and distribution. The public Plugins Directory uses a separate ZIP upload and review flow. The public submission package is built from the contents of `plugins/codex-model-team/`, not from the entire repository.

Before uploading a public submission ZIP:

1. Replace `REPLACE WITH YOUR VERIFIED PUBLISHER NAME` in `plugins/codex-model-team/plugin.json` with the publisher name you intend to use.
2. Confirm the verified developer identity and submission permissions in your OpenAI organization settings.
3. Build the plugin-only ZIP with `zip -r codex-model-team-public-submission.zip plugin.json .codex-plugin skills assets` from inside `plugins/codex-model-team/`.
4. Upload it at <https://platform.openai.com/plugins>, resolve automated metadata/skills findings, submit for review, and publish after approval.

The package is skills-only: it has no MCP server and no lifecycle hooks. Skills-only submissions do not require MCP review cases or website/support/privacy/terms URLs. Do not add secrets or private credentials to the ZIP.

The public plugin can provide the Model Team workflow and agent setup instructions/templates. It cannot automatically make custom TOML subagents active merely by being installed; the user must invoke the setup skill in a project to create `.codex/agents/*.toml` there, then start a new Codex session in that project.

