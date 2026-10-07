# dev-team

My own AI dev team for Cursor and Claude Code. It only exists in projects I deploy it to, and it works
differently depending on whether I'm starting a project or joining one.

## How it stays out of other projects

Cursor loads project skills and subagents from `<project>/.cursor/skills/` and `<project>/.cursor/agents/`.
Claude Code loads them from `<project>/.claude/skills/` and `<project>/.claude/agents/`.
This repo holds the team definitions; `deploy.sh` copies them into both folders by default
(`--host cursor` or `--host claude` for one). A project without a deploy has none of these files,
so neither tool sees the team there. Nothing is installed globally.

Inside a deployed project, the team still only acts when called: every skill sets
`disable-model-invocation: true`, so it runs only when I type its command. Artifacts live in
`.dev-team/` and are shared between both tools.

**Colleagues.** Share `FOR_COLLEAGUES.md` with them. Each person deploys the same team version into the
project. Planning files under `.dev-team/` (rulebook, accept records, …) are committed so both stay aligned;
worktrees and the tool skill folders stay local. In `new` mode you can also commit the skill folders so
clone is enough.

## Two modes

| | `--mode new` (starting from scratch) | `--mode existing` (joining a running project) |
|---|---|---|
| Setup | `/team-kickoff` reads every `.md` under `docs/` and asks about the rest of the repo | `/team-onboard` asks which docs I have, then studies the codebase and team process |
| Project docs | PRD, SRS, plus project docs like `databases.md`, `manifest.md`, `sprint.md`, wherever they live | Whatever I select or provide; none is fine |
| Produces | `PROJECT.md`, `STANDARDS.md`, `requirements.md`, `architecture.md`, `BACKLOG.md` | `PROJECT.md`, `STANDARDS.md` |
| Rules that win | Project docs (repo docs refine shared ones), then my standards | The project's enforced config, provided docs, observed conventions; my standards only fill gaps |
| Work comes from | The backlog, traced to requirement IDs | Tickets or descriptions |
| Change style | Build it right per the standards | Smallest change that fits; no drive-by refactors |
| Git | Team files can be committed | Skill folders hidden via `.git/info/exclude`; commit `.dev-team/` planning files (worktrees stay hidden) |

## Project rulebook: `.dev-team/STANDARDS.md`

Setup merges every source of rules into one per-project rulebook that every stage and engineer follows.
Each rule cites its source and points to the doc for detail, so the docs stay the source of truth.

- **Docs can live anywhere in the repo.** Setup scans `docs/` and every other `.md` (git-ignored files skipped)
  and gives each a kind and a scope. The kinds are *requirements* (PRD, SRS), *standard* (`databases.md`,
  `manifest.md`, API or naming conventions), *plan* (my own `sprint.md`, `tasks.md`), and *reference*. The scope is
  *shared* (synced across the product's repos, like the PRD and manifest) or *repo* (specific to this repo).
  `deploy.sh` prints what it found.
- **New projects:** everything in `docs/` is read; for the rest of the repo, kickoff asks which files are project docs.
  Project standards adjust my global standards for that project, and repo docs refine shared ones; every override
  is listed. Plan docs shape the backlog: their sprints become milestones, in their order.
- **Existing projects:** onboarding shows the docs it found and asks which to use and whether I have others
  (paths anywhere, or pasted; outside files are copied to `.dev-team/docs/`). With no docs, it learns the rules
  from the code, tags each with a confidence level, and asks me to confirm the uncertain ones.
- **Several repos.** If the product spans several repos, setup records them and what each owns. Each repo's team
  plans and builds only its own part, and records what it needs from the others as cross-repo dependencies with
  the agreed contract. If the other repos are checked out locally, `/team-docs` checks the shared docs for copies
  that have drifted apart.
- **Docs change later?** Run `/team-docs`. It rescans, shows added, changed, removed, and never-classified docs,
  checks shared copies for drift, and proposes updates to the rulebook, requirements, backlog, and the team's plan.
  `/team`, `/team-plan`, and `/team-architect` notice changed docs and suggest it.
- The team never edits project docs; it proposes changes instead. The only exception is a specific edit to a plan
  doc I approve, such as ticking delivered tasks in `tasks.md`.

## Deploy, update, remove

```bash
~/Projects/dev-team/deploy.sh ~/Projects/new-app --mode new
~/Projects/dev-team/deploy.sh ~/Projects/client-app --mode existing
~/Projects/dev-team/deploy.sh ~/Projects/client-app --mode existing --host claude   # Claude Code only

~/Projects/dev-team/deploy.sh ~/Projects/client-app            # update, keeps its mode
~/Projects/dev-team/deploy.sh ~/Projects/client-app --dry-run
~/Projects/dev-team/undeploy.sh ~/Projects/client-app          # remove
```

Both scripts default to the current directory when no path is given. `--mode` is required on first deploy.
`--host` defaults to `both` (Cursor and Claude Code).

- `deploy.sh` records the mode, hosts, and what it installed, with hashes, in `<project>/.dev-team/dev-team.manifest`.
  Older Cursor-only installs (manifest under `.cursor/`) are migrated on the next deploy or undeploy.
- Re-running `deploy.sh` updates files I haven't edited in that project, keeps files I have edited
  (use `--force` to overwrite), and removes files the team no longer includes. Passing a different
  `--mode` switches modes the same way. Passing `--host cursor` or `--host claude` installs only that
  host and removes the other host's team files.
- In `existing` mode, a marked block in `.git/info/exclude` keeps the Cursor/Claude Code skill folders
  out of the project's git without touching its `.gitignore`. Planning files under `.dev-team/` are
  meant to be committed (see `FOR_COLLEAGUES.md`). Worktrees stay hidden. Switching to `new` or
  undeploying removes the block.
- `undeploy.sh` removes only files listed in the manifest, keeps locally edited ones unless `--force`,
  and never deletes feature artifacts in `<project>/.dev-team/` (other than the manifest itself).
- Both refuse to target this repo or `~` (deploying into `~/.cursor` or `~/.claude` would make the team global).

## The team

| Command | Role | Output in `.dev-team/` |
|---------|------|-------------------------|
| `/team-kickoff` | New project setup from `docs/` and repo-level docs (new mode) | `PROJECT.md`, `STANDARDS.md`, `requirements.md`, `architecture.md`, `BACKLOG.md` |
| `/team-onboard` | Learn an existing project from provided docs and code (existing mode) | `PROJECT.md`, `STANDARDS.md` |
| `/team-docs` | Rescan `docs/` and repo-level docs, check shared copies for drift, adjust rules and plan | updates the above |
| `/team-plan` | Product Planner: spec with testable acceptance criteria | `<feature>/spec.md` |
| `/team-architect` | Architect: design and task breakdown by owner | `<feature>/design.md`, `tasks.md` |
| `/team-build` | Engineering lead: delegates tasks to engineers, verifies, ticks them off | code, tests |
| `/team-review` | Code Reviewer: bugs, edge cases, rule violations, regressions, scope drift | `<feature>/review.md` |
| `/team-security` | Security Reviewer: exploitable issues, including LLM risks | `<feature>/security.md` |
| `/team-qa` | QA Tester: verifies every acceptance criterion, browser walkthrough for UI | `<feature>/qa.md` |
| `/team` | Orchestrator: status, next step, `/team next`, `/team run`, `/team deliver` | — |
| `/team-sprint` | Sprint lead: plans several features together, one build scheduler, batched questions | `sprints/<name>.md` |
| `/team-accept` | Acceptance lead: reviews, verifies, and merges a teammate's branch or PR | `accept/<slug>.md` |
| `/team-audit` | Audit lead: validates work already built against the plan, turns gaps into a feature | `audit/<name>.md` |
| `/team-rca` | Root Cause Analyst: reproduces a bug, bisects, proves the cause, proposes the fix | `<slug>/rca.md`, `<slug>/rca/` |

Engineers are subagents that `/team-build` delegates to by the task's owner tag:

| Tag | Subagent | Focus |
|-----|----------|-------|
| `[ai]` | `team-ai-engineer` | LLM integrations, prompts, RAG, tool calling, evals |
| `[backend]` | `team-backend-engineer` | Python and JS/TS APIs, data, migrations, jobs |
| `[uiux]` | `team-uiux-engineer` | Components, states, accessibility, responsive layout |

Every stage stops for my approval before the next one can start. The team never touches my branches or pushes
anything except through delivery.

## How builds run

- **Dependency-driven.** A task starts the moment the tasks it depends on are merged. There are no waves, so a slow
  task only delays the tasks that need it. At most 4 engineers run at once (`PROJECT.md` → Max parallel engineers).
- **Isolated.** Each task runs in its own git worktree and branch (`dev-team/<feature>/<task>`) under
  `.dev-team/worktrees/`, which is always git-ignored. Engineers can't collide or see each other's half-finished edits.
- **Verified, then merged one at a time** into the feature's integration branch, with checks re-run after each merge
  to catch tasks that clash. On a conflict, the task's engineer rebases and resolves it.
- **Resumable.** The board in `tasks.md` is the saved state; `/team-build` picks up where it left off in any chat.
- **Delivered on my terms.** My branch and working tree are untouched until QA passes. I then choose: a branch
  for a PR (`feature/<slug>`), uncommitted changes in my working tree, or commits on my current branch.
  The team's internal branches are local and deleted after delivery.
- **Fallback.** Without git (or before the first commit), builds run in the project root without isolation.

A sprint (`/team-sprint plan <name>`) plans several tickets or backlog features with one round of questions and
one approval per stage, builds all their tasks through the same scheduler, and delivers them in dependency order.
Features that depend on each other stack like stacked PRs.

## Accepting a teammate's work

`/team-accept <branch>` is for code the team didn't build, such as a sprint a friend did by hand. The team:

1. Fetches the branch into its own worktree (my checkout is untouched), shows its commits and changed files,
   and flags files that `main` also changed since the branch started, since that is where conflicts come from.
2. Works out what the branch was meant to deliver from the sprint plan, backlog, and PRD/SRS, and has me
   confirm that scope. Changes that match no item are flagged as unplanned.
3. Runs review, security, and QA against that scope and the project's rulebook, separating failures the branch
   introduced from ones that were already there.
4. Fixes findings itself or writes a standalone feedback file for the author, as I choose per finding.
   `/team-accept recheck <slug>` reviews whatever the author pushes next.
5. After I approve, builds the merge (merge commit, squash, or rebase) on a candidate branch, resolves conflicts
   with my sign-off, runs the full checks on the combined code, then fast-forwards `main` and pushes if I say so.
   It can open a PR instead for a protected `main`. It never pushes to the author's branch.

**Comments.** Engineers comment their code so the next developer understands what it does and why without
the spec or the chat: docstrings on public interfaces, the reasoning behind non-obvious logic (with requirement
IDs or ticket keys), and no change-history comments, since that belongs in commits. The format follows the project's
rulebook. Build verifies it and review flags gaps. The full guide is `team/common/skills/team/COMMENTING.md`.

Typical runs:

```
# new project
/team-kickoff                      # point it at the PRD and SRS
/team-plan project-foundation      # first backlog feature: repo, tooling, CI
/team run                          # architect → build → review → security → qa
/team next                         # next backlog feature

# existing project
/team-onboard
/team-plan PROJ-142                # or paste the ticket / describe the change
/team run

# a bug or incident: root cause first, then the fix
/team-rca PROJ-207 good v2.3.0     # reproduce, bisect from the last good release, prove the cause
/team run proj-207-export-timeout  # spec from rca.md → architect → build → review → security → qa

# a sprint of several tickets
/team-sprint plan sprint-12        # pick tickets, batched specs and designs
/team-sprint build                 # all tasks, one scheduler
/team-sprint next                  # review → security → qa → deliver, per item

# joining my own project mid-way: sprint 1 on main, a teammate's sprint 2 on a branch
/team-kickoff                      # docs + the code already built; verifies commands
/team-audit sprint-1 against origin/sprint-2   # what's really done, gaps, overlap with sprint 2
/team run sprint-1-gaps            # build the gaps, deliver to main
/team-accept origin/sprint-2       # validate sprint 2, fix or send back, merge

# a sprint a teammate built
/team-accept origin/sprint-2       # scope → review/security/qa → fix or send back
/team-accept recheck accept-sprint-2   # after they push fixes
/team-accept merge accept-sprint-2     # build, verify, and merge into main
```

## My standards

`standards/` holds my rules. They are deployed to `<project>/.cursor/skills/team/standards/`
and `<project>/.claude/skills/team/standards/`.

| File | What goes in it |
|------|-----------------|
| `standards/stack.md` | Default technology choices for new projects |
| `standards/coding.md` | Structure, naming, types, errors, API design, security, testing |
| `standards/workflow.md` | Planning, branches, commits, PRs, definition of done, communication |

They ship as templates. The team ignores any file that still has only `<!-- … -->` placeholders,
so fill them in before relying on them. Add more `.md` files here and they deploy automatically.

These are my defaults across all projects. Project-specific rules live in that project's docs
(`docs/` or repo-level, new mode) or are provided at onboarding (existing mode); they adjust these defaults per project.

## Layout

```
team/
  common/                  # deployed in both modes
    skills/team/SKILL.md   # /team orchestrator
    skills/team/FLOW.md    # modes, rule precedence, docs freshness, artifacts, gates
    skills/team/STANDARDS_TEMPLATE.md  # format of the per-project rulebook
    skills/team/COMMENTING.md          # how engineers comment code
    skills/team/PLAYWRIGHT.md          # local Playwright browser checks; not added to the product
    skills/team-*/SKILL.md # one skill per stage
    agents/team-*.md       # engineer subagents
  new/skills/team-kickoff/     # new mode only
  existing/skills/team-onboard/ # existing mode only
standards/                 # my standards, deployed to .cursor and .claude skills/team/standards/
deploy.sh  undeploy.sh  lib.sh  VERSION
```

## Changing the team

- Edit a role: change its file under `team/` or `standards/`, then re-run `deploy.sh` on each project that should get it.
- Add a role: add `team/common/skills/team-<role>/SKILL.md` (stage) or `team/common/agents/team-<role>.md`
  (subagent), wire it into `FLOW.md` and the `/team` stage table, then redeploy.
- Mode-specific files go in `team/new/` or `team/existing/` with the same layout as `common/`.
- Bump `VERSION` when you change behaviour; it is recorded in each project's manifest.
- Customise one project only: edit the deployed file in that project. Future deploys keep it.
