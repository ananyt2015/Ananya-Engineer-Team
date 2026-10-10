---
name: team-rca
description: Root Cause Analyst of the dev team. A fresh agent investigates a bug, incident, or regression (reproduces it, narrows it down, proves its root cause with evidence), writes .dev-team/<slug>/rca.md with fix options and preventive actions, and the fix goes to /team-run. Use only when the user invokes /team-rca.
disable-model-invocation: true
---

# /team-rca — Root Cause Analyst

The investigation runs in fresh `team-analyst` agents. This chat takes the report, asks the user, and holds the approval: never read the procedure, the code, logs beyond what the user pasted, or `rca.md` here.

## Usage
- `/team-rca <symptom, error, stack trace, ticket key, or URL> [on <ref>] [good <ref>]` — `on`: where the bug is seen (default the committed `HEAD` of the user's branch); `good`: where it last worked, if known (enables bisecting).
- `/team-rca <slug>` — resume or revise an investigation.
- `/team-rca status` — one line per `.dev-team/*/rca.md`: frontmatter status and the `**Confidence:**` line (`rg -n`).

Gate: `.dev-team/PROJECT.md` and `.dev-team/STANDARDS.md` approved (frontmatter only).

**Starting an analyst:** host subagent tool (Cursor: Task; Claude Code: Agent), `subagent_type: team-analyst`, no model. Prompt: PROCEDURE (absolute path of `skills/team-rca/PROCEDURE.md` under this host's folder), PHASE, ROOT, INPUTS, OUTPUT, NOTES (slug, `on`, `good`, mode, answers). `PARTIAL`: start a fresh analyst for the same phase with its NEXT in NOTES.

## Steps
1. **Take the report.** Slug: kebab-case, at most 40 characters, ticket key plus a short name (e.g. `proj-207-export-timeout`). If `.dev-team/<slug>/rca.md` exists, offer to resume or revise it. If the input is a ticket key or URL, fetch it if a tool is available, otherwise ask the user to paste it. Ask only what's missing, in one round of up to 5 questions: what happens vs what should, the exact error or logs, where (environment, version, commit), since when and how often, who is affected, the last version that worked, and whether users are affected right now. Save the report and answers, with secrets redacted, to `.dev-team/<slug>/rca/report.md`.
2. **Live incident:** run PHASE `mitigate` first and show its options for the user to apply. The team never deploys, rolls back or changes environments.
3. **Investigate:** PHASE `investigate`, INPUTS `rca/report.md`. NEEDS-INPUT (e.g. can't reproduce): ask, append the answers to `report.md`, rerun.
4. **Approve.** Show its summary. Ask in one round: which fix option, the Decision for each preventive action, and Approve / Revise / Stop. Revise: rerun `investigate` with the feedback in NOTES. Approve: PHASE `finalize` with the decisions (and, in `new` mode, where to place it in the backlog) in NOTES.
5. **Next step:** `/team-run <slug>`; its spec step reads `rca.md`.
