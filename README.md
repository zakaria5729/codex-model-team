
# Codex Model Team

A reusable, project-local multi-agent setup for OpenAI Codex.

Codex Model Team provides specialized AI agents for software implementation, architecture advice, local codebase exploration, independent code review, UI review, and documentation research.

Install it into any project with a single command and use a coordinated team of specialized agents directly through Codex.

---

## Features

- Project-local Codex configuration
- Specialized custom agents
- Reusable Model Team workflow skill
- GitHub-based plugin marketplace
- One-command installation
- No Python, Node.js, or Git required on the target machine
- Existing project configuration is preserved where supported
- Custom GitHub repository owner support
- Works across different projects and development environments

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

Model availability and supported reasoning levels depend on the Codex client, account, and workspace configuration.

These are recommended configurations, not guaranteed model availability.

## Agent Responsibilities

### 1. Implementation

Responsible for implementing requested features, fixing bugs, and modifying project code.

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

The advisor does not modify project files.

### 3. Explorer

Responsible for understanding the existing codebase.

Responsibilities:

- Search relevant files and symbols.
- Trace execution paths and dependencies.
- Understand data flows and architectural relationships.
- Identify potential impact areas.
- Return exact file and code references.

The explorer does not modify project files.

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

Every finding should include the affected file, relevant line, impact, and suggested fix.

The reviewer does not modify project files.

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

Custom agents are maintained separately as project-local TOML files under `.codex/agents/`.

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

You can provide a target project directory:

```bash
curl -fsSL https://raw.githubusercontent.com/zakaria5729/codex-model-team/main/install.sh \
  | bash -s -- --target /path/to/your/project
```

### Installation from a local repository clone

If you already cloned this repository:

```bash
git clone https://github.com/zakaria5729/codex-model-team.git
cd codex-model-team
chmod +x install.sh
./install.sh
```

Run the installer from the target project directory if you want to install into the current project.

---

## Use a Different GitHub Owner

The default repository owner is `zakaria5729`.

If you fork this repository or maintain your own copy, you can override the owner.

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

You can change the repository owner at any time by rerunning the installer:

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

After installation, your project will contain:

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

The installer also configures the Model Team plugin in the project-local Codex configuration.

### Existing project protection

The installer is designed to preserve existing project configuration.

- Existing agent files are not overwritten.
- Existing main model settings are preserved.
- Existing project-level Codex settings are preserved.
- Existing marketplace plugins are retained when safe JSON merging is available.
- If an existing marketplace needs merging but `jq` is unavailable, the installer stops rather than overwriting it.

The installer does not modify your global Codex configuration:

```text
~/.codex/config.toml
~/.codex/agents/
```

All custom agent configurations are project-local.

---

## Start Using Model Team

After installation, open Codex from your project directory:

```bash
cd /path/to/your/project
codex
```

Trust the project if Codex asks.

You can inspect available marketplace commands:

```bash
codex plugin marketplace --help
```

Check registered marketplaces:

```bash
codex plugin marketplace list
```

### Example workflow prompt

Give Codex a task like this:

```text
Use the Model Team skill for this task.

1. Ask explorer to inspect the relevant codebase.
2. Ask advisor to analyze the architecture and recommend an approach.
3. Ask implementation to implement the agreed changes.
4. Ask reviewer to independently review the final diff.
5. Fix important findings and run relevant tests.

Use ui-reviewer when visual inspection is relevant.
Use docs-researcher when external documentation research is needed.

Provide a final summary with:
- Implementation approach
- Changed files
- Tests executed
- Review findings
- Remaining risks
```

Codex coordinates the specialized agents according to the task and their instructions.

---

## Example Use Cases

### Android Development

```text
I want to migrate this Android project from Gson
to Kotlin Serialization.

Use Model Team:

- Explorer: inspect existing serialization architecture.
- Advisor: evaluate the migration strategy.
- Implementation: perform the migration.
- Reviewer: independently review all changes.

Check backward compatibility, custom serializers,
null handling, and runtime crash risks.

Run relevant tests and provide a final report.
```

### Spring Boot Development

```text
I want to introduce authentication into this
Spring Boot application.

Use Model Team:

- Explorer: inspect existing security architecture.
- Advisor: evaluate JWT, OAuth2, and Keycloak options.
- Implementation: implement the agreed solution.
- Reviewer: review security and regression risks.

Follow production-ready Spring Security practices.
```

### Bug Investigation

```text
Investigate this production bug.

- Explorer: trace the execution path.
- Advisor: identify possible root causes.
- Implementation: implement the fix.
- Reviewer: verify the fix and look for regressions.

Do not perform unrelated refactoring.
```

---

## Using Model Team on Another PC

You can share the target project's configuration through Git.

Commit these project-local files:

```text
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

The plugin package is fetched and cached by Codex on each PC.

Codex authentication and account credentials are not included in the project repository.

---

## Updating Model Team

To retrieve the latest agent templates, rerun the installer.

```bash
curl -fsSL https://raw.githubusercontent.com/zakaria5729/codex-model-team/main/install.sh | bash
```

**Important:** Existing agent files are intentionally preserved. If the repository contains updated agent templates, review and merge those changes into your existing project files when necessary.

---

## Uninstall

To remove Model Team from a project:

1. Remove the Model Team plugin configuration from `.codex/config.toml`.
2. Remove the Model Team entry from `.agents/plugins/marketplace.json`.
3. Remove the Model Team agent TOML files from `.codex/agents/`.
4. Remove `.codex/model-team.env`.

Do not delete a marketplace file if it contains other plugins you still use.

Codex manages its local plugin cache separately.

---

## Repository Validation

Maintainers can run the repository validation scripts:

```bash
python3 scripts/validate_repository.py
python3 -m unittest discover -s tests -v
```

Python is only needed for maintainer validation, not for end-user installation.

---

## Contributing

Contributions, bug reports, and feature suggestions are welcome.

If you fork this repository, use your own GitHub owner with the `--username` option.

---

## License

MIT License.

See [LICENSE](LICENSE).
