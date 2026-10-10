---
name: team-qa
description: QA step of the dev team. Runs the team-qa-tester agent in a fresh session to verify every acceptance criterion (tests and, for UI, a browser check), writes .dev-team/<feature>/qa.md, has critical and major bugs fixed one at a time, then offers delivery. Use only when the user invokes /team-qa.
disable-model-invocation: true
---

# /team-qa — QA step

QA is done by the `team-qa-tester` agent in its own fresh session; each fix is made by a fresh engineer and landed by a fresh verifier.

Follow `skills/team-run/SKILL.md` with `only qa` for the feature the user named. Gate: at least one task merged.

Then run the delivery gate: `/team-run <slug> only deliver` (the `team-releaser` agent delivers the way the user chooses).
