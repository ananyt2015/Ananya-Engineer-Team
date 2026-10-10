---
name: team-security
description: Security review step of the dev team. Runs the team-security-reviewer agent in a fresh session on the feature's integrated diff, writes .dev-team/<feature>/security.md, then has fresh engineer and verifier agents fix critical and major findings one at a time. Use only when the user invokes /team-security.
disable-model-invocation: true
---

# /team-security — security step

The audit is done by the `team-security-reviewer` agent in its own fresh session; each fix is made by a fresh engineer and landed by a fresh verifier.

Follow `skills/team-run/SKILL.md` with `only security` for the feature the user named. Gate: at least one task merged.

Next step: `/team-run <slug>` or `/team-qa <slug>`.
