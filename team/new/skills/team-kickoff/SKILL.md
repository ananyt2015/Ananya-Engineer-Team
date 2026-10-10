---
name: team-kickoff
description: Project kickoff for a new project built from scratch. Fresh agents read every .md under docs/ (PRD, SRS, project docs such as databases.md or manifest.md) plus the repo-level docs the user selects, adjust my global standards into a project rulebook, and produce the project profile, standards, requirement index, architecture and backlog in .dev-team/. Use only when the user invokes /team-kickoff or /team runs project setup in new mode.
disable-model-invocation: true
---

# /team-kickoff — New project kickoff

The work runs in fresh `team-analyst` agents, one per phase. This chat only asks the user and holds the approval: never read the procedures, the docs, or the drafts here.

Arguments: none for a full kickoff. `refresh` follows `skills/team-docs/SKILL.md` (the same as `/team-docs`).

**Starting an analyst:** host subagent tool (Cursor: Task; Claude Code: Agent), `subagent_type: team-analyst`, no model. Prompt: PROCEDURE (absolute path under this host's folder), PHASE, ROOT, INPUTS, OUTPUT, NOTES (`mode: new` plus anything below). `PARTIAL`: start a fresh analyst for the same phase with its NEXT in NOTES. `NEEDS-INPUT`: ask its questions with the host's question tool (one round per batch of 6), append the answers to `.dev-team/setup/answers.md`.

## Steps
1. **Discover docs:** PROCEDURE `skills/team-docs/PROCEDURE.md`, PHASE `discover`, OUTPUT `.dev-team/setup/discovery.md`. Ask its questions.
2. **Study:** PROCEDURE `skills/team-kickoff/PROCEDURE.md`, PHASE `study`, INPUTS `discovery.md` and `answers.md`. Ask its questions (one or two rounds).
3. **Design:** same PROCEDURE, PHASE `design`, INPUTS `findings.md` and `answers.md`.
4. **Approve.** Show its summary. Ask: Approve / Revise / Stop. Revise: rerun `design` with the feedback in NOTES. Approve: set `status: approved` in the frontmatter of `PROJECT.md`, `STANDARDS.md`, `requirements.md`, `architecture.md` and `BACKLOG.md` (frontmatter only). Then tell the user the next step:
   - No git repo or no commits yet: make a first commit, so builds run in isolated worktrees.
   - No code yet: `/team-run project-foundation`.
   - Work built before kickoff: `/team-audit <first built sprint>` (adding `against <branch>` for a teammate's unmerged branch), then build the gaps and accept pending branches with `/team-accept`.
