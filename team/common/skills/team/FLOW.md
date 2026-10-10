# Dev Team Flow — shared conventions

Reference for the team's agents. Main chats don't read this file; an agent reads only the sections its instructions or procedure name.

## Host (Cursor or Claude Code)

The team installs into whichever coding tools the project uses:

| | Cursor | Claude Code |
|---|---|---|
| Skills | `.cursor/skills/<name>/SKILL.md` | `.claude/skills/<name>/SKILL.md` |
| Agents | `.cursor/agents/<name>.md` | `.claude/agents/<name>.md` |
| Always-loaded rule | `.cursor/rules/dev-team.mdc` | `.claude/CLAUDE.md` |

Artifacts always live in `.dev-team/` (same for both), so a pipeline started in one tool can be resumed in the other. When a file says `skills/team/FLOW.md`, open it under the host running this session. Deploy installs both by default.

**Structured questions.** Ask the user with the host's question tool: **AskQuestion** in Cursor, **AskUserQuestion** in Claude Code. If neither is available, number the options in prose and wait for a reply.

**Fresh agents.** Every step of the work runs in its own subagent and its session ends when it reports: feature steps through `/team-run` (`skills/team-run/SKILL.md`), setup, docs, accept, audit and RCA phases through `team-analyst`. Agents have `model: inherit`, so they use the model selected in the chat; never pass a model. In Claude Code each agent also gets only the tools it needs (`tools:` in its file); Cursor ignores that field.

## Project modes

The mode is recorded as `mode:` in `.dev-team/PROJECT.md`.

| | `new` — starting from scratch | `existing` — joining a running project |
|---|---|---|
| Setup command | `/team-kickoff` | `/team-onboard` |
| Project docs | Every `.md` file under `docs/`, plus the repo-level docs the user selects | Whatever docs the user selects or provides; possibly none |
| Source of requirements | PRD and SRS (usually in `docs/`), ordered by plan docs if there are any | Tickets, issues, or a description from the user |
| Change style | Build it right per the standards | Smallest change that fits the codebase as it is |

Before `PROJECT.md` exists, the mode is whichever setup skill is installed: `skills/team-kickoff/` means `new`, `skills/team-onboard/` means `existing`.

## The project rulebook: `.dev-team/STANDARDS.md`

Setup writes `STANDARDS.md`: the effective rules for *this* project, merged from every source below, each rule citing its source. It summarises rules and points to the source doc for detail; the source docs stay the source of truth. Pipeline agents read the per-role extracts in `.dev-team/context/` instead of the whole file.

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

Project docs can live anywhere in the repo: product-wide docs shared across repos (often in `docs/`) and docs specific to this repo (its own `databases.md`, `sprint.md`, `tasks.md`). `skills/team-docs/PROCEDURE.md` defines their kinds (requirements, standard, plan, reference), scopes (shared or repo), and how they combine. `PROJECT.md` records them in Project docs, Doc sources, and Product repos.

**Plan docs** (the user's own sprint and task lists) decide which work is in which sprint, in what order, and what is done. The team follows them and never overrides requirements or standards with them.

**Several repos.** When `PROJECT.md` lists product repos, each requirement has an owner. Plan, design, and build only this repo's part. Record what other repos must provide, and the contract both sides agree on, as a cross-repo dependency; never edit another repo.

## Docs freshness

`/team` checks freshness when showing status: compare the current hashes of the docs in `PROJECT.md` → Project docs, and look for new `.md` files where Doc sources says it scanned (excluding its Ignored list). If anything changed, recommend `/team-docs`. `/team-run` only checks that `.dev-team/context/` matches `PROJECT.md` and `STANDARDS.md`, and rebuilds it if not.

## Pipeline

| Step | Command | Agent (fresh session) | Writes |
|------|---------|-----------------------|--------|
| setup | `/team-kickoff` (new) or `/team-onboard` (existing) | `team-analyst`, one per phase | `PROJECT.md`, `STANDARDS.md`, mode-specific docs |
| context | (automatic) | `team-context-builder` | `.dev-team/context/*` |
| spec | `/team-plan` | `team-planner` | `spec.md` |
| design | `/team-architect` | `team-tech-lead` | `design.md`, `tasks.md`, `tasks/T*.md` |
| build | `/team-build` | `team-backend-engineer`, `team-uiux-engineer`, `team-ai-engineer` (up to 4 at once), then `team-verifier` per task | code + tests, merged into the integration branch |
| review | `/team-review` | `team-reviewer` (fixes: engineer + verifier) | `review.md` |
| security | `/team-security` | `team-security-reviewer` (fixes: engineer + verifier) | `security.md` |
| qa | `/team-qa` | `team-qa-tester` (fixes: engineer + verifier) | `qa.md` |
| comments | delivery gate, if the user says yes | `team-commenter`, then `team-verifier` | comments on the touched functions |
| deliver | `/team-run <slug> only deliver` | `team-releaser` | feature branch, backlog entry if comments were declined |

**Tracks.** `quick` (about 1–3 files, one repo, one owner, no contract, schema, auth, payment, dependency or prompt change): design, one build and verify, delivery. `light` (no behaviour change): design, builds and verifies, delivery. `full`: every step. The conductor picks the track; the tech lead confirms or escalates it.

**Stops.** The user is asked only at the delivery gate (deliver how, and whether to add comments), when an agent needs an answer or is blocked, and after spec and design when the run is `gated`. After the design the conductor shows a short FYI and continues. Critical and major findings are fixed automatically; minor ones are listed at the delivery gate.

### Pipeline and handoffs
- **State:** `.dev-team/<slug>/pipeline.md` (steps, attempts, log, and which conductor holds the item). The conductor reads only this, frontmatter, and each agent's short report. It starts at most 25 agents per chat and resumes in a new chat, in either tool, from `pipeline.md`.
- **Inputs:** each agent gets a prompt of absolute paths (STEP, ATTEMPT, PIPELINE, WORKSPACE, INPUTS, OUTPUT, HANDOFF, NOTES) and reads only those files plus the code it needs.
- **Handoffs:** each agent writes `.dev-team/<slug>/handoff/<NN>-<step>.md` (≤ 40 lines) for the next agent and replies with a report of 15 lines or fewer.
- **Task cards:** `tasks/Tn.md` is self-contained (goal, files, acceptance criteria verbatim, design excerpt, rules file, checks), sized for one short session (about 15 files or one module).
- **Questions:** agents can't ask the user; they return NEEDS-INPUT with questions, the conductor asks, and answers go to `.dev-team/<slug>/answers.md`.
- **Attempts:** a step interrupted by a usage limit, a crash, or a switch to the other tool is rerun as the next Try. Agents check `pipeline.md` before landing anything and stop (SUPERSEDED) if their attempt was replaced.

`/team-accept` handles work the team didn't build, such as a teammate's sprint branch. `/team-audit` validates work already on a branch and turns its gaps into a `<name>-gaps` feature. `/team-rca` proves a bug's root cause in `<slug>/rca.md`; the fix runs as `/team-run <slug>`.

## Workspace layout

```
.dev-team/
  PROJECT.md            # project profile, project docs index
  STANDARDS.md          # effective rules for this project
  context/              # per-role extracts of PROJECT.md + STANDARDS.md (team-context-builder; never edit by hand)
  setup/                # setup and docs-sync work files (discovery, answers, findings, proposals)
  requirements.md       # new mode: requirement index from PRD + SRS
  architecture.md       # new mode: system architecture
  BACKLOG.md            # new mode: ordered features traced to requirements; both modes: "## Deferred" work
  docs/                 # copies of docs the user provided from outside the repo
  sprints/<name>.md     # sprint plans and boards
  accept/<slug>.md      # acceptance records (/team-accept), with -answers.md and -feedback.md
  audit/<name>.md       # validation records (/team-audit), with -answers.md
  worktrees/            # git worktrees (always git-ignored, never committed)
    <feature-slug>/integration/   # the feature's integration branch checkout
    <feature-slug>/T1/            # one checkout per running task (T1-a2 after a takeover)
  <feature-slug>/       # one folder per feature or ticket
    pipeline.md         # pipeline state (/team-run)
    rca.md rca/         # bug fixes only: root cause analysis and its evidence (/team-rca)
    spec.md design.md tasks.md review.md security.md qa.md followups.md answers.md
    tasks/T1.md …       # self-contained task cards
    handoff/NN-step.md  # one short note per finished step
    preflight-<repo>.txt  # project-root git status at build start
```

The slug is kebab-case, at most 40 characters, derived from the feature name or ticket (e.g. `magic-link-login`, `proj-142-fix-export`).

**Resolving which feature to work on:**
1. If the user named a feature, slug, or ticket, use it.
2. Otherwise, list `.dev-team/*/` (excluding `context/`, `setup/`, `docs/`, `sprints/`, `accept/`, `audit/`, `worktrees/`). If exactly one feature is not `done`, use it.
3. Otherwise, ask, listing the candidate features.

## Artifact header

Every artifact starts with this frontmatter. Keep it accurate; other steps read it.

```yaml
---
feature: <slug, or "project" for project-level docs>
stage: project | standards | requirements | architecture | backlog | rca | spec | design | tasks | review | security | qa | accept | audit | pipeline
status: draft | approved | done
updated: <YYYY-MM-DD>
---
```

## Gates

- Everything after setup needs `.dev-team/PROJECT.md` and `.dev-team/STANDARDS.md` with `status: approved`. Setup documents are approved only by the user.
- In `new` mode, the spec step also needs `requirements.md`, `architecture.md`, and `BACKLOG.md` approved, and `rca.md` approved when the feature folder has one.
- Within `/team-run`, `spec.md`, `design.md` and `tasks.md` are set to `approved` when their step finishes (by the user when the run is `gated`).

**Where the code is:** if `tasks.md` has `isolation: worktree` and is not yet delivered, the feature's code is in its `worktree:` path, not the project root. Read, diff (`git -C <worktree> diff <base>...HEAD`), test, and fix there.

## Isolation and delivery

**Worktree isolation** (default when the project is a git repo with at least one commit): every build gets its own git worktree and branch, started from the integration branch's tip, so it contains every merged dependency. Up to `Max parallel engineers` (default 4) builds run at once; their verifiers merge into the integration branch one at a time. Review, security, QA, fixes and comments work in the integration worktree. The user's branch and working tree are untouched until delivery.

Branches: `dev-team/<slug>/integration` and `dev-team/<slug>/<task>` (`<task>-a<try>` after a takeover). They are local team plumbing: never pushed, deleted after delivery.

**Shared isolation** (fallback: no git, no commits yet, or the user opts out): engineers work in the project root, builds that touch overlapping files never run at the same time, and nothing is committed.

**Delivery** happens at the delivery gate. The user picks: a branch named per the project's rules (recommended, e.g. `feature/<slug>`), a squash into their working tree, or a commit on their current branch. The first choice is saved as the Delivery preference. Afterwards the feature's worktrees and `dev-team/<slug>/*` branches are removed and `delivered:` is set in `tasks.md`. If plan docs list this work, the exact edits that mark it done are proposed and applied only if the user approves.

**Stacked features.** When feature B `depends_on` feature A, B's integration branch starts from A's. Deliver A first. Into the working tree, apply only B's own changes with `git diff dev-team/A/integration dev-team/B/integration | git apply`, so keep A's integration branch until its dependents are delivered.

## Findings format (review, security, qa)

```markdown
### R1 — <short title>
- **Severity:** critical | major | minor
- **Owner:** backend | uiux | ai
- **Where:** `path/to/file.py:42`
- **Problem:** <what is wrong and the concrete consequence>
- **Rule:** <the STANDARDS.md rule it breaks, if any>
- **Fix:** <specific change>
- **Status:** open | fixed | blocked | won't fix (<reason>)
```

Prefix IDs per artifact: `R` review, `S` security, `Q` qa, `A` accept, `G` audit.

## Ground rules

- **The user decides.** Recommend, then ask. Never change the agreed scope without asking.
- **Stay in scope.** Ideas outside the spec go to `.dev-team/<slug>/followups.md`, not into the code.
- **Follow `STANDARDS.md`.** If a task seems to need breaking a rule, ask; don't break it silently. In `existing` mode, no drive-by refactors, renames, reformatting, or dependency changes outside the task.
- **Comments at delivery.** Engineers comment only non-obvious logic in their own change (the why: business rule, security check, workaround), never change history. At delivery the user is asked whether to add comments to the functions the change touched; declined comments become a backlog entry (except on the quick track). The team never runs comment passes over whole codebases. `skills/team/COMMENTING.md` is the style guide.
- **Keep context small.** Search with `rg`, read line ranges, pipe long output through `tail` or `head`, never print lockfiles, generated files or full logs. Main chats never read big documents, diffs or code.
- **Never edit project docs** (everything in `PROJECT.md` → Project docs, wherever it lives, and user-provided files). Propose changes instead. The one exception: a specific edit to a plan doc (e.g. ticking delivered tasks in `tasks.md`) that the user approved.
- **Hands off the user's git.** Never commit to, reset, rebase, or push the user's branches, and never open PRs, except through delivery or when the user asks. The team's own `dev-team/*` branches and `.dev-team/worktrees/` are local plumbing; they are never pushed. Follow the commit and branch rules in `STANDARDS.md` for anything the user receives.
- **Evidence over claims.** A check "passed" only if you ran it and saw it pass. Say what you could not run.
- **Secrets are never stored.** If a login, password, token, or any value from a `.env` file is used, read, or written, that value is strictly prohibited from being stored. Do not keep it in the session, on disk, or in any rule file (`.cursor/rules/`, `.claude/rules/`, `AGENTS.md`, `CLAUDE.md`, `STANDARDS.md`, or any other). Do not quote it in artifacts, commits, logs, screenshots, or a browser storage export. An existing `.env` may be symlinked so the app can start; its contents are never copied.
