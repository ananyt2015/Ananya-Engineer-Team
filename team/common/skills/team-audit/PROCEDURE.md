# /team-audit procedure

Read by `team-analyst`, one phase at a time. Review, security and QA are done by `team-reviewer`, `team-security-reviewer` and `team-qa-tester` in MODE `audit`.

## Common

You check whether work that already exists does what the plan says it does. The plan may say sprint 1 is done; you find out, with evidence, what is really done, partial, missing, or off-standard. You don't change product code; gaps go through `/team-run`.

**Record:** `.dev-team/audit/<name>.md` (the sprint name or a short label, e.g. `sprint-1`). Findings use the FLOW.md format with `G` IDs. Answers in `.dev-team/audit/<name>-answers.md`; screenshots in `.dev-team/audit/<name>/`. Read-only checkout: `.dev-team/worktrees/audit-<name>`.

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

Status: done | partial | missing | off-standard | not verifiable. Evidence: file paths, tests, or screenshots. Pending branch: "changes this" or "implements this".

## Checks
- `<command>` — <result>

## Findings
<G findings, each with a **Decision**: gap feature | backlog later | already addressed by <branch> | won't fix (<reason>)>

## Not verified
- <what you could not check, and why>
```

## Phase: scope

NOTES: what to audit (sprint name, feature slugs, or all), `on <ref>`, `against <branch>…`. OUTPUT: the record with its Scope rows (Status empty).
Work out what this work was meant to deliver: plan docs first (the sprint's section in the plan docs listed in `PROJECT.md`: `rg` the sprint name, read only matching sections), then the matching milestone in `BACKLOG.md`, the requirements and their acceptance criteria (`requirements.md` and the PRD/SRS sections it cites), and in `existing` mode the tickets in NOTES. Derive testable criteria where the docs have none, marked "(derived)". NEEDS-INPUT in one round: confirm the scope and the derived criteria; if the project root has uncommitted changes, say they won't be audited and ask whether to continue.

## Phase: trace

INPUTS: the record, the answers. OUTPUT: the record's Scope (Status, Evidence, Pending branch) and Checks.
1. **Isolate.** `git worktree add --detach .dev-team/worktrees/audit-<name> <sha>` (default the committed `HEAD` of the user's branch), then the worktree setup from `PROJECT.md` → Build settings. Without git, audit the project root and say so.
2. **Trace every criterion to the code.** `rg` for it, read the matching ranges, note the paths. Nothing found: **missing**. Something that covers only part: **partial**. Found and plausible: leave for QA to confirm as **done**.
3. **Checks.** Run the full checks from `PROJECT.md` in the worktree (`tail -n 40`) and record them.
4. **Pending branches** (`against`). Fetch each; `base=$(git merge-base <sha> <branch>)`. For every gap, check whether the branch touches the same code (`git diff --stat <base> <branch> -- <paths>`) or implements the missing behaviour, and fill the Pending branch column. A gap the branch addresses is verified when that branch is accepted, not built twice. A gap it touches without fixing should wait until it is merged; say so.

## Phase: handoff

INPUTS: the record, the answers (each finding's Decision). OUTPUT: record, `BACKLOG.md`.
1. Record each Decision and set `status: approved`.
2. `new` mode, `BACKLOG.md`: tick items verified **done** (`[x]`, "(verified by audit <name>)"); leave partial and missing ones unticked with a pointer to their finding; add `<name>-gaps` right after the audited milestone with "Source: `.dev-team/audit/<name>.md`". Backlog-later gaps: features placed where they fit (`new` mode) or lines under `## Deferred` (`existing` mode).
3. Plan docs: the exact edits that would reflect reality (e.g. un-tick a task marked done that is missing) go in SUMMARY; don't apply them.
4. `git worktree remove .dev-team/worktrees/audit-<name>`.
5. SUMMARY: the next step, `/team-run <name>-gaps` (its spec step reads this record). If a pending branch waits: build the gaps first when they don't overlap it; otherwise accept the branch first.
