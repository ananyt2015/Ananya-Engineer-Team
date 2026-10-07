---
name: team
description: Dev team orchestrator. Shows the status of the project setup and features in .dev-team/ and runs the next stage of the team flow (kickoff or onboard, plan, architect, build, review, security, qa). Use only when the user invokes /team.
disable-model-invocation: true
---

# /team — Dev Team Orchestrator

Read `skills/team/FLOW.md` first. It defines the modes, pipeline, artifacts, gates, and ground rules.

## Usage

- `/team` — show status and recommend the next step.
- `/team <idea, ticket, or feature request>` — start a new feature at `/team-plan`.
- `/team next` — in `new` mode, start the next unchecked feature in `BACKLOG.md`.
- `/team run [feature]` — run the remaining stages in order, stopping at every approval gate.
- `/team deliver <feature>` — deliver a feature's integration branch (see "Delivery" in FLOW.md).
- `/team <feature>` — show status of one feature and offer to run its next stage.

For several features at once, use `/team-sprint`. To review and merge a teammate's branch, use `/team-accept <branch>`. To validate work already built, use `/team-audit <sprint>`.

## Status

1. **Mode and setup.** Determine the mode (FLOW.md). If `.dev-team/PROJECT.md` or `.dev-team/STANDARDS.md` is missing or not approved, say so and recommend `/team-kickoff` (new) or `/team-onboard` (existing). Nothing else can run until setup is approved.
   - In `new` mode before kickoff, list the `.md` files under `docs/` and elsewhere in the repo, so the user can see what kickoff will offer.
   - After setup, run the docs freshness check from FLOW.md and report any added, changed, or removed docs, recommending `/team-docs`.
2. **Backlog** (`new` mode). Count features in `BACKLOG.md` by checked vs unchecked, and name the current milestone.
3. **Features.** For each feature folder (FLOW.md → resolving features), read each artifact's frontmatter and the board in `tasks.md`. Report one line per feature: slug, current stage, tasks merged/running/blocked, open critical/major findings, and whether it's delivered.
4. **Sprints.** For each `.dev-team/sprints/*.md` not `done`, report its status and item progress.
5. **Acceptances and audits.** For each `.dev-team/accept/*.md` and `.dev-team/audit/*.md` not `done`, report what it covers, its status, and open findings. If `BACKLOG.md` has features marked "(built, not verified)", recommend `/team-audit` for them before new work.
6. **Recommend** the next command for the most recently updated unfinished feature, or in `new` mode, the next backlog feature if none is in progress.

The next stage of a feature is the first of these that is missing or not approved:
`spec.md` → `design.md` + `tasks.md` → all tasks merged → `review.md` → `security.md` → `qa.md` → delivered.
When `qa.md` is approved with no open critical/major findings, the feature is done: set `status: done` in `tasks.md`, and in `new` mode tick the feature in `BACKLOG.md`. Delivery follows (QA's last step).

## Running stages

To run a stage, read that stage's skill file and follow it exactly:

| Stage | Skill file |
|-------|-----------|
| setup (new) | `skills/team-kickoff/SKILL.md` |
| setup (existing) | `skills/team-onboard/SKILL.md` |
| re-sync with project docs | `skills/team-docs/SKILL.md` |
| plan | `skills/team-plan/SKILL.md` |
| architect | `skills/team-architect/SKILL.md` |
| build | `skills/team-build/SKILL.md` |
| review | `skills/team-review/SKILL.md` |
| security | `skills/team-security/SKILL.md` |
| qa and delivery | `skills/team-qa/SKILL.md` |
| sprint | `skills/team-sprint/SKILL.md` |
| accept a teammate's branch | `skills/team-accept/SKILL.md` |
| audit existing work | `skills/team-audit/SKILL.md` |

In `run` mode, after each stage's approval gate, continue to the next stage. Stop when the user picks Stop or Revise, when a stage reports a blocker, or when the feature is done. Never skip a gate on the user's behalf.
