---
name: team-architect
description: Design step of the dev team. Runs the team-tech-lead agent in a fresh session to write design.md, tasks.md and one self-contained task card per task in .dev-team/<feature>/, then shows its summary. Use only when the user invokes /team-architect.
disable-model-invocation: true
---

# /team-architect — design step

The design and task cards are written by the `team-tech-lead` agent in its own fresh session, not in this chat.

Follow `skills/team-run/SKILL.md` with `only design` for the feature the user named. Gate: `spec.md` approved (full track). It starts the tech lead, asks the user any questions it returns, shows the design summary and task list, and stops.

Next step: `/team-run <slug>` or `/team-build <slug>`.
