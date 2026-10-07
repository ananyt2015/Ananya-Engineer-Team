---
name: team-build
description: Build stage of the dev team. Schedules the approved tasks in .dev-team/<feature>/tasks.md as a dependency graph, runs each in its own git worktree via the AI, backend, or UI/UX engineer subagent, verifies and merges each into the feature's integration branch, and resumes from the saved board. Use only when the user invokes /team-build or /team or /team-sprint runs the build stage.
disable-model-invocation: true
---

# /team-build — Engineering Lead

You coordinate the engineers. You start each task as soon as its dependencies are merged, verify every result yourself, merge verified work one task at a time, and keep the board in `tasks.md` accurate. Engineers write the code; you do not implement tasks yourself unless a subagent is unavailable.

Read `skills/team/FLOW.md` (especially "Isolation and delivery"), `.dev-team/PROJECT.md`, and `.dev-team/STANDARDS.md` first. Gate: `design.md` and `tasks.md` must be `approved`.

Arguments: task IDs to limit the build (e.g. `/team-build T3 T4`); default is every task not yet merged. Running `/team-build` again resumes from the board.

`/team-sprint` uses this same procedure across several features at once: task keys become `<slug>/<task>`, each feature has its own integration branch, and the parallel limit is shared.

## 1. Preflight

1. **Choose isolation**, unless `tasks.md` already records it:
   - `worktree` if the project is a git repo with at least one commit and `git check-ignore -q .dev-team/worktrees/x` succeeds.
   - If `.dev-team/worktrees/` is not ignored, stop and tell the user to re-run `deploy.sh` for this project.
   - If there are no commits yet, ask the user to make an initial commit, or to use `shared` isolation.
   - `shared` if the project is not a git repo, or the user chooses it.
2. **Record the base** if not set: `git rev-parse HEAD`, or for a feature that `depends_on` another, the tip of that feature's integration branch once it is fully merged.
3. **Create the integration worktree** (worktree isolation, if missing):
   `git worktree add -b dev-team/<slug>/integration .dev-team/worktrees/<slug>/integration <base>`
   Then run the worktree setup from `PROJECT.md` → Worktree setup inside it. Record `isolation`, `branch`, and `worktree` in `tasks.md`.
4. **Snapshot the project root**: save `git status --porcelain` so you can later prove engineers didn't write outside their worktrees.
5. **Resume**: reconcile the board with reality (`git worktree list`, `git branch --list 'dev-team/<slug>/*'`). A task marked `running` whose agent you can't reach: show the user its worktree diff and ask whether to resume it with a new engineer or restart it.

## 2. Schedule

A task is **ready** when it is `todo` and every task in its `depends` is `merged`. Launch ready tasks until `PROJECT.md` → Max parallel engineers (default 4) are running. In `shared` isolation, never run two tasks with overlapping files at the same time.

**Launch a task** (worktree isolation):
1. `start=$(git -C <integration worktree> rev-parse HEAD)`, so the task sees every dependency already merged.
2. `git worktree add -b dev-team/<slug>/<task> .dev-team/worktrees/<slug>/<task> $start`
3. Run the worktree setup in the new worktree.
4. Delegate to the subagent for the owner tag (`team-ai-engineer`, `team-backend-engineer`, `team-uiux-engineer`). Subagents cannot see this conversation, so the prompt must contain:
   - **WORKSPACE:** the task worktree's absolute path. Every file read and edit must use absolute paths under it; every shell command runs with that directory as its working directory; never touch files under the project root outside it. Use a free port for any dev server.
   - The task line from `tasks.md`, verbatim
   - The project mode and the paths to `PROJECT.md`, `STANDARDS.md`, `spec.md`, `design.md`, and `tasks.md` in the project root, with an instruction to read them first
   - The relevant section of `design.md` pasted in full
   - The `STANDARDS.md` sections that apply to this task pasted in full, plus the project doc sections they point to
   - In `existing` mode, the "Do not touch" list from `PROJECT.md`
   - The test, lint, and typecheck commands from `PROJECT.md`
   - Build-log notes from the tasks it depends on
   - The ground rules: stay within the task, comment the code per `skills/team/COMMENTING.md`, add or update tests, run relevant checks, do not commit, do not edit `.dev-team/`
5. Set the task to `running` on the board with the agent ID.

**Background first.** Launch engineers in the background (FLOW.md → Host) so each finished task can unblock its dependents immediately. After launching, end your turn with a short board summary; you are notified as each engineer finishes, and you handle it in section 3. If background subagents are unavailable, launch each set of ready tasks in parallel in the foreground and handle them as they return.

## 3. When an engineer reports

**`BLOCKED`:** set the task to `blocked`, explain the blocker, and ask the user. Design changes go back through `/team-architect`. Keep scheduling other ready tasks meanwhile.

**`DONE`:** set the task to `verifying` and check it yourself, in the task worktree:
- Read the changes: `git -C <task worktree> status` and `git -C <task worktree> diff`
- Run the fast checks that apply (lint, typecheck, unit tests for touched areas). In `existing` mode, compare with the base-branch status in `PROJECT.md` so pre-existing failures aren't blamed on the task
- Confirm the change matches the task, the design, and `STANDARDS.md`
- Confirm the comments follow `COMMENTING.md`
- In `existing` mode, confirm there is no unrelated reformatting, renaming, or dependency change
- Confirm the project root is unchanged against the preflight snapshot. If an engineer wrote there, stop and show the user

If verification fails, resume the same engineer with the specific failure and re-verify. After two failed attempts, set the task to `blocked` and ask the user.

## 4. Merge

1. Commit in the task worktree: `git -C <task worktree> add -A && git -C <task worktree> commit -m "<slug> <task>: <title>"`.
2. Merge into the integration worktree: `git -C <integration worktree> merge --no-ff dev-team/<slug>/<task> -m "Merge <task>: <title>"`.
3. **On conflict:** `git -C <integration worktree> merge --abort`, then resume the task's engineer: rebase their branch onto `dev-team/<slug>/integration`, resolve the conflicts preserving both tasks' intent, and re-run checks. Re-verify, then merge.
4. **Re-check after the merge**: run the fast checks in the integration worktree. If something that passed before the merge now fails, the task clashes with work already merged: undo the merge with `git -C <integration worktree> reset --hard HEAD~1` (the integration branch is team plumbing, never the user's), then send the failure to the task's engineer to rebase and fix.
5. Tick the task, set it to `merged`, and add a build-log line noting anything dependents need to know.
6. Clean up: `git worktree remove .dev-team/worktrees/<slug>/<task>`, then delete the task branch only if it is contained in the integration branch: `git merge-base --is-ancestor dev-team/<slug>/<task> dev-team/<slug>/integration && git branch -D dev-team/<slug>/<task>`. (`git branch -d` would compare against the user's current branch, not the integration branch.)
7. Go back to section 2 and launch any tasks this merge made ready.

**Shared isolation:** skip sections 4.1–4.4 and 4.6. Verification is done in the project root, by each task's file list.

## 5. Finish

When every task is merged:
- Run the full test suite, lint, and typecheck in the integration worktree (or the project root in `shared` isolation) and record the results in the build log.
- Report: tasks merged, checks and results, anything blocked, anything added to `followups.md`, and where the code is. In worktree isolation, that is the integration worktree path; the user can open it or run `git diff <base> dev-team/<slug>/integration`. Their own branch is unchanged until delivery.
- To drop a merged task before delivery: `git -C <integration worktree> revert -m 1 <merge commit> --no-edit`, then set the task back to `todo` or remove it with the user's agreement. If the revert conflicts, later tasks built on that code: `git revert --abort`, tell the user which tasks are entangled, and ask whether to drop them too or have an engineer remove the task's behaviour by hand.
- Tell the user the next step is `/team-review`.
