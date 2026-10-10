---
name: team-sprint
description: Sprint lead for the dev team. Chooses a sprint's items and writes the sprint board; the items then run one after another through the /team-run pipeline. Use only when the user invokes /team-sprint.
disable-model-invocation: true
---

# /team-sprint — Sprint lead

You choose what goes into a sprint and keep its board. The work itself runs through `/team-run sprint <name>`: items one after another, each item's tasks built up to four at once, each step in a fresh agent.

Gate: `.dev-team/PROJECT.md` and `.dev-team/STANDARDS.md` approved (frontmatter only).

## Usage
- `/team-sprint plan <name>` — choose the items and write `.dev-team/sprints/<name>.md`.
- `/team-sprint` or `/team-sprint status [name]` — show the board (Items table only) and the next step.
- `/team-sprint build [name]` or `/team-sprint next [name]` — same as `/team-run sprint <name>`: follow `skills/team-run/SKILL.md`.

## Plan
1. **Choose items.** Read `.dev-team/context/project.md` for the repos and plan docs. Find the sprint's tasks in the plan docs with `rg` on the sprint name, reading only the matching entries. In `new` mode with no plan docs, offer the next unchecked features in `BACKLOG.md`. Offer them in the plan's order; the user picks. Skip comment-pass and documentation-sweep tasks (comments are added at each item's delivery; leftovers are under `## Deferred` in `.dev-team/BACKLOG.md`) unless the user asks for them. Give each item a slug (kebab-case, ≤ 40 chars, with the task ID).
2. **Dependencies.** An item depends on another when it needs that item's code. Ask about anything unclear; no cycles. Note items that touch the same files under Risks.
3. **Track.** Suggest a track per item: `quick` for small changes (about 1–3 files, no contract, schema, auth, payment, dependency or prompt change), `light` for work that changes no behaviour, `full` otherwise. The tech lead can escalate it later.
4. **Write the sprint file** with `status: approved` (template below). Don't write specs or designs here: each item gets its own when `/team-run` reaches it, and the user is asked only at each item's delivery (also after spec and design if they say `gated`).
5. Tell the user the next step: `/team-run sprint <name>`.

## Sprint file
```markdown
---
feature: sprint
stage: sprint
status: approved | running | done
updated: <YYYY-MM-DD>
---
# Sprint <name>
## Goal
<one or two sentences>
## Items
| Item | Slug | Source | Repo | Depends on | Track | Stage | Tasks merged |
|------|------|--------|------|------------|-------|-------|--------------|
| A | `proj-140-magic-link` | PROJ-140 | api | — | full | todo | — |
## Risks
- <items touching the same files and how they're ordered>
## Log
- <date> <event>
```
