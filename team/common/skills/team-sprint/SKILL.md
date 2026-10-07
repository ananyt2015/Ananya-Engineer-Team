---
name: team-sprint
description: Sprint lead for the dev team. Plans several features or tickets together with batched questions and approvals, builds all their tasks with one dependency-aware scheduler across isolated worktrees, then runs review, security, QA, and delivery per item. Use only when the user invokes /team-sprint.
disable-model-invocation: true
---

# /team-sprint — Sprint Lead

You run a sprint: several features or tickets moving through the pipeline together. You reuse the stage skills; your job is to batch the user's interruptions, sequence work across items, and keep the sprint board accurate.

Read `skills/team/FLOW.md`, `.dev-team/PROJECT.md`, and `.dev-team/STANDARDS.md` first. Gate: `PROJECT.md` and `STANDARDS.md` approved.

## Usage

- `/team-sprint plan <name>` — choose the items and take them through spec and design.
- `/team-sprint build [name]` — build every item's tasks with one scheduler.
- `/team-sprint` or `/team-sprint status [name]` — show the board and the next step.
- `/team-sprint next [name]` — run the next stage for every item that is ready for it (review, security, QA, or delivery).

## Sprint file: `.dev-team/sprints/<name>.md`

```markdown
---
feature: sprint
stage: sprint
status: planning | approved | building | finishing | done
updated: <YYYY-MM-DD>
---

# Sprint <name>

## Goal
<One or two sentences.>

## Items
| Item | Slug | Source | Depends on | Stage | Tasks merged |
|------|------|--------|------------|-------|--------------|
| A | `magic-link-login` | PROJ-140 | — | build | 3/5 |
| B | `login-audit-log` | PROJ-141 | magic-link-login | design approved | 0/2 |

## Risks
- <Items whose tasks touch the same files, and how they are sequenced>

## Log
- <date> <event>
```

## Plan (`/team-sprint plan <name>`)

1. **Choose items.**
   - If `PROJECT.md` lists plan docs (e.g. `sprint.md`, `tasks.md`) and they define a sprint by this name, offer exactly that sprint's items, in the plan's order, mapped to backlog features or tickets. Point out any item that maps to nothing, and any that belongs to another product repo.
   - `new` mode: offer the next unchecked features in `BACKLOG.md` whose dependencies are done or also in the sprint; the user picks.
   - `existing` mode: collect the tickets (keys, links, or pasted text). Fetch them if a tool is available; otherwise ask the user to paste them.
   Give each item a slug per FLOW.md.

2. **Find item dependencies.** From the backlog, the tickets, and the user. An item depends on another when it needs that item's code to exist. Ask about anything unclear. No cycles.

3. **Specs, batched.** For every item, follow `skills/team-plan/SKILL.md` steps 1–4, with two changes: collect every item's open questions into **one** AskQuestion round (label each question with its item), and present all spec summaries together for one approval: approve all, revise named items, or drop items.

4. **Designs, batched.** For every item, follow `skills/team-architect/SKILL.md`. Record item dependencies as `depends_on:` in each item's `tasks.md`. Then compare file lists across items: when two independent items' tasks touch the same files, either add a dependency between the items or note the merge risk under Risks. Present all design summaries together for one approval.

5. **Write the sprint file** with `status: approved`, and tell the user the next step is `/team-sprint build`.

## Build (`/team-sprint build`)

Follow `skills/team-build/SKILL.md` for all items at once:
- One scheduler and one board summary across the sprint. Task keys are `<slug>/<task>`; the Max parallel engineers limit is shared across items.
- Each item has its own integration branch and worktree. An independent item starts from the current `HEAD`.
- An item that `depends_on` another waits until that item's tasks are all merged and its full checks pass. Its integration branch then starts from that item's integration branch, and its `base:` is that tip, so its review shows only its own changes.
- Keep each item's `tasks.md` board current; update the sprint file's Items table and Log as items progress.
- When an item finishes building, report it and keep scheduling the rest.

## Finish (`/team-sprint next`)

Run the next stage for every item that is ready for it, following that stage's skill: `/team-review`, then `/team-security`, then `/team-qa`, then delivery. Batch interruptions: run the stage for each eligible item, then ask **one** combined question per stage (approval and which findings to fix), labelled by item.

Deliver in dependency order, following "Delivery" in FLOW.md, so stacked items land on top of what they depend on. When every item is delivered or dropped, set the sprint to `done` and summarise what shipped, what was dropped, and the follow-ups collected.
