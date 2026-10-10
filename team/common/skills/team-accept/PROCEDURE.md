# /team-accept procedure

Read by `team-analyst`, one phase at a time. Review, security and QA are done by the `team-reviewer`, `team-security-reviewer` and `team-qa-tester` agents in MODE `accept`; fixes by an engineer and `team-verifier` (MODE fix).

## Common

You accept work someone else built, usually a teammate's sprint branch. You find out what it was meant to deliver, prove whether it does, get problems fixed or sent back, and merge it only when the user approves. The author is not in this conversation, so everything you send them must stand on its own. Read FLOW.md → "Ground rules" when a phase touches git or secrets.

Never push to the author's branch, force-push, or delete remote branches unless the user asks.

**Record:** `.dev-team/accept/<slug>.md`, slug `accept-<branch name without the remote, kebab-case>` (e.g. `accept-sprint-2`). Code in `.dev-team/worktrees/<slug>/integration` on branch `dev-team/<slug>/integration`. User answers in `.dev-team/accept/<slug>-answers.md`. Screenshots in `.dev-team/accept/<slug>/`.

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

## Overview
<commits and authors (count), size and areas, how far the target moved, files both sides changed, flags>

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
<A findings: FLOW.md findings format with A IDs, plus **Kind** (review | security | qa) and **Decision** (fix here | send to author | backlog feature | won't fix, with the reason)>

## Not verified
- <what you could not check, and why>

## Log
- <date> <what happened: reviewed <sha>, fixed A2, sent A3–A5 to author, merged>
```

## Phase: locate

NOTES: the source (branch, PR URL or number) and target. OUTPUT: the record with `status: draft`, the worktree.
1. The project is a git repo and `git check-ignore -q .dev-team/worktrees/x` succeeds; if not, BLOCKED: re-run `deploy.sh`.
2. Resolve the source without touching the user's checkout. `sprint-2` or `origin/sprint-2`; a bare name with no local branch means the remote branch; if both exist and differ, NEEDS-INPUT asking which.
   - Remote branch: `git fetch <remote> <branch>`, `source_sha=$(git rev-parse <remote>/<branch>)`.
   - Local branch: `git rev-parse <branch>`.
   - Pull request: `gh pr view <n> --json headRefName,baseRefName,url` (or NEEDS-INPUT if `gh` is unavailable), `git fetch <remote> pull/<n>/head`, take `FETCH_HEAD`. The PR's base is the target unless NOTES say otherwise. Target default: the remote's default branch.
3. Target tip: `git fetch <remote> <target>`, compare local `<target>` with `<remote>/<target>`. Equal or local behind: use `<remote>/<target>`. Local ahead: use local `<target>` and say so. Diverged: BLOCKED, ask the user to sync their target.
4. `base=$(git merge-base <target tip> <source_sha>)`. If `git merge-base --is-ancestor <source_sha> <target tip>`, the branch is already in the target: say so, DONE.
5. Overview (write it in the record, keep each list short with `| head`): `git log --format='%h %an %s' <base>..<source_sha> | head -n 40`; `git diff --stat <base> <source_sha> | tail -n 40`; `git rev-list --count <base>..<target tip>`; the files both sides changed (overlap of the two `--name-only` lists). Flag changes to project docs (`PROJECT.md` → Project docs, new `.md` files), dependency manifests or lockfiles, migrations, CI or deploy config, secret-looking files, and `.dev-team/`.
6. `git worktree add -b dev-team/<slug>/integration .dev-team/worktrees/<slug>/integration <source_sha>`, then the worktree setup from `PROJECT.md` → Build settings.
7. SUMMARY: the overview in 8 lines.

## Phase: scope

INPUTS: the record. OUTPUT: the record's Scope and Unplanned changes.
1. Gather intent, best source first: what NOTES say (sprint name, ticket IDs); a sprint plan for it (plan docs in `PROJECT.md` → Project docs, `.dev-team/sprints/`, the milestone in `BACKLOG.md`, any doc assigning work to sprints: `rg` the sprint name and read only matching sections); the requirements behind those items (`requirements.md` and the PRD/SRS sections it cites, or the tickets); commit messages and the branch name as hints only.
2. Fill the Scope table: one row per item with its requirement IDs and acceptance criteria. Where the docs give no testable criteria, write them and mark "(derived)".
3. Map the diff (`--stat`, then per-file as needed) to the items. Everything that maps to no item goes under Unplanned changes.
4. NEEDS-INPUT in one round: confirm the scope (or what's wrong), approve the derived criteria, and for each unplanned change whether it is expected.

## Phase: decisions

INPUTS: the record, the answers file (the user's policy or per-finding choices). OUTPUT: the record, the feedback file, backlog entries.
1. Set each finding's **Decision** from the answers.
2. **Send to author:** write `.dev-team/accept/<slug>-feedback.md` for someone who has never seen `.dev-team/`: a short summary (what was checked, at which commit, the verdict); per finding: where, the problem and its consequence, how to reproduce (bugs), the suggested fix, and the rule broken quoted in full with its source doc path; what was fixed on our side so they don't fix it twice. If the source is a PR, say in SUMMARY that it can be posted as a review (`gh pr review <n> --comment --body-file <file>`); never post it yourself. Set `status: waiting on author` when anything was sent.
3. **Backlog feature** (a missing item, or one too large to fix in place): `new` mode, add it to `BACKLOG.md` after the current milestone with "Source: `.dev-team/accept/<slug>.md`"; `existing` mode, add a line under `## Deferred` in `BACKLOG.md`.
4. Log line. SUMMARY: which findings will be fixed here (IDs and owners), sent, or backlogged.

## Phase: recheck

The author pushed. INPUTS: the record. OUTPUT: the record, worktree rebased.
1. Fetch the source. If it hasn't moved, DONE saying so.
2. `git log --format='%h %an %s' <old source_sha>..<new sha>`. Put our fixes on top of the author's new commits: `git -C <worktree> rebase <new sha>`. A fix the author already made becomes empty: `git rebase --skip`. A real conflict: `git rebase --abort`, and NEEDS-INPUT with each conflict and a proposed resolution; on the rerun, resolve as approved.
3. Update `source_sha` and the Log. SUMMARY: the new commits; the range for the reviewers is `<old source_sha>..<new sha>`.

## Phase: merge

INPUTS: the record, NOTES (merge style: merge commit / squash / rebase / pull request). OUTPUT: candidate branch, record.
1. **Freshness.** Fetch the source. If it moved past `source_sha`, BLOCKED: the new commits are unreviewed; recommend `recheck`. Re-resolve the target tip as in locate step 3.
2. **Build the candidate in the worktree** (commit or discard anything uncommitted there first):
   - Merge commit: `git -C <wt> switch -c dev-team/<slug>/candidate <target tip>`, then `git -C <wt> merge --no-ff dev-team/<slug>/integration`.
   - Squash: same switch, then `git -C <wt> merge --squash dev-team/<slug>/integration` and `git -C <wt> commit`.
   - Rebase: `git -C <wt> switch -c dev-team/<slug>/candidate dev-team/<slug>/integration`, then `git -C <wt> rebase <target tip>`.
   - Messages follow the commit rules in `STANDARDS.md`; otherwise `Merge <branch>: <scope items>`.
   - **Pull request:** push the integration branch under a name per `STANDARDS.md` (e.g. `<branch>-reviewed`) only if NOTES say the user approved pushing, then `gh pr create --base <target> --head <name>` with the Scope results, checks, fixed findings and what's open. Never push to the author's branch. Then go to the land phase's finish steps.
3. **Conflicts** mean the target changed the same code. For each conflicted file, write both sides, what each was for, and a proposed resolution into the record's Log, abort (`git merge --abort` / `git rebase --abort`), and NEEDS-INPUT. On the rerun, resolve as approved.
4. **Verify the result.** If manifests or lockfiles differ between integration and candidate, re-run the worktree setup. Run the full checks (`tail -n 40`), then re-test the acceptance criteria in files that conflicted or that both sides changed. A failure is a finding: NEEDS-INPUT (fix on the candidate / stop).
5. SUMMARY: `git log --oneline <target tip>..dev-team/<slug>/candidate | head -n 20`, the diffstat summary line, the check results.

## Phase: land

INPUTS: the record, NOTES (update and push / update local only).
1. Update the target, which only ever fast-forwards. If `<target>` is checked out in a worktree (`git worktree list`, usually the project root): `git -C <that worktree> merge --ff-only dev-team/<slug>/candidate`; if git refuses because local changes would be overwritten, BLOCKED naming the files. Otherwise `git fetch . dev-team/<slug>/candidate:<target>`.
2. If chosen, `git push <remote> <target>`. Rejected (someone pushed, or protected): never force; BLOCKED with why, recommending a rebuilt candidate or a PR.
3. **Finish:** confirm with `git merge-base --is-ancestor dev-team/<slug>/candidate <target>` (or that the PR branch was pushed); `git worktree remove` everything under `.dev-team/worktrees/<slug>/`; delete the `dev-team/<slug>/*` branches; set `merged:` and `status: done`; Log line.
4. `new` mode: tick the accepted features in `BACKLOG.md`. If plan docs list the accepted work, put the exact edits that mark it done in SUMMARY (don't apply them). If the merge changed a project doc, recommend `/team-docs`.
5. SUMMARY: what landed where, what's still open, and that the author's remote branch can be deleted if they want (don't delete it).
