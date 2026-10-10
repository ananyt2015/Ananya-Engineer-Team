---
name: team-onboard
description: Onboarding for an existing, running project. Asks which project docs are available (possibly none), has fresh agents study the codebase, conventions and process and verify the dev commands, and writes the project profile and rulebook to .dev-team/ so the team adapts to the project as it is. Use only when the user invokes /team-onboard or /team runs project setup in existing mode.
disable-model-invocation: true
---

# /team-onboard — Join an existing project

The work runs in fresh `team-analyst` agents, one per phase. This chat only asks the user and holds the approval: never read the procedures, the code, the docs, or the drafts here.

Arguments: none for a full onboarding; `refresh` to re-sync after docs or conventions change.

**Starting an analyst:** host subagent tool (Cursor: Task; Claude Code: Agent), `subagent_type: team-analyst`, no model. Prompt: PROCEDURE (absolute path under this host's folder), PHASE, ROOT, INPUTS, OUTPUT, NOTES (`mode: existing` plus anything below). `PARTIAL`: start a fresh analyst for the same phase with its NEXT in NOTES. `NEEDS-INPUT`: ask its questions in one round with the host's question tool, append the answers to `.dev-team/setup/answers.md`.

## Steps
1. **Discover docs:** PROCEDURE `skills/team-docs/PROCEDURE.md`, PHASE `discover`, OUTPUT `.dev-team/setup/discovery.md`. Ask its questions. If the user pastes doc content, save it as `.dev-team/docs/<short-name>.md` and add the path to the answers.
2. **Study:** PROCEDURE `skills/team-onboard/PROCEDURE.md`, PHASE `study`, INPUTS `discovery.md` and `answers.md`. It writes the drafts and `findings.md`. Ask its questions.
3. **Finalize:** same PROCEDURE, PHASE `finalize`, INPUTS `findings.md` and `answers.md`.
4. **Approve.** Show its summary. Ask: Approve / Revise / Stop. Revise: rerun `finalize` with the feedback in NOTES. Approve: set `status: approved` in the frontmatter of `.dev-team/PROJECT.md` and `.dev-team/STANDARDS.md` (frontmatter only), then tell the user to start work with `/team-run <ticket or description>`; the first run builds `.dev-team/context/` from these two documents.

## Refresh (`/team-onboard refresh`)
Follow `skills/team-docs/SKILL.md` (the same as `/team-docs`), adding to the scan questions whether there are new docs from outside the repo. If conventions moved on without a doc changing, run PHASE `refresh-conventions` with the areas in NOTES, then approve as in step 4.
