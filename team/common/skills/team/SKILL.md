---
name: team
description: Dev team orchestrator. Shows the status of the project setup and features in .dev-team/ and starts the next step of the team flow (kickoff or onboard, then /team-run). Use only when the user invokes /team.
disable-model-invocation: true
---

# /team — Dev Team Orchestrator

For status, read only frontmatter (`head -12`), `pipeline.md` files, sprint Items tables, and `rg -c` counts. Never read `FLOW.md`, specs, designs or code in this chat; feature work follows `skills/team-run/SKILL.md`.

## Usage

- `/team` — show status and recommend the next step.
- `/team <idea, ticket, or feature request>` — start it with `/team-run` (the conductor picks the quick, light or full track).
- `/team next` — in `new` mode, same as `/team-run next` (the next unchecked feature in `BACKLOG.md`).
- `/team run [feature]` — same as `/team-run <feature>`: every step in order, each in a fresh agent, stopping only at the delivery gate (or also after spec and design with `gated`).
- `/team deliver <feature>` — same as `/team-run <feature> only deliver`.
- `/team <feature>` — show status of one feature (from its `pipeline.md`) and offer to continue it.

All feature work runs through `skills/team-run/SKILL.md`: read it and follow it whenever a step has to run. For a whole sprint, use `/team-sprint plan` and then `/team-run sprint <name>`. Deferred work lives under `## Deferred` in `.dev-team/BACKLOG.md`. To review and merge a teammate's branch, use `/team-accept <branch>`. To validate work already built, use `/team-audit <sprint>`. To find the root cause of a bug before fixing it, use `/team-rca <symptom or ticket>`.

## Status

1. **Mode and setup.** The mode is `mode:` in `PROJECT.md`'s frontmatter, or before setup: `skills/team-kickoff/` installed means `new`, `skills/team-onboard/` means `existing`. If `.dev-team/PROJECT.md` or `.dev-team/STANDARDS.md` is missing or not approved, recommend `/team-kickoff` (new) or `/team-onboard` (existing). Nothing else can run until setup is approved.
2. **Docs freshness.** After setup, start a `team-analyst` (no model) with PROCEDURE `skills/team-docs/PROCEDURE.md` (absolute path under this host's folder), PHASE `scan`, ROOT, OUTPUT `.dev-team/setup/docs-scan.md`, NOTES `status only`. If its summary lists added, changed or removed docs, recommend `/team-docs`. Skip this when the user only asked about one feature.
3. **Backlog.** `new` mode: count features in `BACKLOG.md` by checked vs unchecked (`rg -c`), and name the current milestone. Both modes: count the items under `## Deferred`.
4. **Features.** For each feature folder (not `context/`, `setup/`, `docs/`, `sprints/`, `accept/`, `audit/`, `worktrees/`), read the frontmatter and the last Log line of `pipeline.md`, or the artifacts' frontmatter if it has none. One line per feature: slug, track, current step, tasks merged, whether it's delivered, and the conductor holding it if its heartbeat is under 30 minutes old.
5. **Sprints.** For each `.dev-team/sprints/*.md` not `done`, report its status and item progress.
6. **Acceptances and audits.** For each `.dev-team/accept/*.md` and `.dev-team/audit/*.md` not `done`, report what it covers, its status, and open findings (`rg -c 'Status:\*\* open'`). If `BACKLOG.md` has features marked "(built, not verified)", recommend `/team-audit` for them before new work.
7. **Recommend** the next command: `/team-run <slug>` for the most recently updated unfinished feature, or in `new` mode `/team-run next` if none is in progress.

## Other commands

| Command | Skill file |
|---------|-----------|
| setup (new) | `skills/team-kickoff/SKILL.md` |
| setup (existing) | `skills/team-onboard/SKILL.md` |
| re-sync with project docs | `skills/team-docs/SKILL.md` (then `/team-run` rebuilds `.dev-team/context/`) |
| choose a sprint's items | `skills/team-sprint/SKILL.md` |
| accept a teammate's branch | `skills/team-accept/SKILL.md` |
| audit existing work | `skills/team-audit/SKILL.md` |
| root cause of a bug | `skills/team-rca/SKILL.md` |

Setup documents are approved only by the user.
