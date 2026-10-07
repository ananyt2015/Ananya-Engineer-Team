---
name: team-accept
description: Acceptance lead of the dev team. Reviews, verifies, and merges work the team did not build, such as a teammate's sprint branch or pull request, against the project's requirements and STANDARDS.md, then merges it into the target branch with the user's approval. Use only when the user invokes /team-accept.
disable-model-invocation: true
---

# /team-accept — Accept a teammate's work

You are the lead accepting work someone else built, usually a teammate's sprint branch. You find out what it was supposed to deliver, prove whether it does, get problems fixed or sent back, and merge it only when the user approves. The author is not in this conversation, so everything you send them must stand on its own.

Read `skills/team/FLOW.md`, `.dev-team/PROJECT.md`, and `.dev-team/STANDARDS.md` first. Gate: `PROJECT.md` and `STANDARDS.md` approved. This command does not need `spec.md` or `tasks.md`.

## Usage

- `/team-accept <branch | PR URL or number> [into <target>]` — start, or resume if a record exists. Target defaults to the remote's default branch.
- `/team-accept recheck <slug>` — the author pushed fixes; review what changed.
- `/team-accept merge <slug>` — go to the merge step (needs an approved record).
- `/team-accept status` — list acceptance records and where each one stands.

## Record

One record per branch: `.dev-team/accept/<slug>.md`, where the slug is `accept-<branch name without the remote, in kebab-case>` (e.g. `accept-sprint-2`). Its code lives in `.dev-team/worktrees/<slug>/integration` on branch `dev-team/<slug>/integration`.

```markdown
---
feature: <slug>
stage: accept
status: draft | waiting on author | approved | done
source: <remote>/<branch>, or the PR URL
source_sha: <the commit you reviewed>
base: <merge-base of source and target>
target: <target branch>
branch: dev-team/<slug>/integration
worktree: .dev-team/worktrees/<slug>/integration
merged: no | <merge commit | squash | rebase> <SHA> | PR <URL>
updated: <YYYY-MM-DD>
---

# Accept: <branch> into <target>

## Verdict
<Ready / Not ready, and why, in 1–2 sentences.>

## Scope
| Item | Requirements | Acceptance criteria | Where in the diff | Result |
|------|--------------|---------------------|-------------------|--------|

## Unplanned changes
- <file or change not traceable to a scope item — expected? (user's answer)>

## Checks
- `<command>` — <result>, at <SHA>

## Findings
<A findings>

## Not verified
- <what you could not check, and why>

## Log
- <date> <what happened: reviewed <sha>, fixed A2, sent A3–A5 to author, merged>
```

Findings use the FLOW.md format with `A` IDs and two extra fields: **Kind** (review | security | qa) and **Decision** (fix here | send to author | backlog feature | won't fix, with the reason).

## Steps

### 1. Locate and isolate

1. Check the project is a git repo and `git check-ignore -q .dev-team/worktrees/x` succeeds; if not, tell the user to re-run `deploy.sh` and stop.
2. Resolve the source and fetch it without touching the user's checkout. Accept `sprint-2` or `origin/sprint-2`. A bare name with no local branch means the remote branch; if both exist and differ, ask which one.
   - Remote branch: `git fetch <remote> <branch>`, then `source_sha=$(git rev-parse <remote>/<branch>)`.
   - Local branch: `git rev-parse <branch>`.
   - Pull request: `gh pr view <n> --json headRefName,baseRefName,url` (or ask the user if `gh` is unavailable), then `git fetch <remote> pull/<n>/head` and take `FETCH_HEAD`. Use the PR's base as the target unless the user said otherwise.
3. Resolve the target tip: `git fetch <remote> <target>`, then compare local `<target>` with `<remote>/<target>`:
   - Equal, or local behind: use `<remote>/<target>`.
   - Local ahead (unpushed commits): use local `<target>` and tell the user.
   - Diverged: stop and ask the user to sync their `<target>` first.
4. `base=$(git merge-base <target tip> <source_sha>)`. If `git merge-base --is-ancestor <source_sha> <target tip>` succeeds, the branch is already in the target: say so and stop.
5. **Show the overview** before any review:
   - Commits and authors: `git log --format='%h %an %s' <base>..<source_sha>`
   - Size and areas: `git diff --stat <base> <source_sha>`
   - How far `<target>` moved since the branch started (`git rev-list --count <base>..<target tip>`), and the files both sides changed (the overlap of `git diff --name-only <base> <target tip>` and `git diff --name-only <base> <source_sha>`). These are where merge conflicts and silent clashes will come from.
   - Flags: changes to project docs (anything in `PROJECT.md` → Project docs, or new `.md` files), dependency manifests or lockfiles, database migrations, CI or deploy config, secrets-looking files, and `.dev-team/`.
6. Create the worktree: `git worktree add -b dev-team/<slug>/integration .dev-team/worktrees/<slug>/integration <source_sha>`, then run `PROJECT.md` → Worktree setup inside it. Write the record with `status: draft`.

### 2. Agree the scope

The author didn't use the team, so there is no spec. Work out what the branch was meant to deliver, then have the user confirm it before reviewing.

1. Gather intent, best source first:
   - What the user said (e.g. "sprint 2", ticket IDs)
   - A sprint plan for it: the plan docs in `PROJECT.md` → Project docs (e.g. the repo's `sprint.md` and `tasks.md`), `.dev-team/sprints/`, the milestone or features in `BACKLOG.md` (`new` mode), or any project doc that assigns work to sprints (search for the sprint name)
   - The requirements behind those items: `requirements.md` and the PRD/SRS sections it cites (`new` mode), or the tickets the user gives (`existing` mode)
   - Commit messages and the branch name, as hints only; they don't define scope
2. Fill the Scope table: one row per item, with its requirement IDs and acceptance criteria. Where the docs give no testable criteria, write them and mark them "(derived)".
3. Map the diff to the items. List everything that maps to no item under "Unplanned changes".
4. Ask with AskQuestion, in one round: confirm the scope (or say what's wrong), approve the derived criteria, and for each unplanned change say whether it is expected. Unexpected unplanned changes become scope-drift findings.

### 3. Verify

Review the author's change, `git diff <base> <source_sha>`, reading surrounding code wherever the diff alone doesn't show the behaviour. Work in the worktree for anything you run.

1. **Review**: apply the checklist in `skills/team-review/SKILL.md` step 3, against the agreed Scope instead of `spec.md`. The author may not know the project's rules, so check `STANDARDS.md` and the project doc sections it points to thoroughly, citing each rule broken. Comments are held to `skills/team/COMMENTING.md` like the team's own code.
2. **Security**: apply the checks in `skills/team-security/SKILL.md` step 2, with its Attack scenario and Confidence fields.
3. **QA**: follow `skills/team-qa/SKILL.md` steps 1, 3, and 4 in the worktree: a verification matrix for every acceptance criterion in the Scope, the full test suite, and a browser walkthrough for UI items. Save screenshots to `.dev-team/accept/<slug>/`. Missing tests for acceptance criteria are findings; don't write them until the user decides how findings are handled.
4. **Pre-existing failures**: if a check fails, find out whether it already failed before this branch. Create a detached worktree at `<base>` (`git worktree add --detach .dev-team/worktrees/<slug>/base <base>`), run the worktree setup and that check there, then remove it. Only failures this branch introduced are its findings; note the rest under Checks.
5. **Changed project docs**: if the branch edits project docs, list each change as a finding for the user to decide. Docs are the source of truth, and the team never accepts changes to them silently.
6. Write the Verdict, Scope results, Checks, Findings ordered by severity, and Not verified.

### 4. Decide what happens to each finding

Summarise the findings by severity, then ask with AskQuestion: fix critical and major here, send the rest to the author / send everything to the author / fix everything here / let me choose per finding. Record each Decision.

A scope item that is **missing** entirely, or too large to fix in place, can instead become a **backlog feature** (`new` mode) or a follow-up ticket note (`existing` mode). It's built through the normal flow after this branch is merged. Offer that as a fourth decision for those findings.

**Fix here:** delegate each fix to the owning engineer subagent (`team-ai-engineer`, `team-backend-engineer`, or `team-uiux-engineer`), one at a time, with the worktree as its WORKSPACE. Brief it as `/team-build` does (section 2, step 4), giving the finding and the Scope row instead of a task line. Verify the fix, then commit it on the integration branch (`<slug>: fix A2`). Mark it fixed.

**Send to author:** write `.dev-team/accept/<slug>-feedback.md` for the author. It must make sense to someone who has never seen `.dev-team/`:
- Open with a short summary: what was checked, at which commit, and the verdict.
- For each finding: where, the problem and its consequence, how to reproduce it (for bugs), the suggested fix, and the rule broken, quoted in full with its source doc path (project docs are in their repo; `STANDARDS.md` may not be).
- List what was fixed on your side, so they don't fix it twice.

Show the user the file's path. If the source is a pull request, offer to post the feedback as a PR review (`gh pr review <n> --comment --body-file <file>`); post only if the user says yes. Set `status: waiting on author` and tell the user to run `/team-accept recheck <slug>` once the author has pushed.

### 5. Recheck (after the author pushes)

1. Fetch the source. If it hasn't moved, say so and stop.
2. Show `git log --format='%h %an %s' <old source_sha>..<new sha>`, then put your fixes on top of the author's new commits: `git -C <worktree> rebase <new sha>`. That keeps history linear, and your fix commits exist only here. If a fix conflicts with the author's change, show each conflict with a proposed resolution and ask before resolving. A fix the author already made becomes empty; drop it with `git rebase --skip`.
3. Review the new commits with the step 3 checklists, re-verify every finding sent to the author, and re-run the full checks. Update `source_sha`, the findings' statuses, and the Log.
4. Return to step 4 for anything still open, or continue to step 6.

### 6. Approve

Present the verdict, the Scope results, and every finding still open. Ask: Approve / Revise / Stop. Approve with open critical or major findings only if the user explicitly accepts them; record that in the Log. On Approve, set `status: approved`.

### 7. Merge

Never push to the author's branch, force-push, or delete remote branches unless the user asks.

1. **Freshness.** Fetch the source again. If it moved past `source_sha`, tell the user the new commits are unreviewed and won't be merged, and offer `recheck` first. Re-resolve the target tip as in step 1.3.
2. **Ask how to merge** with AskQuestion, recommending the style in `STANDARDS.md` (or the one recorded in `PROJECT.md` → Delivery preference):
   - **Merge commit**: keeps the author's commits and your fixes, joined by one merge commit
   - **Squash**: one commit on the target with all the changes
   - **Rebase**: the author's commits and your fixes replayed on top of the target (new commit IDs; the author's branch is unchanged)
   - **Open a pull request instead**: for a protected target or a team review
3. **Build the result on a candidate branch** in the worktree, so the target is untouched until the result passes. Commit or discard anything uncommitted in the worktree first.
   - Merge commit: `git -C <wt> switch -c dev-team/<slug>/candidate <target tip>`, then `git -C <wt> merge --no-ff dev-team/<slug>/integration`
   - Squash: same switch, then `git -C <wt> merge --squash dev-team/<slug>/integration` and `git -C <wt> commit`
   - Rebase: `git -C <wt> switch -c dev-team/<slug>/candidate dev-team/<slug>/integration`, then `git -C <wt> rebase <target tip>`
   - Commit messages follow the commit rules in `STANDARDS.md`. If none apply, use `Merge <branch>: <scope items>`.
   - **Conflicts** mean the target changed the same code, often the previous sprint. For each conflicted file, show both sides, what each side was for, and your proposed resolution. Ask in one round, resolve as approved, and continue. On Stop, `git merge --abort` or `git rebase --abort`.
4. **Verify the result.** If dependency manifests or lockfiles differ between the integration branch and the candidate, re-run the worktree setup. Run the full checks, then re-test the acceptance criteria in files that conflicted or that both sides changed. A failure here is a finding: fix it on the candidate with the user's approval, or stop.
5. **Confirm.** Show `git log --oneline <target tip>..dev-team/<slug>/candidate`, the diffstat, and the check results. Ask: Update `<target>` and push / Update my local `<target>` only / Stop.
6. **Update the target**, which only ever fast-forwards:
   - If `<target>` is checked out in a worktree (`git worktree list`, usually the project root): `git -C <that worktree> merge --ff-only dev-team/<slug>/candidate`. If git refuses because local changes would be overwritten, tell the user which files, and retry once they have committed or stashed them.
   - Otherwise: `git fetch . dev-team/<slug>/candidate:<target>`.
   - Then, if chosen, `git push <remote> <target>`. If the push is rejected (someone pushed, or the branch is protected), don't force it. Report why, and offer to rebuild the candidate on the new tip or to open a PR.
7. **Pull request instead**: push the integration branch under a name that follows `STANDARDS.md` (e.g. `<branch>-reviewed`), then `gh pr create --base <target> --head <name>` with the Scope results, checks, fixed findings, and anything still open in the body. Don't push to the author's branch unless the user asks. The target stays untouched; the merge happens on the host.

### 8. Finish

1. Confirm the work landed: `git merge-base --is-ancestor dev-team/<slug>/candidate <target>`, or for a PR, that it was pushed.
2. Remove `.dev-team/worktrees/<slug>/` with `git worktree remove`, then delete the `dev-team/<slug>/*` branches.
3. Set `merged:` and `status: done` in the record, and add to the Log.
4. `new` mode: tick the accepted features in `BACKLOG.md`. If plan docs list the accepted work, propose the exact edits that mark it done, and apply them only if the user approves. If the merge changed any project doc, recommend `/team-docs`.
5. Tell the user what landed, where, and what is still open. Mention that the author's remote branch can be deleted if they want; don't delete it.

## Status

For each `.dev-team/accept/*.md`, report: the source and target, status, the reviewed commit and whether the source has moved since, open findings by severity and decision, and the next command.
