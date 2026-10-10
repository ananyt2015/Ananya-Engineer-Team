---
name: team-docs
description: Project docs lead of the dev team. Scans docs/ and every other .md file in the repo, classifies each one, tracks which are shared with the product's other repos and which are specific to this repo, checks synced copies for drift, and adjusts STANDARDS.md, the requirement index, the backlog, and the plan to match. Each phase runs in a fresh agent. Use only when the user invokes /team-docs.
disable-model-invocation: true
---

# /team-docs — Project docs

Every phase runs in a fresh `team-analyst` agent. This chat only asks the user and holds the approval: never read the procedure, the docs, or the analyst's outputs here.

- `/team-docs` — scan, show what changed, and adjust the team's artifacts with the user's approval.
- `/team-docs status` — scan and report only; change nothing.

**Starting an analyst:** host subagent tool (Cursor: Task; Claude Code: Agent), `subagent_type: team-analyst`, no model. Prompt: PROCEDURE (absolute path of `skills/team-docs/PROCEDURE.md` under this host's folder), PHASE, ROOT, INPUTS, OUTPUT, NOTES. A `PARTIAL` report: start a fresh analyst for the same phase with its NEXT in NOTES. `NEEDS-INPUT`: ask its questions in one round with the host's question tool, append the answers to `.dev-team/setup/answers.md`, and pass that file on.

## Steps
1. **Gate.** If `.dev-team/PROJECT.md` doesn't exist, run phase `discover`, show its summary, and tell the user to run `/team-kickoff` (new) or `/team-onboard` (existing). Stop.
2. **Scan:** phase `scan` (NOTES `status` for `/team-docs status`). Nothing changed, or `status`: show the summary and stop.
3. Ask its questions.
4. **Propose:** phase `propose`, INPUTS `.dev-team/setup/docs-scan.md` and the answers file.
5. **Approve.** Show its summary. Ask: Approve / Revise / Stop, and separately which proposed plan-doc edits to apply. Revise: rerun `propose` with the feedback in NOTES.
6. **Apply:** phase `apply`, INPUTS `.dev-team/setup/docs-proposal.md`, NOTES the approval and approved plan-doc edits. Tell the user the next `/team-run` rebuilds the team's context automatically.
