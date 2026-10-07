# Dev Team Flow — shared conventions

Every `/team-*` skill follows these rules. Read this file once per session before acting.

## Host (Cursor or Claude Code)

The team installs into whichever coding tools the project uses:

| | Cursor | Claude Code |
|---|---|---|
| Skills | `skills/<name>/SKILL.md` | `.claude/skills/<name>/SKILL.md` |
| Agents | `.cursor/agents/<name>.md` | `.claude/agents/<name>.md` |

Artifacts always live in `.dev-team/` (same for both). When a skill says `skills/team/FLOW.md`, open it under the host that is running this session (`skills/…` or `.claude/skills/…`). Deploy installs both by default so colleagues on either tool share the same team.

**Structured questions.** Ask the user with the host's question tool: **AskQuestion** in Cursor, **AskUserQuestion** in Claude Code. If neither is available, number the options in prose and wait for a reply. Every "AskQuestion" in these skills means that.

**Background engineers.** Launch engineer subagents in the background when the host supports it (Cursor: `run_in_background: true`; Claude Code: a background agent). If background is unavailable, run ready tasks in parallel in the foreground.

**Explore.** For codebase search, use the host's explore agent (`explore` in Cursor, `Explore` in Claude Code), or search the tree yourself.

## Project modes

The team is deployed in one of two modes. The mode is recorded as `mode:` in `.dev-team/PROJECT.md`.

| | `new` — starting from scratch | `existing` — joining a running project |
|---|---|---|
| Setup command | `/team-kickoff` | `/team-onboard` |
| Project docs | Every `.md` file under `docs/`, plus the repo-level docs the user selects | Whatever docs the user selects or provides; possibly none |
| Source of requirements | PRD and SRS (usually in `docs/`), ordered by plan docs if there are any | Tickets, issues, or a description from the user |
| Change style | Build it right per the standards | Smallest change that fits the codebase as it is |

Before `PROJECT.md` exists, the mode is whichever setup skill is installed: `skills/team-kickoff/` means `new`, `skills/team-onboard/` means `existing`.

## The project rulebook: `.dev-team/STANDARDS.md`

Setup writes `STANDARDS.md`: the effective rules for *this* project, merged from every source below, each rule citing its source. **Every stage and every engineer follows `STANDARDS.md`.** It summarises rules and points to the source doc for detail (e.g. "Table and column naming: see `docs/databases.md` § Naming"); the source docs stay the source of truth.

My global standards live in `skills/team/standards/`. A standards file that still contains only template placeholders (`<!-- … -->`) counts as absent.

### Which source wins

**`new` mode**, highest first:
1. Project docs that set rules (e.g. `databases.md`, `manifest.md`, `api.md`), in `docs/` or elsewhere in the repo — they adjust my standards for this project, and repo docs refine shared ones
2. My global standards
3. General best practice

The PRD and SRS define *what* to build; the rules above define *how*. `architecture.md` is derived from both and must conform to them.

**`existing` mode**, highest first:
1. Rules the project enforces: lint/format/type configs, CI checks, `CONTRIBUTING.md`, the team's `AGENTS.md`, `.cursor/rules/`, or `.claude/rules/`
2. Docs the user provided, and ADRs or docs in the repo
3. Conventions observed in the code
4. My global standards, **only where 1–3 are silent**, and never where they would make new code inconsistent with its surroundings
5. General best practice

When two sources conflict and the priority order doesn't settle it (most often: a doc says one thing, the code does another), ask the user during setup and record the answer in `STANDARDS.md`.

## Project docs

Project docs can live anywhere in the repo: product-wide docs shared across repos (often in `docs/`) and docs specific to this repo (e.g. its own `databases.md`, `sprint.md`, `tasks.md`). `/team-docs` (`skills/team-docs/SKILL.md`) finds them, gives each a kind (requirements, standard, plan, reference) and a scope (shared or repo), and says how they combine. Setup runs its Discovery; `PROJECT.md` records the result in Project docs, Doc sources, and Product repos.

**Plan docs** (the user's own sprint and task lists) decide which work is in which sprint, in what order, and what is done. The team follows them in `BACKLOG.md`, `/team-sprint`, and `/team-accept`, and never overrides requirements or standards with them.

**Several repos.** When `PROJECT.md` lists product repos, each requirement has an owner. Plan, design, and build only this repo's part. Record what other repos must provide, and the contract both sides agree on, as a cross-repo dependency; never edit another repo.

## Docs freshness

`/team`, `/team-plan`, and `/team-architect` check freshness before acting: compare the current hashes of the docs in `PROJECT.md` → Project docs, and look for new `.md` files in the places Doc sources says were scanned (excluding its Ignored list). Projects set up before Doc sources existed scan `docs/` only.

If a doc was added, changed, or removed, tell the user which, and recommend `/team-docs` before continuing. The user may choose to continue anyway.

## Pipeline

| Stage | Command | Role | Writes |
|-------|---------|------|--------|
| 0 | `/team-kickoff` (new) or `/team-onboard` (existing) | Project setup | `PROJECT.md`, `STANDARDS.md`, mode-specific docs |
| 1 | `/team-plan` | Product Planner | `spec.md` |
| 2 | `/team-architect` | Architect | `design.md`, `tasks.md` |
| 3 | `/team-build` | Engineers (AI, Backend, UI/UX subagents) | code + tests, ticks `tasks.md` |
| 4 | `/team-review` | Code Reviewer | `review.md` |
| 5 | `/team-security` | Security Reviewer | `security.md` |
| 6 | `/team-qa` | QA Tester | `qa.md`, then delivery |

`/team` shows status and runs the next stage. Stage 0 runs once per project, and `/team-docs` re-syncs the team when docs change; stages 1–6 run per feature. `/team-sprint` runs stages 1–6 for several features together, with one shared build scheduler and batched questions. `/team-accept` handles work the team didn't build, such as a teammate's sprint branch: it agrees the scope, runs review, security, and QA against it, and merges it with the user's approval. `/team-audit` validates work already on a branch (e.g. a sprint built before the team was deployed) and turns its gaps into a `<name>-gaps` feature. `/team-rca` investigates a bug or incident, proves its root cause in `<slug>/rca.md`, and hands the fix to `/team-plan` under the same slug.

## Workspace layout

```
.dev-team/
  PROJECT.md            # project profile, project docs index — every stage reads it first
  STANDARDS.md          # effective rules for this project — every stage and engineer follows it
  requirements.md       # new mode: requirement index from PRD + SRS
  architecture.md       # new mode: system architecture
  BACKLOG.md            # new mode: ordered features traced to requirements
  docs/                 # existing mode: copies of docs the user provided from outside the repo
  sprints/<name>.md     # sprint plans and boards
  accept/<slug>.md      # acceptance records for teammates' branches (/team-accept)
  audit/<name>.md       # validation records for existing work (/team-audit)
  worktrees/            # git worktrees for isolated builds (always git-ignored, never committed)
    <feature-slug>/integration/   # the feature's integration branch checkout
    <feature-slug>/T1/            # one checkout per running task
  <feature-slug>/       # one folder per feature or ticket
    rca.md rca/         # bug fixes only: root cause analysis and its evidence (/team-rca)
    spec.md design.md tasks.md review.md security.md qa.md followups.md
```

The slug is kebab-case, at most 40 characters, derived from the feature name or ticket (e.g. `magic-link-login`, `proj-142-fix-export`).

**Resolving which feature to work on:**
1. If the user named a feature, slug, or ticket, use it.
2. Otherwise, list `.dev-team/*/` (excluding `docs/`, `sprints/`, `accept/`, `audit/`, `worktrees/`). If exactly one feature is not `done`, use it.
3. Otherwise, ask with the AskQuestion tool, listing the candidate features.

## Artifact header

Every artifact starts with this frontmatter. Keep it accurate; other stages read it.

```yaml
---
feature: <slug, or "project" for project-level docs>
stage: project | standards | requirements | architecture | backlog | rca | spec | design | tasks | review | security | qa | accept | audit
status: draft | approved | done
updated: <YYYY-MM-DD>
---
```

## Gates

- Every stage from 1 onward needs `.dev-team/PROJECT.md` and `.dev-team/STANDARDS.md` with `status: approved`. If missing, tell the user to run the setup command for this mode and stop.
- In `new` mode, `/team-plan` also needs `requirements.md`, `architecture.md`, and `BACKLOG.md` approved.
- `/team-plan` needs `rca.md` approved when the feature folder has one.
- `/team-architect` needs `spec.md` approved.
- `/team-build` needs `design.md` and `tasks.md` approved.
- `/team-review`, `/team-security`, `/team-qa` need at least one merged task in `tasks.md`.

**Where the code is:** if `tasks.md` has `isolation: worktree` and is not yet delivered, the feature's code is in its `worktree:` path, not the project root. Read, diff (`git -C <worktree> diff <base>...HEAD`), test, and fix there, and commit fixes on the integration branch (`<slug> <stage>: fix R1, R3`). Otherwise use the project root.

If a gate fails, say which command to run first and stop. The user may explicitly say "skip the gate"; then proceed and note the skip in the artifact.

Only the user approves. Present a short summary, then ask with AskQuestion: **Approve** / **Revise** (/ **Stop**). Set `status: approved` only after the user picks Approve.

## Task format (`tasks.md`)

```markdown
---
feature: <slug>
stage: tasks
status: draft
base: <commit SHA the feature starts from, recorded by /team-build>
depends_on: <other feature slugs this feature builds on, or none>
isolation: <worktree | shared, recorded by /team-build>
branch: <dev-team/<slug>/integration, when isolation is worktree>
worktree: <.dev-team/worktrees/<slug>/integration, when isolation is worktree>
delivered: <no | branch <name> | working tree | commits>
updated: <YYYY-MM-DD>
---

## Tasks
- [ ] T1 [backend] Add `magic_links` table and model — files: `app/models/…`; acceptance: AC1; depends: none
- [ ] T2 [ai] Classify sign-in risk with the LLM — files: `app/ai/risk.py`; acceptance: AC4; depends: T1
- [ ] T3 [uiux] Email entry form with all states — files: `web/src/…`; acceptance: AC2, AC3; depends: none

## Board
| Task | Status | Agent | Attempts | Note |
|------|--------|-------|----------|------|
| T1 | merged | — | 1 | |
| T2 | running | <agent id> | 1 | |
| T3 | todo | — | 0 | |

## Build log
- <date> T1 merged — <one-line note: what changed that later tasks need to know>
```

Board statuses: `todo` → `running` → `verifying` → `merged`, or `blocked`. A task's checkbox is ticked when it is `merged`. The board is the build's saved state: `/team-build` resumes from it in any session.

Owner tags map to subagents: `[ai]` → `team-ai-engineer`, `[backend]` → `team-backend-engineer`, `[uiux]` → `team-uiux-engineer`.

## Isolation and delivery

**Worktree isolation** (default when the project is a git repo with at least one commit): every running task gets its own git worktree and branch, started from the feature's integration branch. Verified tasks are committed on their task branch and merged into the integration branch one at a time. Review, security, and QA work in the integration worktree. The user's current branch and working tree are untouched until delivery.

Branches: `dev-team/<slug>/integration` and `dev-team/<slug>/<task>`. They are local team plumbing: never pushed, deleted after delivery.

**Shared isolation** (fallback: no git, no commits yet, or the user opts out): engineers work in the project root, tasks that touch overlapping files never run at the same time, and nothing is committed.

**Delivery** happens after QA approves, or when the user asks (`/team deliver <feature>`). Ask how to deliver with AskQuestion, recommending the choice saved in `PROJECT.md` → Delivery preference if there is one, and save the answer there:
1. **As a branch** (recommended): create a branch named per `STANDARDS.md` (e.g. `feature/<slug>`) from the integration branch. The user reviews it, pushes it, and opens a PR.
2. **Into my working tree:** `git merge --squash dev-team/<slug>/integration` on the user's current branch, so changes appear uncommitted. First check the user has no uncommitted changes in files the feature touches; if they do, ask.
3. **As commits on my current branch:** one squashed commit or one per task, with messages per the commit rules in `STANDARDS.md`.

After delivery: `git worktree remove` the feature's worktrees, delete its `dev-team/<slug>/*` branches, and set `delivered:` in `tasks.md`. If plan docs list this work, propose the exact edits that mark it done, and apply them only if the user approves.

**Stacked features.** When feature B `depends_on` feature A, B's integration branch starts from A's. Deliver A first. As a branch, B's branch then sits on top of A's, like stacked PRs. Into the working tree, apply only B's own changes with `git diff dev-team/A/integration dev-team/B/integration | git apply`, so keep A's integration branch until its dependents are delivered.

## Findings format (review, security, qa)

```markdown
### R1 — <short title>
- **Severity:** critical | major | minor
- **Where:** `path/to/file.py:42`
- **Problem:** <what is wrong and the concrete consequence>
- **Rule:** <the STANDARDS.md rule it breaks, if any>
- **Fix:** <specific change>
- **Status:** open | fixed | won't fix (<reason>)
```

Prefix IDs per artifact: `R` review, `S` security, `Q` qa, `A` accept, `G` audit.

## Ground rules

- **The user decides.** Recommend, then ask. Never change the agreed scope without asking.
- **Stay in scope.** Ideas outside the spec go to `.dev-team/<slug>/followups.md`, not into the code.
- **Follow `STANDARDS.md`.** If a task seems to need breaking a rule, ask; don't break it silently. In `existing` mode, no drive-by refactors, renames, reformatting, or dependency changes outside the task.
- **Comment for the next developer.** All code the team writes follows `skills/team/COMMENTING.md`: explain what and why, never change history.
- **Never edit project docs** (everything in `PROJECT.md` → Project docs, wherever it lives, and user-provided files). Propose changes to the user instead. The one exception: a specific edit to a plan doc (e.g. ticking delivered tasks in `tasks.md`) that the user approved.
- **Hands off the user's git.** Never commit to, reset, rebase, or push the user's branches, and never open PRs, except through delivery or when the user asks. The team's own `dev-team/*` branches and `.dev-team/worktrees/` are local plumbing the lead manages; they are never pushed. Follow the commit and branch rules in `STANDARDS.md` for anything the user receives.
- **Evidence over claims.** A check "passed" only if you ran it and saw it pass. Say what you could not run.
- **Secrets are never stored.** If a login, password, token, or any value from a `.env` file is used, read, or written, that value is strictly prohibited from being stored. Do not keep it in the session, on disk, or in any rule file (`.cursor/rules/`, `.claude/rules/`, `AGENTS.md`, `CLAUDE.md`, `STANDARDS.md`, or any other). Do not quote it in artifacts, commits, logs, screenshots, or a browser storage export. An existing `.env` may be symlinked so the app can start; its contents are never copied.
