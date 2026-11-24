
# Codex Model Team

A reusable, project-local multi-agent setup for OpenAI Codex.

Codex Model Team provides specialized AI agents for software implementation,
architecture advice, codebase exploration, independent code review,
UI review, and documentation research.

Install it into any project with a single command and let Codex
automatically follow the Model Team workflow for non-trivial engineering tasks.

---

## Features

- Project-local Codex configuration
- Specialized custom agents
- Reusable Model Team workflow skill
- Automatic project-level workflow instructions through AGENTS.md
- GitHub-based plugin marketplace
- One-command installation
- No Python, Node.js, or Git required on the target machine
- Existing AGENTS.md content is preserved outside the managed section
- Existing project configuration is preserved where supported
- Custom GitHub repository owner support
- No global Codex configuration modification

## Model Team

| Role | Model | Reasoning |
|---|---|---|
| Main implementation | GPT-6.2 Sol | Medium |
| Complex implementation | GPT-6.2 Astra | High |
| Architecture advisor | GPT-6.2 Astra | High |
| Local project explorer | GPT-6 Luna | High |
| Independent code reviewer | GPT-6.2 Astra | High |
| UI / screenshot reviewer | GPT-6.1 Terra | Medium |
| Documentation researcher | GPT-6 Luna | High |

Model availability and supported reasoning levels depend on the Codex
client, account, and workspace configuration.

These are recommended configurations, not guaranteed model availability.

## Agent Responsibilities

### 1. Implementation

The main Codex session implements requested features and fixes bugs.

Responsibilities:

- Follow existing architecture and coding conventions.
- Keep changes focused.
- Avoid unnecessary refactoring.
- Handle edge cases.
- Add or update relevant tests.
- Run appropriate validation.

### 2. Advisor

Acts as a senior software architect and independent technical advisor.

Responsibilities:

- Analyze requirements and architecture.
- Evaluate implementation strategies.
- Identify technical risks and trade-offs.
- Recommend scalable and maintainable solutions.
- Challenge assumptions before implementation.

The advisor does not implement changes.

### 3. Explorer

Responsible for understanding the existing codebase.

Responsibilities:

- Search relevant files and symbols.
- Trace execution paths and dependencies.
- Understand data flows and architectural relationships.
- Identify potential impact areas.
- Return exact file and code references.

The explorer does not implement changes.

### 4. Reviewer

Performs independent code reviews after implementation.

Review priorities:

1. Functional bugs
2. Runtime crashes
3. Regression risks
4. Concurrency and lifecycle issues
5. Memory and performance issues
6. Security vulnerabilities
7. Missing test coverage

Findings should include the affected file, relevant line,
impact, and suggested fix.

The reviewer does not implement changes.

### 5. UI Reviewer

Focuses on UI implementation and visual quality.

Responsibilities:

- Inspect screenshots and UI behavior.
- Identify layout and visual inconsistencies.
- Review accessibility and usability.
- Suggest practical UI improvements.

### 6. Documentation Researcher

Researches external technical documentation.

Responsibilities:

- Find relevant official documentation.
- Verify API usage and compatibility.
- Research framework and library behavior.
- Provide source references.
- Distinguish verified information from assumptions.

---

## Architecture

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
│               ├── SKILL.md
│               └── references/
│
├── scripts/
├── tests/
├── install.sh
└── README.md
```

### Plugin vs. custom agents

The plugin packages the reusable Model Team workflow skill.

Custom agents are maintained separately as project-local TOML files
under `.codex/agents/`.

The installer copies these agent definitions into the target project.

---

## Installation

### Requirements

- OpenAI Codex CLI
- Bash
- curl
- tar
- Standard Unix utilities

No Python, Node.js, or Git is required on the target machine.

### One-command installation

The official repository is:

https://github.com/zakaria5729/codex-model-team

Open your terminal inside the project where you want to install Model Team.

Run:

```bash
curl -fsSL https://raw.githubusercontent.com/zakaria5729/codex-model-team/main/install.sh | bash
```

That's it!

The installer automatically uses:

| Setting | Default |
|---|---|
| GitHub owner | `zakaria5729` |
| Repository | `codex-model-team` |
| Branch | `main` |

No username prompt is required.

### Install into a specific directory

```bash
curl -fsSL https://raw.githubusercontent.com/zakaria5729/codex-model-team/main/install.sh \
  | bash -s -- --target /path/to/your/project
```

### Installation from a local repository clone

```bash
git clone https://github.com/zakaria5729/codex-model-team.git

cd codex-model-team

chmod +x install.sh

./install.sh
```

Run the installer from the target project directory
if you want to install into the current project.

---

## Automatic Model Team Workflow

One of the main goals of Codex Model Team is to avoid requiring
users to manually request the Model Team skill for every task.

The installer automatically creates or updates a managed section
inside the target project's root `AGENTS.md`.

Codex reads project-level instructions automatically when working
inside the trusted project.

The instructions tell Codex to:

1. Understand the task and inspect the project.
2. Use `explorer` for non-trivial codebase investigation.
3. Use `advisor` for architecture and technical decisions.
4. Implement changes through the main Codex session.
5. Use `reviewer` for independent review after meaningful changes.
6. Use `ui-reviewer` when visual inspection is relevant.
7. Use `docs-researcher` when external documentation is needed.
8. Report actual tests, findings, and remaining risks.

### Task-based delegation

Not every task needs every agent.

| Task | Recommended workflow |
|---|---|
| Simple typo or small change | Main Codex session |
| Multi-file feature | Explorer → Implementation → Reviewer |
| Architecture change | Explorer → Advisor → Implementation → Reviewer |
| Production bug investigation | Explorer → Advisor → Implementation → Reviewer |
| UI redesign | Explorer → Implementation → UI Reviewer |
| Version-specific API integration | Explorer → Docs Researcher → Implementation → Reviewer |

These are workflow instructions, not a guarantee that Codex will
spawn every agent on every request.

### AGENTS.md protection

The installer uses these markers:

```markdown
<!-- BEGIN CODEX MODEL TEAM -->

Model Team instructions are managed here.

<!-- END CODEX MODEL TEAM -->
```

When the installer runs again:

- It updates only the managed Model Team section.
- Existing user instructions remain untouched.
- It does not duplicate the managed section.
- It stops if the markers are malformed or duplicated.

You can continue adding your own instructions outside these markers.

---

## Start Using Model Team

After installation:

```bash
cd /path/to/your/project

codex
```

Trust the project if Codex asks.

Start giving Codex normal engineering tasks.

You do not need to write:

```text
Use the Model Team skill for this task.
```

The project-level `AGENTS.md` provides persistent workflow guidance.

To inspect registered marketplaces:

```bash
codex plugin marketplace list
```

To inspect marketplace commands:

```bash
codex plugin marketplace --help
```

---

## Use a Different GitHub Owner

The default repository owner is `zakaria5729`.

If you fork this repository or maintain your own copy,
you can override the owner.

```bash
curl -fsSL https://raw.githubusercontent.com/zakaria5729/codex-model-team/main/install.sh \
  | bash -s -- --username YOUR_GITHUB_USERNAME
```

You can also specify another repository or branch:

```bash
curl -fsSL https://raw.githubusercontent.com/zakaria5729/codex-model-team/main/install.sh \
  | bash -s -- \
      --username YOUR_GITHUB_USERNAME \
      --repo codex-model-team \
      --ref main
```

### Change the owner later

```bash
curl -fsSL https://raw.githubusercontent.com/zakaria5729/codex-model-team/main/install.sh \
  | bash -s -- --username NEW_OWNER
```

The installer saves the selected repository coordinates in:

```text
.codex/model-team.env
```

Example:

```text
owner=zakaria5729
repo=codex-model-team
ref=main
```

The saved configuration is project-local.

---

## What Gets Installed?

After installation:

```text
your-project/
│
├── AGENTS.md
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

The installer also configures the Model Team plugin
in the project-local Codex configuration.

### Existing project protection

The installer is designed to preserve existing project configuration.

- Existing root `AGENTS.md` content outside the managed section is preserved.
- Existing agent files are not overwritten.
- Existing main model settings are preserved.
- Existing project-level Codex settings are preserved.
- Existing marketplace plugins are retained when safe JSON merging is available.
- If an existing marketplace needs merging but `jq` is unavailable,
  the installer stops rather than overwriting it.

The installer does not modify global Codex configuration:

```text
~/.codex/config.toml
~/.codex/agents/
```

All custom agent configurations are project-local.

---

## Using Model Team on Another PC

You can share the target project's configuration through Git.

Commit these project-local files:

```text
AGENTS.md
.codex/config.toml
.codex/agents/
.codex/model-team.env
.agents/plugins/marketplace.json
```

On another PC:

1. Install Codex CLI.
2. Sign in to Codex.
3. Clone the target project.
4. Trust the project if prompted.
5. Start Codex from the project directory.

Codex authentication and account credentials are not included
in the project repository.

---

## Updating Model Team

To retrieve the latest agent templates and workflow instructions,
rerun the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/zakaria5729/codex-model-team/main/install.sh | bash
```

Important:

Existing agent files are intentionally preserved.
If the repository contains updated agent templates, review and merge
those changes into existing project files when necessary.

The managed section of `AGENTS.md` is updated automatically.

---

## Uninstall

To remove Model Team from a project:

1. Remove the Model Team plugin configuration from `.codex/config.toml`.
2. Remove the Model Team entry from `.agents/plugins/marketplace.json`.
3. Remove the Model Team agent TOML files from `.codex/agents/`.
4. Remove `.codex/model-team.env`.
5. Remove only the section between the Model Team markers from root `AGENTS.md`.

Do not delete a marketplace file if it contains other plugins.

Do not delete other project instructions from `AGENTS.md`.

Codex manages its local plugin cache separately.

---

## Repository Validation

Maintainers can run repository validation scripts:

```bash
python3 scripts/validate_repository.py

python3 -m unittest discover -s tests -v
```

Python is only needed for maintainer validation,
not for end-user installation.

---

## Contributing

Contributions, bug reports, and feature suggestions are welcome.

If you fork this repository, use your own GitHub owner
with the `--username` option.

---

## License

MIT License.

See [LICENSE](LICENSE).
