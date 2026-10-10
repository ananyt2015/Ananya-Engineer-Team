---
name: team-build
description: Build step of the dev team. Runs the approved task cards, up to four at once: a fresh engineer agent builds each in its own git worktree, then a fresh verifier agent checks, commits and merges it into the feature's integration branch. Use only when the user invokes /team-build.
disable-model-invocation: true
---

# /team-build — build step

Each task is built by a fresh engineer agent (up to `Max parallel engineers` at once, default 4) and landed by a fresh `team-verifier` agent, one merge at a time. This chat only keeps the pipeline state.

Follow `skills/team-run/SKILL.md` with `only build` for the feature the user named. Gate: `design.md` and `tasks.md` approved. Task IDs after the feature (e.g. `/team-build <slug> T3 T4`) limit the run to those tasks.

Running it again resumes from `.dev-team/<slug>/pipeline.md`, in Cursor or Claude Code. Next step: `/team-run <slug>` or `/team-review <slug>`.
