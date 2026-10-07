---
name: team-onboard
description: Onboarding for an existing, running project. Asks the user which project docs are available (possibly none), studies the codebase and the team's conventions and process, verifies the dev commands, and writes the project profile and project rulebook to .dev-team/ so the team adapts to the project as it is. Use only when the user invokes /team-onboard or /team runs project setup in existing mode.
disable-model-invocation: true
---

# /team-onboard — Join an Existing Project

You are a senior engineer on your first day in an established codebase. Your job is to learn how this team builds software so every later stage fits in. You record what is true, with evidence; you do not judge or propose refactors.

Read `skills/team/FLOW.md` first. This project is in `existing` mode.

Arguments: none for a full onboarding; `refresh` to re-sync after docs or conventions change (see the end).

## Steps

1. **See what docs the repo already has.** Follow `skills/team-docs/SKILL.md` → Discovery steps 1–3: every `.md` file in the repo, wherever it lives (`docs/`, the repo root, other folders), grouped, with a proposed kind (requirements, standard, plan, reference, ignored) and scope (shared with the product's other repos, or specific to this repo). Also find `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, `.claude/rules/`, ADRs, and `.github/` templates. Don't read them in depth yet.

2. **Ask the user which docs to use.** One AskQuestion round:
   - A multi-select of the docs found in step 1, grouped, with your recommendation preselected, so the user can drop outdated ones. Include the product repos question from Discovery step 3 if the product spans several repos.
   - Whether they have other docs: requirements, architecture, database, API, coding guidelines, onboarding notes, ticket context. They can give file paths (any location) or paste content in their next message.
   - An explicit option: **"No docs — learn from the code."**

   Then collect what they provide:
   - Files inside the repo: reference them by path.
   - Files outside the repo: copy them into `.dev-team/docs/` (local only) and record the original path.
   - Pasted content: save it as `.dev-team/docs/<short-name>.md`.
   - `.pdf` and `.txt`: read directly. `.docx`: convert with `textutil -convert txt "<file>" -output .dev-team/docs/<name>.txt`.

   Record a short hash of each doc (`shasum -a 256 <file> | cut -c1-8`).

3. **Read the explicit rules.** The docs selected in step 2, plus the enforced config: lint, format, type, and editor config (`.eslintrc*`, `prettier*`, `ruff.toml`, `pyproject.toml`, `tsconfig.json`, `.editorconfig`, pre-commit hooks) and CI workflows.

4. **Map the codebase.** Stack and versions, entry points, main modules and what each owns, data layer and migrations, API style, frontend framework and design system, AI/LLM integrations, generated or vendored code that must not be edited. For a large repo, delegate to an `explore` subagent and ask for paths and patterns.

5. **Observe conventions.** From representative files (not the oldest or strangest): naming, folder structure, comment and docstring style, error handling, logging, validation, state management, test layout and style, how dependencies are injected. Each convention needs a file path as evidence and a confidence tag: **high** (enforced by config, or consistent everywhere you looked) or **medium** (the majority pattern, with exceptions).

   **If the user provided no docs**, the code is the only source, so go deeper: sample more files per area, and check where docs would normally answer the question (migrations for DB conventions, route files for API conventions, existing tests for testing conventions).

   **Where a doc and the code disagree**, note both; you'll ask in step 8.

6. **Observe the team's process.** `git log --oneline -30` for commit message style, `git branch -r` for branch naming, PR template for what reviewers expect, CI workflows for which checks gate merges.

7. **Verify the commands.** Find install, dev server, test, lint, and typecheck commands from scripts and CI. Run the read-only ones (test, lint, typecheck) and record the results, including failures that already exist on the base branch so later stages do not blame the feature for them. Ask before installing dependencies, starting services, or running anything that writes to a database.

   Then work out the **worktree setup**: what a fresh git checkout of this repo needs before its tests run, since the team builds each task in its own worktree.
   - Dependencies: prefer a fast install from the lockfile (`pnpm install --frozen-lockfile`, `uv sync`), or symlinks to the main checkout's dependency folders when tasks won't change dependencies.
   - Python: make sure imports resolve to the worktree's code. An editable install in a shared virtualenv points at the main checkout and would test the wrong code; prefer a per-worktree environment.
   - Untracked files the app needs, such as `.env`: symlink them from the project root.

   With the user's agreement, prove it once: `git worktree add .dev-team/worktrees/_probe HEAD`, run the setup and the test command there, then `git worktree remove --force .dev-team/worktrees/_probe`.

8. **Confirm what you're unsure of.** One AskQuestion round, most important first, skipping anything already answered:
   - Each doc-versus-code conflict: which reflects reality?
   - Medium-confidence conventions that would change how new code is written
   - Where work comes from (Jira, Linear, GitHub issues) and the ticket key format
   - Branch, commit, and PR expectations if not evident
   - Areas not to touch, or that need sign-off
   - Whether adding dependencies needs approval
   - The team's definition of done

9. **Write `.dev-team/STANDARDS.md`** using `skills/team/STANDARDS_TEMPLATE.md`, applying the existing-mode priority order from FLOW.md. Every rule cites its source: a config file, a doc, or "observed in `<paths>`" with its confidence tag. Use my global standards only for topics the project leaves open, and list them in "Adjustments to my global standards" where the project differs from them. Record the user's answers from step 8 under "Decisions".

10. **Write `.dev-team/PROJECT.md`** using the template below.

11. **Approve.** Summarise: docs used (or "none, learned from code"), stack, the most important rules, command status, pre-existing failures, and what you're still unsure of. Ask: Approve / Revise / Stop. On Approve, set both documents to `approved` and tell the user to start work with `/team-plan <ticket or description>`.

## Refresh (`/team-onboard refresh`)

Run when docs changed, the user has new docs, or the project's conventions moved on.
1. Follow `skills/team-docs/SKILL.md` → Reconcile (the same as `/team-docs`), and ask whether there are new docs from outside the repo to add (same handling as step 2).
2. If conventions moved on without any doc changing, re-observe the affected areas as in step 5, then update `STANDARDS.md`, show the user what changed, and ask for approval.

## `PROJECT.md` template

```markdown
---
feature: project
stage: project
status: draft
mode: existing
updated: <YYYY-MM-DD>
---

# <Project name>

## Summary
<What the product does and the main parts of the system. 2–3 sentences.>

## Project docs
| Doc | Kind | Scope | Original location | Governs | Hash |
|-----|------|-------|-------------------|---------|------|
<One row per doc used, or the single row: "None provided — standards learned from the code".>

## Doc sources
- Scanned: every `.md` in the repo (git-ignored files skipped), plus docs the user provided from outside it
- Ignored: <paths the user chose not to use>

## Product repos
<Only if the product spans several repos; otherwise "Single repo".>
| Repo | Owns | Local path |
|------|------|------------|

## Stack
<Languages and versions, frameworks, database, AI providers, hosting.>

## Codebase map
| Area | Path | Owns |
|------|------|------|

## Commands
| Purpose | Command | Status on base branch |
|---------|---------|-----------------------|
| Install | | |
| Dev server | | <URL> |
| Test | | <pass/fail counts> |
| Lint | | |
| Typecheck | | |

## Build settings
- Worktree setup: <commands that make a fresh worktree runnable, run inside it; "verified" or "not verified">
- Max parallel engineers: 4
- Delivery preference: <unset until the first delivery>

## Team process
- Work tracking: <tool, ticket key format>
- Branches: <pattern>
- Commits: <style, with an example from git log>
- PRs: <template and review expectations>
- Merge gates: <CI checks>
- Definition of done: <…>

## Do not touch without asking
- <paths or areas, and why>
```
