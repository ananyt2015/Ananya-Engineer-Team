---
name: team-audit
description: Audit lead of the dev team. Validates work that is already on a branch, such as a sprint built before the team was deployed, against the plan, requirements, and STANDARDS.md. Reports what is done, partial, missing, or off-standard, checks whether a pending branch already touches each gap, and turns the gaps into backlog features. Use only when the user invokes /team-audit.
disable-model-invocation: true
---

# /team-audit — Validate existing work

You check whether work that already exists does what the plan says it does. The plan may say sprint 1 is done; you find out, with evidence, what is really done, what is partial, what is missing, and what breaks the project's rules. Then the user decides what becomes new work. You don't change product code; gaps go through the normal flow.

Read `skills/team/FLOW.md`, `.dev-team/PROJECT.md`, and `.dev-team/STANDARDS.md` first. Gate: `PROJECT.md` and `STANDARDS.md` approved.

## Usage

- `/team-audit <sprint name | feature slugs | all> [on <ref>] [against <branch>…]`
  - `on <ref>`: what to audit. Default: the committed `HEAD` of the user's current branch.
  - `against <branch>`: pending work not merged yet, such as a teammate's next sprint. Each gap is checked against it, so the team doesn't fix something that branch already changes.
- `/team-audit status` — list audit records and their open gaps.

## Record

`.dev-team/audit/<name>.md`, where the name is the sprint name or a short label (e.g. `sprint-1`). Findings use the FLOW.md format with `G` IDs.

```markdown
---
feature: <name>
stage: audit
status: draft | approved | done
ref: <branch or ref audited>
sha: <commit audited>
against: <pending branches and the commits checked, or none>
updated: <YYYY-MM-DD>
---

# Audit: <name> at <ref>

## Verdict
<How much of the scope is really done, the most important gaps, and whether the next sprint can safely build on it. 2–3 sentences.>

## Scope
| Item | Requirements | Acceptance criterion | Status | Evidence | Pending branch |
|------|--------------|----------------------|--------|----------|----------------|

Status: done | partial | missing | off-standard | not verifiable. Evidence: file paths, tests, or screenshots. Pending branch: "changes this" or "implements this" if a pending branch touches it.

## Checks
- `<command>` — <result>

## Findings
<G findings, each with a **Decision**: gap feature | backlog later | already addressed by <branch> | won't fix (<reason>)>

## Not verified
- <what you could not check, and why>
```

## Steps

1. **Agree the scope.** Work out what this work was supposed to deliver, as `/team-accept` step 2 does: plan docs first (the sprint's section in `sprint.md` or `tasks.md`), then the matching milestone in `BACKLOG.md`, the requirements and their acceptance criteria in `requirements.md` and the PRD/SRS, and in `existing` mode, the tickets the user names. Derive testable criteria where the docs have none, and mark them "(derived)". The user confirms the scope and derived criteria in one AskQuestion round.

2. **Isolate.** If the project root has uncommitted changes, tell the user they won't be audited, and ask whether to continue or wait for them to commit. Create a read-only checkout: `git worktree add --detach .dev-team/worktrees/audit-<name> <sha>`, then run `PROJECT.md` → Worktree setup in it. Without git, audit the project root and say so.

3. **Trace every item to the code.** For each acceptance criterion, find the code that implements it and note the paths. For a large codebase, delegate the search to `explore` subagents, one per area, and ask for paths and a one-line explanation. Nothing found means **missing**; something found that covers only part of the criterion means **partial**.

4. **Verify what the code claims.**
   - Run the full checks from `PROJECT.md` in the worktree and record the results.
   - For items that look done, verify them as `/team-qa` steps 1, 3, and 4 do: an existing test that proves the criterion, or a browser walkthrough for UI. Save screenshots to `.dev-team/audit/<name>/`. Code that exists but fails its criterion is **partial**, with a finding.
   - Review the scope's code with the checklists in `skills/team-review/SKILL.md` step 3 (correctness, edge cases, error handling, rules, comments, tests) and `skills/team-security/SKILL.md` step 2. A criterion met by code that breaks a `STANDARDS.md` rule is **off-standard**, citing the rule.
   - Only report findings you can point to in the code, with a concrete consequence.

5. **Check pending branches** (`against`). Fetch each one and find where it split off: `base=$(git merge-base <sha> <branch>)`. For every gap, check whether the branch touches the same code (`git diff --stat <base> <branch> -- <paths>`) or implements the missing behaviour, and fill the Pending branch column. A gap the branch already addresses is verified when that branch is accepted (`/team-accept`), not built twice. A gap the branch touches without fixing should wait until the branch is merged, or the fix will collide with it; say so.

6. **Write the record**: the Verdict, Scope, Checks, Findings ordered by severity, and Not verified.

7. **Decide.** Summarise: items by status, the gaps by severity, and which gaps a pending branch affects. Ask with AskQuestion, recommending:
   - **Gap feature** (recommended for gaps the next sprint builds on, and for critical and major defects): one feature, `<name>-gaps`, that closes them.
   - **Backlog later**: a backlog feature placed where it fits, in `new` mode; in `existing` mode, a note under the record's Findings for the user to raise as a ticket.
   - **Already addressed by `<branch>`**: no new work; recheck after `/team-accept`.
   - **Won't fix**, with a reason.
   Then record each Decision and set `status: approved`.

8. **Hand the gaps to the normal flow.**
   - `new` mode: in `BACKLOG.md`, tick items verified **done** (`[x]`, with "(verified by audit <name>)"). Leave partial and missing ones unticked, with a pointer to their finding. Add `<name>-gaps` right after the audited milestone, depending on nothing new, with "Source: `.dev-team/audit/<name>.md`".
   - Plan docs: propose the exact edits that reflect reality (e.g. un-tick a task marked done that is missing), and apply them only if the user approves.
   - Remove the worktree with `git worktree remove .dev-team/worktrees/audit-<name>`.
   - Tell the user the next step: `/team-plan <name>-gaps` (it reads this record), or `/team run <name>-gaps` to go straight through. If a pending branch is waiting, say whether to build the gaps first or accept the branch first, based on step 5: build first when the gaps don't overlap the branch; otherwise accept the branch first.

## Status

For each `.dev-team/audit/*.md`, report its scope, the audited commit, items by status, open gaps by decision, and whether the gap feature has been delivered.
