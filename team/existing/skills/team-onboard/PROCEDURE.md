# /team-onboard procedure

Read by `team-analyst`, one phase at a time. Doc discovery is the `discover` phase of `skills/team-docs/PROCEDURE.md`.

## Common

You are a senior engineer on your first day in an established codebase. You learn how this team builds software so every later step fits in. You record what is true, with evidence; you do not judge or propose refactors. This project is in `existing` mode: read FLOW.md → "Which source wins" (`existing` mode) and "Ground rules" → Secrets.

Work files live in `.dev-team/setup/`: `discovery.md`, `answers.md` (every user answer so far), `findings.md` (your evidence and open questions). Drafts are `.dev-team/STANDARDS.md` and `.dev-team/PROJECT.md` with `status: draft`.

## Phase: study

INPUTS: `discovery.md`, `answers.md`. OUTPUT: `findings.md`, draft `STANDARDS.md` and `PROJECT.md`.
1. **Collect the docs the user chose.** Files inside the repo: by path. Files outside it: copy into `.dev-team/docs/` and record the original path. `.pdf` and `.txt`: read directly. `.docx`: `textutil -convert txt "<file>" -output .dev-team/docs/<name>.txt`. Record a short hash of each.
2. **Read the explicit rules.** The chosen docs, plus the enforced config: lint, format, type and editor config (`.eslintrc*`, `prettier*`, `ruff.toml`, `pyproject.toml`, `tsconfig.json`, `.editorconfig`, pre-commit hooks) and CI workflows.
3. **Map the codebase.** Stack and versions, entry points, main modules and what each owns, data layer and migrations, API style, frontend framework and design system, AI/LLM integrations, generated or vendored code that must not be edited. Sample; don't read everything.
4. **Observe conventions** from representative files (not the oldest or strangest): naming, folder structure, comment and docstring style, error handling, logging, validation, state management, test layout and style, dependency injection. Each convention needs a file path as evidence and a confidence tag: **high** (enforced by config, or consistent everywhere you looked) or **medium** (the majority pattern, with exceptions). No docs provided: the code is the only source, so sample more files per area and check where docs would normally answer (migrations, route files, tests). Where a doc and the code disagree, note both.
5. **Observe the process.** `git log --oneline -30` (commit style), `git branch -r | head -30` (branch naming), PR template, CI workflows (which checks gate merges).
6. **Verify the commands** if the user allowed it. Find install, dev server, test, lint and typecheck from scripts and CI. Run the read-only ones (test, lint, typecheck), output through `tail -n 40`, and record results, including failures that already exist on the base branch. Never install dependencies, start services, or write to a database unless the answers allow it.
   Then the **worktree setup**: what a fresh checkout needs before its tests run.
   - Dependencies: a fast install from the lockfile (`pnpm install --frozen-lockfile`, `uv sync`), or symlinks to the main checkout's dependency folders when tasks won't change dependencies.
   - Python: imports must resolve to the worktree's code; an editable install in a shared virtualenv points at the main checkout. Prefer a per-worktree environment.
   - Untracked files the app needs, such as `.env`: symlink them from the project root. Never copy a `.env` or write its values anywhere.
   If allowed, prove it once: `git worktree add .dev-team/worktrees/_probe HEAD`, run the setup and the test command there, then `git worktree remove --force .dev-team/worktrees/_probe`.
7. **Write drafts.** `STANDARDS.md` from `skills/team/STANDARDS_TEMPLATE.md`, applying the `existing`-mode priority order: every rule cites its source (a config file, a doc, or "observed in `<paths>`" with its confidence tag). Use the global standards in `skills/team/standards/` only for topics the project leaves open (a file with only `<!-- … -->` placeholders counts as absent), listing differences under "Adjustments to my global standards". `PROJECT.md` from the template below.
8. **Write `findings.md`** and return NEEDS-INPUT with one round, most important first, skipping anything already answered: each doc-versus-code conflict (which reflects reality?); medium-confidence conventions that would change how new code is written; where work comes from and the ticket key format; branch, commit and PR expectations if not evident; areas not to touch or that need sign-off; whether new dependencies need approval; the definition of done. Nothing to ask: reply DONE.

## Phase: finalize

INPUTS: `findings.md`, `answers.md`, the drafts; NOTES may carry revision feedback.
Apply the answers: record each resolved conflict under "Decisions" in `STANDARDS.md` (dated), update the affected rules, fill `PROJECT.md` → Team process and Do not touch. Keep `status: draft`. SUMMARY for the user's approval: docs used (or "none, learned from code"), stack, the most important rules, command status, pre-existing failures, and anything still uncertain.

## Phase: refresh-conventions

For `/team-onboard refresh` when conventions moved on without a doc changing. Re-observe the areas named in NOTES as in study step 4, update `STANDARDS.md` with the changes (citing evidence), and list them in SUMMARY for approval.

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
| Repo | Owns | Local path | Base branch |
|------|------|------------|-------------|

## Stack
<Languages and versions, frameworks, database, AI providers, hosting.>

## Codebase map
| Area | Path | Owns |
|------|------|------|

## Commands
| Repo | Purpose | Command | Status on base branch |
|------|---------|---------|-----------------------|
| | Install | | |
| | Dev server | | <URL> |
| | Test | | <pass/fail counts> |
| | Lint | | |
| | Typecheck | | |

## Build settings
- Worktree setup: <commands that make a fresh worktree runnable, run inside it; "verified" or "not verified">
- Worktree helper: <script that creates and sets up a worktree, if the project has one; otherwise "none">
- Plan docs: <where tasks and sprints are listed, e.g. `TASKS.md`, `tasks/SPRINT-*.md`, or the ticket tool>
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
