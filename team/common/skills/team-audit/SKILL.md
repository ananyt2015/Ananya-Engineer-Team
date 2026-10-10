---
name: team-audit
description: Audit lead of the dev team. Has fresh agents validate work that is already on a branch, such as a sprint built before the team was deployed, against the plan, requirements and STANDARDS.md; reports what is done, partial, missing, or off-standard, checks whether a pending branch already touches each gap, and turns the gaps into backlog features. Use only when the user invokes /team-audit.
disable-model-invocation: true
---

# /team-audit — Validate existing work

Every phase runs in a fresh agent. This chat asks the user and holds the decisions: never read the procedure, the code, or the record's body here.

## Usage
- `/team-audit <sprint name | feature slugs | all> [on <ref>] [against <branch>…]` — `on`: what to audit (default the committed `HEAD` of the user's branch); `against`: pending work not merged yet, such as a teammate's next sprint.
- `/team-audit status` — one line per `.dev-team/audit/*.md`: scope, audited `sha`, status, open findings (`rg -c 'Status:\*\* open'`), and whether `<name>-gaps` is delivered.

Gate: `.dev-team/PROJECT.md` and `.dev-team/STANDARDS.md` approved (frontmatter only). Record: `.dev-team/audit/<name>.md`; answers: `.dev-team/audit/<name>-answers.md`.

**Starting agents:** host subagent tool (Cursor: Task; Claude Code: Agent), no model, one at a time.
- Analyst: `subagent_type: team-analyst`; prompt PROCEDURE (absolute path of `skills/team-audit/PROCEDURE.md` under this host's folder), PHASE, ROOT, INPUTS, OUTPUT, NOTES. `PARTIAL`: rerun the phase with its NEXT in NOTES.
- Reviewers: `team-reviewer`, `team-security-reviewer`, `team-qa-tester` with `MODE: audit`, ROOT, INTEGRATION (the audit worktree), INPUTS (the record, `.dev-team/context/rules-review.md` / `rules-security.md` / `rules-qa.md` and `context/project.md`, and `skills/team/PLAYWRIGHT.md` for UI), NOTES (`prefix: G`, screenshots `.dev-team/audit/<name>/`). If `.dev-team/context/` is missing or stale, run `team-context-builder` first.
`NEEDS-INPUT`: ask its questions in one round with the host's question tool, append the answers to the answers file, rerun.

## Steps
1. **Scope:** PHASE `scope` (NOTES: the scope, `on`, `against`). Ask its questions.
2. **Trace:** PHASE `trace`.
3. **Verify:** reviewer, then security reviewer, then QA tester (QA confirms the items that look done and writes the Verdict). One line to the user per agent.
4. **Decide.** From the reports, show items by status and gaps by severity, and which gaps a pending branch affects. Ask, recommending: **gap feature** `<name>-gaps` (for gaps the next sprint builds on, and critical and major defects) / **backlog later** / **already addressed by `<branch>`** / **won't fix** (with a reason). Per finding if the user wants. Save the answers.
5. **Hand off:** PHASE `handoff`. Show its summary: the next step (`/team-run <name>-gaps`) and the plan-doc edits it proposes (apply only if the user approves).
