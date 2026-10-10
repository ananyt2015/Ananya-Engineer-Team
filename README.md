# dev-team

My own AI dev team for Cursor and Claude Code. It only exists in projects I deploy it to, and it works
differently depending on whether I'm starting a project or joining one.

## How it stays out of other projects

Cursor loads project skills and subagents from `<project>/.cursor/skills/` and `<project>/.cursor/agents/`.
Claude Code loads them from `<project>/.claude/skills/` and `<project>/.claude/agents/`.
This repo holds the team definitions; `deploy.sh` copies them into both folders by default
(`--host cursor` or `--host claude` for one). A project without a deploy has none of these files,
so neither tool sees the team there. Nothing is installed globally.

Inside a deployed project, the team still only acts when called: every skill except `team-run` sets
`disable-model-invocation: true`, so it runs only when I type its command. `team-run` can also start when I
ask in plain words to work on a ticket, task or sprint, so that work goes through the pipeline instead of
the main chat. Artifacts live in `.dev-team/` and are shared between both tools.

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
  `/team` notices changed docs and suggests it.
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
- Besides skills and agents, each host gets one always-loaded rule that routes work through `/team-run`:
  `.cursor/rules/dev-team.mdc` and `.claude/CLAUDE.md`. If the project already has its own `.claude/CLAUDE.md`,
  deploy leaves it alone (even with `--force`) and tells me which lines to add.
- Re-running `deploy.sh` updates files I haven't edited in that project, keeps files I have edited
  (use `--force` to overwrite), and removes files the team no longer includes. Passing a different
  `--mode` switches modes the same way. Passing `--host cursor` or `--host claude` installs only that
  host and removes the other host's team files.
- In `existing` mode, a marked block in `.git/info/exclude` keeps the Cursor/Claude Code team files
  out of the project's git without touching its `.gitignore`. Planning files under `.dev-team/` are
  meant to be committed (see `FOR_COLLEAGUES.md`). Worktrees stay hidden. Switching to `new` or
  undeploying removes the block.
- `undeploy.sh` removes only files listed in the manifest, keeps locally edited ones unless `--force`,
  and never deletes feature artifacts in `<project>/.dev-team/` (other than the manifest itself).
- Both refuse to target this repo or `~` (deploying into `~/.cursor` or `~/.claude` would make the team global).

## The team

The main command is **`/team-run <item>`**: a conductor that runs every step of a feature, ticket, plan task or
sprint in a fresh subagent. The chat that runs it only holds a small state file and short reports.

| Command | What it does | Output in `.dev-team/` |
|---------|--------------|-------------------------|
| `/team-run` | Conductor: spec → design → build → verify → review → security → QA → comments → delivery | `<feature>/pipeline.md` and everything below |
| `/team` | Status of setup, features, sprints, accept and audit records; recommends the next command | — |
| `/team-kickoff` | New project setup from `docs/` and repo-level docs (new mode) | `PROJECT.md`, `STANDARDS.md`, `requirements.md`, `architecture.md`, `BACKLOG.md` |
| `/team-onboard` | Learn an existing project from provided docs and code (existing mode) | `PROJECT.md`, `STANDARDS.md` |
| `/team-docs` | Rescan project docs, check shared copies for drift, adjust rules and plan | updates the above |
| `/team-sprint` | Choose a sprint's items and keep its board | `sprints/<name>.md` |
| `/team-accept` | Review, verify, and merge a teammate's branch or PR | `accept/<slug>.md` |
| `/team-audit` | Validate work already built against the plan, turn gaps into a feature | `audit/<name>.md` |
| `/team-rca` | Reproduce a bug, bisect, prove the cause, hand the fix to `/team-run` | `<slug>/rca.md`, `<slug>/rca/` |
| `/team-plan`, `/team-architect`, `/team-build`, `/team-review`, `/team-security`, `/team-qa` | One step of `/team-run` (`only <step>`) | that step's artifact |

The agents (`team/common/agents/`), each started fresh for one step:

| Agent | Step |
|-------|------|
| `team-context-builder` | Small per-role extracts of `PROJECT.md` and `STANDARDS.md` in `.dev-team/context/` |
| `team-planner` | Spec with testable acceptance criteria |
| `team-tech-lead` | Design, task list, and one self-contained card per task; confirms or escalates the track |
| `team-backend-engineer`, `team-uiux-engineer`, `team-ai-engineer` | Build one task card in its own worktree (by owner tag `[backend]`, `[uiux]`, `[ai]`) |
| `team-verifier` | Run the checks, commit, merge into the integration branch |
| `team-reviewer`, `team-security-reviewer`, `team-qa-tester` | Review, security, and QA (also for `/team-accept` and `/team-audit`) |
| `team-commenter` | Docstrings and why-comments on the touched functions, at delivery, if I say yes |
| `team-releaser` | Deliver, clean up, record declined comments in the backlog |
| `team-analyst` | Setup, docs, accept, audit and RCA phases, one `PROCEDURE.md` section at a time |

The team never touches my branches or pushes anything except through delivery.

## How the pipeline runs

- **Tracks.** The conductor picks one and the tech lead can escalate it; `quick`, `light` or `full` after the item
  overrides it.
  - `quick` (about 1–3 files, one repo, one owner, no contract, schema, auth, payment, dependency or prompt
    change): design → one build and verify → delivery.
  - `light` (no behaviour change): design → builds and verifies → delivery.
  - `full`: spec → design → builds and verifies → review → security → QA (each with automatic fixes) → delivery.
- **One stop.** I'm asked only at delivery: how to deliver, and whether to add comments to the functions the change
  touched. After the design the chat shows a short FYI (summary and task list) and keeps going. Agents that need an
  answer or are blocked also stop the run. Add `gated` to also approve the spec and the design.
- **Fixes.** Critical and major findings are fixed automatically by a fresh engineer and verifier; minor ones are
  listed at the delivery gate.
- **Small context everywhere.** Agents get paths, not contents; read only their inputs and the code they need, with
  `rg` and line ranges; pipe long output through `tail`; and have a tool-call budget. Each writes a handoff note
  of 40 lines or fewer and replies in 15 lines or fewer. One chat starts at most 25 agents, then says how to resume.

## How builds run

- **Parallel.** Up to 4 engineers build at once (`PROJECT.md` → Max parallel engineers), each in its own git
  worktree and branch (`dev-team/<feature>/<task>`) under `.dev-team/worktrees/`, which is always git-ignored.
  A task starts when the tasks it depends on are merged.
- **Verified, then merged one at a time** into the feature's integration branch, with checks re-run after each merge.
  On a conflict, the task is rebuilt on the new integration tip.
- **Delivered on my terms.** My branch and working tree are untouched until delivery. I then choose: a branch
  for a PR (`feature/<slug>`), uncommitted changes in my working tree, or a commit on my current branch.
  The team's internal branches are local and deleted after delivery.
- **Fallback.** Without git (or before the first commit), builds run in the project root without isolation.

## Usage limits and switching between Cursor and Claude Code

`.dev-team/<feature>/pipeline.md` is the whole state, and it is written before every agent starts. If a usage limit
or a crash stops a run, nothing is lost: run `/team-run <slug>` again later, in either tool.

`pipeline.md` records which tool and session holds the item (`conductor:`) and when it last acted (`heartbeat:`).
A second chat that finds a heartbeat under 30 minutes old asks before taking over; an older one is taken over
automatically. Steps that were running are marked `interrupted` and rerun as a new attempt in a new worktree and
branch. Agents check `pipeline.md` before they commit or merge, and stop if their attempt was replaced, so two tools
never land work on top of each other.

A sprint (`/team-sprint plan <name>`, then `/team-run sprint <name>`) runs its items one after another in
dependency order. Features that depend on each other stack like stacked PRs.

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

## Comments

While building, engineers write only why-comments for non-obvious logic in their change (with requirement IDs or
ticket keys), never change history. At delivery the team asks whether to add comments: on yes, `team-commenter`
adds headers, docstrings and why-comments to the files and functions the change touched, nothing else, and a
verifier commits them. On no, a line listing the touched files and functions goes under `## Deferred` in
`.dev-team/BACKLOG.md` (not for quick fixes), runnable later as `/team-run comments-<slug> light`. The team never
runs comment passes over whole codebases. The style guide is `team/common/skills/team/COMMENTING.md`.

## Typical runs

```
# new project
/team-kickoff                      # point it at the PRD and SRS
/team-run next                     # first backlog feature: spec → … → delivery
/team-run next                     # the one after

# existing project
/team-onboard
/team-run PROJ-142                 # or paste the ticket / describe the change
/team-run fix the typo in the signup email quick   # small change, quick track
/team-run PROJ-150 gated           # also approve the spec and design

# resume after a usage limit, in either tool
/team-run proj-142-export          # picks up from pipeline.md
/team-run status

# a bug or incident: root cause first, then the fix
/team-rca PROJ-207 good v2.3.0     # reproduce, bisect from the last good release, prove the cause
/team-run proj-207-export-timeout  # spec from rca.md → … → delivery

# a sprint of several tickets
/team-sprint plan sprint-12        # pick the items and their tracks
/team-run sprint sprint-12         # each item through the pipeline, in dependency order

# joining my own project mid-way: sprint 1 on main, a teammate's sprint 2 on a branch
/team-kickoff                      # docs + the code already built; verifies commands
/team-audit sprint-1 against origin/sprint-2   # what's really done, gaps, overlap with sprint 2
/team-run sprint-1-gaps            # build the gaps, deliver to main
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

## Keeping sessions lean

v0.9 runs regularly used tens of millions of tokens, up to about 150M, and spent most of their wall-clock time
locked out by Claude usage limits (about 8 of 11 hours in one session). The causes, and what v0.10 does:

| Cause | Fix |
|-------|-----|
| The lead chat read specs, designs, diffs, `FLOW.md` and long skill files, and grew with every step | `/team-run` reads only `pipeline.md`, frontmatter and short reports; setup, docs, accept, audit and RCA hand their reading to `team-analyst`, one procedure section at a time |
| Every subagent started with about 41k tokens of tool definitions and skill listings (about 40 tools, every MCP server, every installed skill) | In Claude Code, each agent's `tools:` line gives it only the tools it needs (no MCP tools except Playwright for UI/QA, no skill listing). Cursor ignores `tools:` |
| Engineers printed full test, build and install output | `rg`, line-range reads, `tail -n 40`, and a tool-call budget per agent |
| Comment passes and documentation sweeps read whole codebases | Comments only at delivery, only for the touched functions, only if I say yes |
| Every stage waited for my approval, and builds ran one at a time | One stop at delivery, a quick track, up to 4 parallel engineers |
| A usage limit mid-step lost the step | State is written before every agent starts; resume in either tool |

**Global skills and MCP servers.** Skills and MCP servers installed globally (`~/.claude/skills/`, `~/.cursor/skills/`,
plugins, Gmail/Outlook/browser MCP servers) are listed in every main chat, and in Cursor in every subagent. For
projects that run the team, turn off what that project doesn't need:
- **Claude Code:** `/mcp` to disable servers for this project; keep large personal skill suites out of `~/.claude/skills/`
  (or install them per project) if you don't use them in team projects. Subagents with a `tools:` line are already
  unaffected.
- **Cursor:** disable unused MCP servers in Settings → Tools & MCP, and unused skills in the skills settings, per
  project where the setting allows it. Cursor also loads `.claude/agents/` and `.claude/skills/`; agents in `.cursor/`
  win on a name clash, but skills may be listed twice. If a project is used only from Cursor, deploy with
  `--host cursor`.

**Checking a run.** After a pipeline, Claude Code session logs (`~/.claude/projects/<project>/`) show each agent's
token usage; a step that uses far more than its siblings usually read something it shouldn't have.

## Layout

```
team/
  common/                  # deployed in both modes
    skills/team/SKILL.md   # /team status
    skills/team/FLOW.md    # shared conventions agents read by section: modes, precedence, artifacts, isolation
    skills/team/STANDARDS_TEMPLATE.md  # format of the per-project rulebook
    skills/team/COMMENTING.md          # comment style guide
    skills/team/PLAYWRIGHT.md          # local Playwright browser checks; not added to the product
    skills/team-run/SKILL.md           # the conductor
    skills/team-<step>/SKILL.md        # thin wrappers for one pipeline step
    skills/team-<cmd>/SKILL.md + PROCEDURE.md  # docs, accept, audit, rca: the chat asks, team-analyst works
    agents/team-*.md       # every agent, model: inherit
  new/skills/team-kickoff/     # new mode only (SKILL.md + PROCEDURE.md)
  existing/skills/team-onboard/ # existing mode only (SKILL.md + PROCEDURE.md)
  hosts/cursor/rules/dev-team.mdc   # Cursor only: always-loaded routing rule
  hosts/claude/CLAUDE.md            # Claude Code only: the same rule
standards/                 # my standards, deployed to .cursor and .claude skills/team/standards/
deploy.sh  undeploy.sh  lib.sh  VERSION  CHANGELOG.md
```

## Changing the team

- Edit a role: change its file under `team/` or `standards/`, then re-run `deploy.sh` on each project that should get it.
- Add an agent: add `team/common/agents/team-<role>.md` with `model: inherit` and a `tools:` line, then wire it into
  `team-run/SKILL.md` (steps table) or a command's `SKILL.md`.
- Keep main-chat skills thin: questions and approvals in `SKILL.md`, the work in `PROCEDURE.md` sections an agent reads.
- Mode-specific files go in `team/new/` or `team/existing/` with the same layout as `common/`; host-specific files
  go in `team/hosts/<host>/`, relative to that host's folder.
- Bump `VERSION` and add a `CHANGELOG.md` entry when you change behaviour; the version is recorded in each project's manifest.
- Customise one project only: edit the deployed file in that project. Future deploys keep it.
