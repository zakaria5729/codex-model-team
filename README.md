
# Codex Model Team

A reusable, project-local multi-agent setup for OpenAI Codex.

Codex Model Team provides specialized agents for implementation, architecture advice, code exploration, independent code review, UI review, and documentation research.

The setup is designed to be installed directly into any project without modifying global Codex configuration.

## Features

- Project-local Codex configuration
- Specialized custom agents
- Reusable Model Team workflow skill
- GitHub-based plugin marketplace
- One-command installation
- No Python, Node.js, or Git required on the target machine
- Existing project settings and agent files are preserved
- Custom GitHub repository owner support

## Model Team

| Role | Model | Reasoning |
|---|---|---|
| Main implementation | GPT-6.2 Sol | Medium |
| Architecture advisor | GPT-6.2 Astra | High |
| Local project explorer | GPT-6 Luna | High |
| Independent code reviewer | GPT-6.2 Astra | High |
| UI / screenshot reviewer | GPT-6.1 Terra | Medium |
| Documentation researcher | GPT-6 Luna | High |

Model availability and supported reasoning levels depend on the Codex client, account, and workspace configuration.

The installer uses Sol / Medium as the default main model only when the project does not already have a model configured.

## Architecture

The repository contains:

```text
codex-model-team/
│
├── .codex/
│   ├── config.toml
│   └── agents/
│       ├── advisor.toml
│       ├── explorer.toml
│       ├── reviewer.toml
│       ├── ui-reviewer.toml
│       └── docs-researcher.toml
│
├── .agents/
│   └── plugins/
│       └── marketplace.json
│
├── plugins/
│   └── codex-model-team/
│       ├── plugin.json
│       ├── .codex-plugin/
│       └── skills/
│           └── model-team/
│               └── SKILL.md
│
├── scripts/
├── tests/
├── install.sh
└── README.md
```

### Plugin and custom agents

The plugin packages the reusable `model-team` workflow skill.

Custom Codex agents are maintained separately as project-local TOML files under `.codex/agents/`.

The installer copies those agent definitions into the target project.

## Installation

### Requirements

- OpenAI Codex CLI
- Bash
- curl
- tar

No Python, Node.js, Git, or separate toolkit clone is required on the target machine.

### One-command installation

The default GitHub repository is:

https://github.com/zakaria5729/codex-model-team

Open your terminal inside the project where you want to install Model Team.

Run:

```bash
curl -fsSL https://raw.githubusercontent.com/zakaria5729/codex-model-team/main/install.sh | bash
```

That's it.

The installer automatically uses:

```text
GitHub owner: zakaria5729
Repository:   codex-model-team
Branch:       main
```

No username prompt is required.

### Install into a specific directory

You can also provide a target directory:

```bash
curl -fsSL https://raw.githubusercontent.com/zakaria5729/codex-model-team/main/install.sh \
  | bash -s -- --target /path/to/your/project
```

## Use another GitHub owner

The default owner is `zakaria5729`.

If you fork this repository or maintain your own copy, you can override the owner:

```bash
curl -fsSL https://raw.githubusercontent.com/zakaria5729/codex-model-team/main/install.sh \
  | bash -s -- --username YOUR_GITHUB_USERNAME
```

You can also use another repository name or branch:

```bash
curl -fsSL https://raw.githubusercontent.com/zakaria5729/codex-model-team/main/install.sh \
  | bash -s -- \
      --username YOUR_GITHUB_USERNAME \
      --repo codex-model-team \
      --ref main
```

The selected repository coordinates are saved in:

```text
.codex/model-team.env
```

Example:

```text
owner=zakaria5729
repo=codex-model-team
ref=main
```

The file contains public repository information only. It does not contain credentials or secrets.

### Change the owner later

You can change the repository owner at any time by rerunning the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/zakaria5729/codex-model-team/main/install.sh \
  | bash -s -- --username NEW_OWNER
```

The installer updates the saved repository coordinates and marketplace source.

## What gets installed?

The installer creates or updates:

```text
your-project/
│
├── .codex/
│   ├── config.toml
│   ├── model-team.env
│   └── agents/
│       ├── advisor.toml
│       ├── explorer.toml
│       ├── reviewer.toml
│       ├── ui-reviewer.toml
│       └── docs-researcher.toml
│
└── .agents/
    └── plugins/
        └── marketplace.json
```

### Existing project protection

The installer is designed to preserve existing project configuration.

- Existing agent files are not overwritten.
- Existing main model settings are preserved.
- Existing project-level Codex settings are preserved.
- Existing marketplace plugins are retained when `jq` is available for safe JSON merging.
- If an existing marketplace needs merging but `jq` is unavailable, the installer stops instead of overwriting it.

The installer does not modify:

```text
~/.codex/config.toml
~/.codex/agents/
```

All agent configuration is project-local.

## Start using Model Team

After installation:

```bash
cd /path/to/your/project
codex
```

Trust the project if Codex asks.

Check the marketplace:

```bash
codex plugin marketplace list
```

Then ask Codex:

```text
Use the Model Team skill for this task.

1. Have explorer inspect the relevant codebase.
2. Have advisor analyze the architecture and recommend an approach.
3. Have implementation implement the agreed changes.
4. Have reviewer independently review the final diff.
5. Fix important findings and run relevant tests.

Use ui-reviewer when visual inspection is relevant.
Use docs-researcher when external documentation research is needed.

Provide a final summary with changed files, tests, and review findings.
```

## Using Model Team on another PC

The target project's following files can be committed to its Git repository:

- `.codex/config.toml`
- `.codex/agents/`
- `.codex/model-team.env`
- `.agents/plugins/marketplace.json`

On another PC:

1. Install Codex CLI.
2. Sign in to Codex.
3. Clone the target project.
4. Trust the project if prompted.
5. Start Codex from the project directory.

The plugin package is fetched and cached by Codex on each PC.

Your Codex authentication is not included in the project repository.

## Update Model Team

To update the custom agent templates, rerun the installer.

Existing agent files are intentionally preserved. Review and merge template changes when necessary.

To refresh the plugin marketplace source, use the marketplace commands supported by your installed Codex CLI:

```bash
codex plugin marketplace --help
```

## Uninstall

To remove Model Team from a project:

1. Remove the Model Team plugin entry from `.codex/config.toml`.
2. Remove its marketplace entry from `.agents/plugins/marketplace.json`.
3. Remove the Model Team agent TOML files from `.codex/agents/`.
4. Remove `.codex/model-team.env`.

Do not delete a marketplace file if it contains other plugins you still use.

Codex manages its local plugin cache separately.

## Repository validation

Maintainers can run the repository validation suite:

```bash
python3 scripts/validate_repository.py
python3 -m unittest discover -s tests -v
```

Python is only needed for maintainer tests, not for end-user installation.

## Contributing

Issues and pull requests are welcome.

If you fork this repository, use your own GitHub owner with the `--username` option.

## License

MIT License. See [LICENSE](LICENSE).
```

---

## 3. GitHub-এ কী করবে

<box border radius="lg" padding={3} gap={3}>
  <row align="center" gap={2}>
    <icon name="github" size="xl"/>
    **File update checklist**
  </row>
  <list marker="number" gap={2}>
    <list-item>
      [install.sh Edit](https://github.com/zakaria5729/codex-model-team/edit/main/install.sh) খুলবে।
      
      পুরো content replace করে Commit changes করবে।
    </list-item>
    <list-item>
      [README.md Edit](https://github.com/zakaria5729/codex-model-team/edit/main/README.md) খুলবে।
      
      পুরো content replace করে Commit changes করবে।
    </list-item>
    <list-item>
      দুটো ফাইলই `main` branch-এ commit হয়েছে কিনা নিশ্চিত করবে।
    </list-item>
  </list>
</box>

## 4. Installation test

Commit করার পর অন্য একটি project directory-তে গিয়ে এই command চালিয়ে পরীক্ষা করতে পারো:

```bash
curl -fsSL https://raw.githubusercontent.com/zakaria5729/codex-model-team/main/install.sh | bash
```

Expected output-এ দেখতে পাবে:

```text
Repository : zakaria5729/codex-model-team
Branch     : main

==> Downloading repository...
==> Installing project-local agents...
==> Registering plugin marketplace...
==> Configuring Codex...

Codex Model Team installed successfully
```

**একটি বিষয়:** আমি এখানে GitHub repository-তে সরাসরি commit করিনি। এই content তোমাকে নিজে paste করে commit করতে হবে। আর production ব্যবহারের আগে installer-টি একটি disposable test project-এ পরীক্ষা করো—বিশেষ করে আগে থেকে `.agents/plugins/marketplace.json` থাকা project-এ।
