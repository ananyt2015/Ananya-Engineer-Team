---
name: team-accept
description: Acceptance lead of the dev team. Has fresh agents review, verify and merge work the team did not build, such as a teammate's sprint branch or pull request, against the project's requirements and STANDARDS.md, then merges it into the target branch with the user's approval. Use only when the user invokes /team-accept.
disable-model-invocation: true
---

# /team-accept — Accept a teammate's work

Every phase runs in a fresh agent. This chat asks the user and holds the approvals: never read the procedure, the diff, the code, or the record's body here. You may read the record's frontmatter and count its open findings with `rg -c`.

## Usage
- `/team-accept <branch | PR URL or number> [into <target>]` — start, or resume if a record exists.
- `/team-accept recheck <slug>` — the author pushed fixes.
- `/team-accept merge <slug>` — go to the merge (needs an approved record).
- `/team-accept status` — one line per `.dev-team/accept/*.md`: source and target, status, `source_sha`, open findings (`rg -c 'Status:\*\* open'`), next command.

Gate: `.dev-team/PROJECT.md` and `.dev-team/STANDARDS.md` approved (frontmatter only). Record: `.dev-team/accept/<slug>.md`; answers: `.dev-team/accept/<slug>-answers.md`.

**Starting agents:** host subagent tool (Cursor: Task; Claude Code: Agent), no model, one at a time.
- Analyst: `subagent_type: team-analyst`; prompt PROCEDURE (absolute path of `skills/team-accept/PROCEDURE.md` under this host's folder), PHASE, ROOT, INPUTS, OUTPUT, NOTES. `PARTIAL`: rerun the phase with its NEXT in NOTES.
- Reviewers: `team-reviewer`, `team-security-reviewer`, `team-qa-tester` with `MODE: accept`, ROOT, INTEGRATION (worktree path and base), INPUTS (the record, the answers file, `.dev-team/context/rules-review.md` / `rules-security.md` / `rules-qa.md` and `context/project.md`, and `skills/team/PLAYWRIGHT.md` for UI), NOTES (`range: <base> <source_sha>`, `prefix: A`, screenshots `.dev-team/accept/<slug>/`). If `.dev-team/context/` is missing or stale, run `team-context-builder` first (as `/team-run` does).
- Fixes: the owner's engineer (WORKSPACE = the integration worktree, INPUTS the record, NOTES the finding ID and its Scope row), then `team-verifier` MODE fix (commit message `<slug>: fix A2`).
`NEEDS-INPUT` from any agent: ask its questions in one round with the host's question tool, append the answers to the answers file, rerun.

## Steps
1. **Locate:** PHASE `locate` (NOTES: source, target). Show its overview.
2. **Scope:** PHASE `scope`. Ask its questions (scope, derived criteria, unplanned changes).
3. **Verify:** reviewer, then security reviewer, then QA tester (QA also writes the Verdict). Tell the user one line per agent.
4. **Decide.** From the three reports' FINDINGS lines, show counts by severity. Ask: fix critical and major here, send the rest to the author (recommended) / send everything to the author / fix everything here / let me choose per finding (then list them). A missing scope item may also become a backlog feature. Save the answers, run PHASE `decisions`, then each "fix here" finding one at a time: engineer, then verifier. A fix that fails twice: mark it blocked and move on.
5. **Waiting on author:** show the feedback file's path (and offer to post it on the PR; post only if the user says yes). Tell the user to run `/team-accept recheck <slug>` after the author pushes.
6. **Recheck:** PHASE `recheck`, then `team-reviewer` with NOTES `range: <old>..<new>; also re-verify the findings sent to the author and update their Status`, then `team-qa-tester` to re-run the checks. Back to step 4 for anything still open.
7. **Approve.** Show the Verdict line and open findings by severity. Ask: Approve / Revise / Stop. Approving with open critical or major findings needs the user's explicit yes; note it in the answers file. Approve: set `status: approved` in the record's frontmatter.
8. **Merge.** Ask how, recommending the style in `context/project.md` or the delivery preference: merge commit / squash / rebase / open a pull request instead. Run PHASE `merge`. Show its summary and ask: update `<target>` and push / update my local `<target>` only / stop. Then PHASE `land`. Tell the user what landed and what's open, and propose the plan-doc edits it lists (apply only if approved).
