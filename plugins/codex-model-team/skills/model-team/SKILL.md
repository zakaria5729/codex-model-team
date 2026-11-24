---
name: model-team
description: Coordinate a project-local team of Codex agents for non-trivial implementation, architecture planning, codebase investigation, debugging, migrations, and independent code review. Use when a task spans multiple files or layers, has meaningful regression risk, or benefits from independent analysis.
---

# Codex Model Team

Use this workflow to divide substantial engineering work between the main Codex session and the project-local specialist agents.

## Team and model routing

| Responsibility | Agent | Intended model | Reasoning |
|---|---|---|---|
| Main implementation | Main Codex session / built-in `worker` | `gpt-6.2-sol` | `medium` by default; use `high` for broad refactors |
| Architecture and planning | `advisor` | `gpt-6.2-astra` | `high` |
| Local codebase exploration | `explorer` | `gpt-6-luna` | `high`; use `low` only for simple, bounded lookups when explicitly spawning with an override |
| Independent code review | `reviewer` | `gpt-6.2-astra` | `high` |
| Visual review | `ui-reviewer` | `gpt-6.1-terra` | `medium` |
| Documentation verification | `docs-researcher` | `gpt-6-luna` | `high` |

These are project defaults, not guarantees of account availability. If a configured model is unavailable in the current Codex client or account, tell the user which agent could not be started and suggest selecting an available model. Do not silently claim that a different model was used.

## Decide whether to use the team

Do not spawn agents for every request.

Use the full or partial workflow when the task:
- changes multiple files, modules, services, or layers;
- requires understanding unfamiliar code before editing;
- involves architecture, a migration, data flow, concurrency, security, or lifecycle behavior;
- has significant regression risk; or
- explicitly requests independent review.

For a small, obvious, single-file change, implement directly and run the appropriate focused validation.

## Standard workflow for substantial changes

### 1. Explore before editing

Ask `explorer` to investigate the relevant code paths. Request evidence rather than guesses:
- entry points and call hierarchy;
- relevant classes, functions, routes, state, and configuration;
- data and control flow;
- existing conventions and nearby tests;
- exact file and line references;
- likely impact areas.

Keep exploration read-focused. Do not ask the explorer to implement the change.

### 2. Obtain an independent technical plan

Ask `advisor` to assess the requirement and exploration findings. Request:
- the simplest suitable design;
- alternatives and trade-offs;
- edge cases and failure modes;
- compatibility, security, performance, and operational risks;
- affected components; and
- a practical validation plan.

The advisor should not edit project files. Reconcile its recommendations with the actual requirements and codebase; do not accept advice blindly.

### 3. Implement with the main session

The main session is the implementation owner and normally uses Sol at medium reasoning effort.

- Follow existing project conventions and architecture.
- Keep the diff focused; avoid unrelated refactoring.
- Add or update tests for changed behavior.
- Handle error paths and relevant edge cases.
- Run targeted tests and validation.
- For unusually difficult implementation work, consider switching the main session to Astra or explicitly spawning a suitable specialist if one is configured. Do not use Astra for routine edits by default.

### 4. Review independently

After implementation, ask `reviewer` to inspect the actual diff and relevant surrounding code. The reviewer should not rely only on the implementation summary.

Prioritize:
1. Functional bugs and behavioral regressions
2. Crashes, data loss, and reliability failures
3. Security and privacy issues
4. Concurrency, lifecycle, and resource-management errors
5. Performance and scalability problems
6. Missing or ineffective tests

Require actionable findings with severity, exact file/line references, a concrete failure scenario, and a recommended fix. Do not report style-only preferences or speculative issues.

Address valid findings, then rerun relevant tests. If a finding is not valid, explain why rather than changing code to satisfy it blindly.

### 5. Use specialist reviewers only when relevant

- Ask `ui-reviewer` to inspect screenshots or rendered UI when visual behavior is part of the task. Do not ask it to infer visual details without evidence.
- Ask `docs-researcher` to verify current SDK, framework, platform, or library behavior when correctness depends on version-specific documentation.

### 6. Final report

Summarize:
- what changed and why;
- important files/components changed;
- tests and checks actually executed, with results;
- review findings and how they were handled; and
- unresolved risks or work not completed.

Never claim a command, test, screenshot inspection, or documentation check was performed unless it actually was.

## Example prompt

> Use the Model Team workflow for this change. Have `explorer` map the current implementation, ask `advisor` for a design and risk review, implement the agreed approach in the main session, and have `reviewer` independently inspect the final diff. Use `docs-researcher` or `ui-reviewer` only if relevant. Run focused tests and report exact results.

## Permission reminder

Custom agent instructions such as “do not edit files” are behavioral guidance, not an independent security boundary. Subagents inherit the parent session's sandbox and approval settings. Set the parent Codex session to the permission level you intend before delegating work.

## Set up the specialist agents in this project

When the user asks to install, initialize, or set up Codex Model Team in the current project:

1. Work only in the current project root. Do not edit `~/.codex/config.toml`, global agent folders, shell profiles, or other repositories.
2. Check whether `.codex/agents/` and `.codex/config.toml` already exist. Preserve unrelated content and existing user choices.
3. The packaged agent templates are in this skill's `references/agents/` directory: `advisor.toml`, `explorer.toml`, `reviewer.toml`, `ui-reviewer.toml`, and `docs-researcher.toml`.
4. Create `.codex/agents/` if needed and copy each template there. If a destination file already exists, do not overwrite it. Show a diff or ask the user before replacing an existing Model Team agent.
5. Do not force a primary model in `.codex/config.toml`. If no project-local model is configured and the user explicitly wants Model Team defaults, propose `gpt-6.2-sol` with `medium` reasoning before adding those settings. Otherwise preserve the project's current model and reasoning settings.
6. Explain that custom agents become available in a new Codex session started from the trusted project root. Do not claim that the public plugin itself automatically registers custom agents.
7. Verify the created TOML files and report exactly what changed.

The agent templates are project-local configuration resources, not executable code. Their instructions to remain read-only are behavioral guidance; actual write permissions are controlled by the parent Codex session's sandbox and approval settings.

