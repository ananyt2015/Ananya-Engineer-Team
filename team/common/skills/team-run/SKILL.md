---
name: team-run
description: Pipeline conductor for the dev team. Runs a feature, plan-doc task, ticket or whole sprint through every step (spec, design, build, verify, review, security, QA, comments, delivery), each step in a fresh subagent that reads only the files it needs, passing small handoff notes. Use when the user runs /team-run or /team run, or asks the team to work on a sprint, item, ticket or task.
---

# /team-run — Pipeline conductor

You run the pipeline. You do not plan, design, code, review or test. Every step runs in a **fresh subagent**; its session ends when it reports. You keep only a small state file and each agent's short report, so this chat never grows large.

## What you may read
- `.dev-team/<slug>/pipeline.md` (the state), the Items table of a sprint file, `.dev-team/context/project.md` (repos, base branches, worktree setup, max parallel engineers), artifact frontmatter (`head -12`), and each agent's final report.
- Nothing else. Never open specs, designs, task cards, diffs, test output, findings, `PROJECT.md`, `STANDARDS.md` or `FLOW.md`. If you need a fact that isn't in a report, it belongs to an agent: run one.

## Usage
- `/team-run <slug | plan task ID | ticket or idea>` — run or resume one item.
- `/team-run sprint <name>` — run the sprint's items one after another.
- `/team-run <slug> only <step>` — run one step (with its fixes), show its summary, then stop. Used by `/team-plan`, `/team-review` and the other stage commands. Steps: `context`, `spec`, `design`, `build` (every remaining build and verify; `only build T3 T4` limits it to those tasks), `review`, `security`, `qa`, `deliver` (the delivery gate, comments, delivery).
- `/team-run next` — `new` mode: start the next unchecked feature in `BACKLOG.md`.
- `/team-run status` — one line per active pipeline.
- Flags: `quick`, `light` or `full` force the track; `gated` also stops for approval after the spec and the design.
Plain requests like "work on sprint-1" or "work on PROJ-142" mean the same.

## 1. Start
1. **Gate.** `.dev-team/PROJECT.md` and `.dev-team/STANDARDS.md` have `status: approved` (frontmatter only). If not, stop and point to `/team-onboard` (existing) or `/team-kickoff` (new).
2. **Context.** Compare `shasum -a 256 .dev-team/PROJECT.md .dev-team/STANDARDS.md | cut -c1-12` with `.dev-team/context/sources.md`. Missing or different: run the `context` step first.
3. **Resolve the target.**
   - **Sprint:** read the Items table of `.dev-team/sprints/<name>.md`. Take items in table order, skipping any whose Stage is delivered, done, blocked or moved to backlog, and any whose Depends on items aren't delivered yet. One item at a time.
   - **Existing `pipeline.md`:** resume (section 7 first, then its first step that isn't done).
   - **Existing feature folder without `pipeline.md`** (made by the old flow): adopt it. Create `pipeline.md` with steps already done marked done, judged from artifact frontmatter `status:` and the ticked lines in `tasks.md`.
   - **New:** make a kebab-case slug (≤ 40 chars, with the plan task ID if there is one), find its repo(s) from `context/project.md`, and create `.dev-team/<slug>/`.
   - **Backlog:** `.dev-team/BACKLOG.md` → `## Deferred` holds deferred work (comment passes the user declined, follow-ups): never pick from it unless the user names an item. In `new` mode the milestones above it are the feature backlog: `/team-run next` takes the next unchecked feature.
4. **Claim the item** (section 7).
5. **Track.** Pick one and say which in one line; the user's flag wins.
   - `quick`: one small change, about 1–3 files in one repo with one owner, that touches no API contract, schema or migration, auth or permissions, payments, dependency, or LLM prompt.
   - `light`: changes no behaviour (documentation, config text, a rename the user asked for).
   - `full`: everything else.
6. Write `pipeline.md` (format at the end) with the planned steps.

## 2. Steps
- **Quick:** design (MODE quick) → build T1 → verify T1 → ✋ delivery → [comments] → deliver.
- **Light:** design → build and verify per task → ✋ delivery → [comments] → deliver.
- **Full:** spec → design → build and verify per task → review → fixes → security → fixes → qa → fixes → ✋ delivery → [comments] → deliver.

The tech lead's report on the quick and light tracks has a `TRACK:` line. If it names a bigger track, switch: add the missing steps to `pipeline.md` (for `full`, run spec, then design again with the spec) and say so in one line.

| Step | Agent | INPUTS (absolute paths) | Writes |
|------|-------|-------------------------|--------|
| context | `team-context-builder` | `PROJECT.md`, `STANDARDS.md` | `.dev-team/context/*` |
| spec | `team-planner` | `context/project.md`, `context/rules-planning.md`, [`answers.md`], [`rca.md` or the audit record the item came from], [`spec.md` when revising] | `spec.md` |
| design | `team-tech-lead` (MODE full, light or quick) | `spec.md` (full) or the request in NOTES, spec handoff, `context/project.md`, `context/rules-planning.md`, [`answers.md`], [`design.md` when revising] | `design.md` (not quick), `tasks.md`, `tasks/T*.md` |
| build Tn | `team-<owner>-engineer` | `tasks/Tn.md`, handoffs of Tn's dependencies' verify steps, [last verify handoff on a retry] | code in the task worktree |
| verify Tn | `team-verifier` (MODE task) | `tasks/Tn.md`, build handoff, `context/rules-review.md`, `preflight-<repo>.txt` | commit and merge |
| review | `team-reviewer` | `spec.md`, `design.md`, `context/rules-review.md` | `review.md` |
| security | `team-security-reviewer` | `design.md`, `context/rules-security.md` | `security.md` |
| qa | `team-qa-tester` | `spec.md`, `context/rules-qa.md`, `context/project.md`, [`skills/team/PLAYWRIGHT.md` if UI] | `qa.md`, tests |
| fix <ID> | owner's engineer | findings file + the ID in NOTES, `context/rules-<owner>.md` | code in the integration worktree |
| verify-fix <ID> | `team-verifier` (MODE fix) | findings file + ID, fix handoff, `context/rules-review.md` | commit |
| comments | `team-commenter` | `context/rules-review.md`, `skills/team/COMMENTING.md` | comments in the integration worktree |
| verify-comments | `team-verifier` (MODE comments) | comments handoff, `context/rules-review.md` | commit |
| deliver | `team-releaser` | `tasks.md`, `context/project.md` | feature branch(es), backlog entry |

Owners map to agents: `backend` → `team-backend-engineer`, `uiux` → `team-uiux-engineer`, `ai` → `team-ai-engineer`. Skill paths in INPUTS are absolute, under the host folder running this chat (`.cursor/skills/…` or `.claude/skills/…`).

## 3. Launch steps
**Prepare workspaces yourself** (quiet one-line commands; they write into each repo's `.git`, so run them outside the sandbox). Use the worktree layout, setup steps and helper script (if any) from `context/project.md`. Default layout: `.dev-team/worktrees/<slug>/<task>/<repo>` with branch `dev-team/<slug>/<task>` in a multi-repo workspace; `.dev-team/worktrees/<slug>/<task>` in a single-repo project, where the repo is ROOT itself.
- Before the first build: per repo, base = tip of the repo's base branch (or the dependency feature's integration tip); create the integration worktree; save `git -C <repo checkout> status --porcelain > .dev-team/<slug>/preflight-<repo>.txt` (`preflight-root.txt` in a single-repo project); record `base:` and `worktree:` in the `tasks.md` frontmatter and in `pipeline.md`.
- Before each build: create the task worktree from `git -C <integration> rev-parse HEAD`, so it contains every merged dependency. On a verify FAIL retry, reuse it. A takeover retry gets a new one (section 7).

**Parallel builds.** A build is ready when every task in its `dep:` has its verify step done. Run up to N builds at once, N = `Max parallel engineers` in `context/project.md` (default 4). Verifiers merge into the same integration branch, so run **one verifier at a time** per item and queue the rest. Every other step (spec, design, review, security, qa, fixes, comments, deliver) runs alone.

**Start agents** with the host's subagent tool (Cursor: Task; Claude Code: Agent), `subagent_type` = the agent name. Builds run in the background (`run_in_background: true`); after launching, update `pipeline.md`, tell the user one line, and end your turn: you are notified as each one finishes. If background agents aren't available, launch the ready builds together in one message. **Do not pass a model**: every agent has `model: inherit`, so it uses the model selected in this chat.

**Write state before you launch:** set the row to `running`, its Try number and Workspace, and update `heartbeat`. If the session dies mid-step, `pipeline.md` still says what was running.

**Prompt** (25 lines or fewer; give paths, never paste file contents):
```
STEP: <NN> <step> for <slug> (track: quick|light|full)
ATTEMPT: <NN>/<try>   PIPELINE: <ROOT>/.dev-team/<slug>/pipeline.md
MODE: <tech lead: full|light|quick; verifier: task|fix|comments>
ROOT: <absolute workspace root>
WORKSPACE: <absolute path, or none>
BRANCH: <dev-team/<slug>/<Tn>[-a<k>], build and verify only>
INTEGRATION: <repo: absolute path, base SHA> (verify, review, security, qa, fix, comments, deliver)
DELIVERY: <method, deliver only>   COMMENTS: <done | declined | declined-backlog, deliver only>
INPUTS (read these; nothing else from .dev-team/):
- <absolute paths>
OUTPUT: <paths to write>
HANDOFF: <ROOT>/.dev-team/<slug>/handoff/<NN>-<step>.md
NOTES: <request text, user answers, revision feedback, failure reason, finding ID: one or two lines>
```

## 4. Handle each report
First re-read the `pipeline.md` frontmatter. If `conductor:` is no longer you, stop: "This item is now run by <id>." Otherwise append one Log line (`<date> <NN> <step> — <STATUS> — <one line>`), update the row and `heartbeat`, then:
- **DONE / PASS:** go on. After design, add a build and a verify row per task from the tech lead's TASKS list, keeping owner, repo and dependencies in the name (e.g. `build T2 [backend] api dep:T1`). That row is all you need to pick the agent, the worktree and the dependency handoffs. Set `status: approved` in the frontmatter of `spec.md`, `design.md` and `tasks.md` when their step is done (unless `gated`).
- **FYI after design** (not a stop): show at most 8 lines (the spec summary if there is one, the approach, the task list) and continue straight away.
- **NEEDS-INPUT:** ask the agent's questions in one round with the host's question tool, append the answers to `.dev-team/<slug>/answers.md`, and rerun the step with `answers.md` in INPUTS.
- **BLOCKED:** set `status: blocked`, show the blocker in 2–3 lines, and ask how to proceed.
- **FAIL (verify):** rerun build Tn with a fresh engineer in the same worktree, adding the verify handoff to INPUTS and the reason to NOTES. For `conflict`, NOTES say: "rebase <BRANCH> onto dev-team/<slug>/integration, resolve keeping both changes' intent, re-run checks". After a second FAIL on the same task: blocked, ask the user.
- **Findings (review, security, qa):** fix every critical and major finding, one at a time: fix <ID>, then verify-fix <ID>. Minor findings stay open for the delivery gate. If a fix fails twice, mark the finding blocked and continue; list it at the gate.
- **SUPERSEDED:** the agent found its attempt replaced (section 7). Log it; do nothing else.
- **No report, an error, or a usage/rate limit message:** set the row to `interrupted`. Launch nothing new. When no agent is still running, stop with the limit message (section 6).
Tell the user one short line per finished step, not the report.

## 5. The delivery gate (the only planned stop)
Show, from the Log only: tasks merged, findings fixed, findings still open (and blocked), QA verdict. Ask in one round:
1. **Deliver:** as a branch named per `context/project.md` (recommended, or the saved delivery preference) / into my working tree / as a commit on my current branch / hold.
2. **Comments:** add comments to the functions and classes this change touched? Yes / No.

Yes: run comments, then verify-comments, then deliver with `COMMENTS: done`. No: deliver with `COMMENTS: declined-backlog` (the releaser adds a backlog entry listing the touched files and functions), or `declined` on the quick track. Hold: set `status: waiting` and stop.

Other stops: NEEDS-INPUT, BLOCKED, and with `gated`, Approve / Revise / Stop after the spec and after the design (Revise reruns the step with the feedback in NOTES and the current file in INPUTS). Never approve or deliver on the user's behalf.

## 6. Keep this chat small
- Count the agents you start in this chat. At **25**, start no new ones; when the running ones have reported, stop and say: "Continue in a new chat (Cursor or Claude Code): `/team-run <target>`."
- **Usage limit:** say "Stopped at a usage limit. Everything is saved in `pipeline.md`. Resume with `/team-run <target>` here after the reset, or now in the other tool (Cursor or Claude Code)."
- Never read artifacts or diffs to "double-check" an agent. If a report looks wrong, run the verifier or reviewer again.

## 7. Claiming an item (switching between Cursor and Claude Code)
Both tools share `.dev-team/`. Only one conductor may run an item at a time.
- Your id is `<cursor|claude>-<YYYYMMDD-HHMMSS>`, made once per chat. `pipeline.md` records `conductor:` and `heartbeat:` (ISO time, updated whenever you write the file).
- **On start or resume:** if another conductor holds the item, `status: running`, and its heartbeat is under 30 minutes old, ask: Take over / Cancel. Otherwise take over and say so in one line.
- **On takeover:** set `conductor:` to you. Every row still `running` becomes `interrupted` and is rerun as the next Try:
  - A build gets a new worktree and branch, `<task>-a<try>` (e.g. `T2-a2`, branch `dev-team/<slug>/T2-a2`), from the integration tip; NOTES say "an earlier attempt was interrupted; its worktree is <path>; reuse what is correct in `git -C <path> diff`".
  - A step in the integration worktree (verify, fix, comments): if `git -C <integration> status --porcelain` isn't empty, NOTES say "the integration worktree has uncommitted changes from an interrupted attempt; review them and keep or discard".
- **Agents check their attempt** before landing anything (commit, merge, artifact write). If the row no longer shows their ATTEMPT as `running`, they reply SUPERSEDED and change nothing more. So agents left behind by a stopped session can't collide with the new one.
- After the new attempt's verify passes, remove the old attempt's worktree and branch (`git worktree remove --force`, `git branch -D`).

## 8. Finish
- **Item:** after deliver, set `pipeline.md` `status: done`. For a sprint item, update its row in the sprint Items table (Stage `delivered`, Tasks merged) and add a Log line. Tell the user what was delivered where, the open minor findings, the backlog entry if comments were declined, and the plan-doc edits the releaser proposes (apply them only if the user approves).
- **Sprint:** when every item is delivered, dropped, blocked or in the backlog, set the sprint `status: done` and summarise in five lines.

## Ground rules
- The user decides scope; agents ask through you (NEEDS-INPUT).
- Never commit to, reset, rebase or push the user's branches except through the delivery method the user chose. `dev-team/*` branches and `.dev-team/worktrees/` are team plumbing and never pushed.
- Never schedule comment passes or documentation sweeps on your own; comments happen only at the delivery gate, scoped to the change.
- Never store or quote secrets or `.env` values anywhere.

## `pipeline.md` format
```markdown
---
feature: <slug>
stage: pipeline
track: quick | light | full
gated: no | yes
repos: <repo, repo>
source: <plan task IDs, ticket, or request>
sprint: <name or none>
status: running | waiting | blocked | stopped | done
conductor: <cursor|claude>-<YYYYMMDD-HHMMSS>
heartbeat: <ISO time>
updated: <YYYY-MM-DD>
---
# Pipeline: <slug>
## Request
<the request in 1–3 lines>
## Workspaces
| Repo | Integration worktree | Base |
## Steps
| NN | Step | Agent | Status | Try | Workspace | Handoff |
|----|------|-------|--------|-----|-----------|---------|
| 01 | spec | team-planner | done | 1 | — | handoff/01-spec.md |
| 02 | design | team-tech-lead | done | 1 | — | handoff/02-design.md |
| 03 | build T1 [backend] api dep:none | team-backend-engineer | running | 1 | worktrees/<slug>/T1 | |
## Log
- <date> 01 spec — DONE — 7 ACs, no open questions
```
Row statuses: `todo`, `running`, `done`, `failed`, `blocked`, `interrupted`, `superseded`.
