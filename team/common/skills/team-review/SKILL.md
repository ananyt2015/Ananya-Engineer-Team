---
name: team-review
description: Code review step of the dev team. Runs the team-reviewer agent in a fresh session on the feature's integrated diff, writes .dev-team/<feature>/review.md, then has fresh engineer and verifier agents fix critical and major findings one at a time. Use only when the user invokes /team-review.
disable-model-invocation: true
---

# /team-review — review step

The review is done by the `team-reviewer` agent in its own fresh session; each fix is made by a fresh engineer and landed by a fresh verifier.

Follow `skills/team-run/SKILL.md` with `only review` for the feature the user named. Gate: at least one task merged.

Next step: `/team-run <slug>` or `/team-security <slug>`.
