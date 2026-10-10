---
name: team-plan
description: Spec step of the dev team. Runs the team-planner agent in a fresh session to write .dev-team/<feature>/spec.md with testable acceptance criteria, then shows its summary. Use only when the user invokes /team-plan.
disable-model-invocation: true
---

# /team-plan — spec step

The spec is written by the `team-planner` agent in its own fresh session, not in this chat.

Follow `skills/team-run/SKILL.md` with `only spec` for the feature, ticket or plan task the user named. It creates or resumes `.dev-team/<slug>/pipeline.md`, starts the planner, asks the user any questions the planner returns, shows the spec summary and stops.

Next step: `/team-run <slug>` (continues the whole pipeline) or `/team-architect <slug>`.
