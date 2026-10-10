# /team-rca procedure

Read by `team-analyst`, one phase at a time.

## Common

You find out why something broke, with evidence, before anyone fixes it. A symptom explained is not a root cause: keep going until you can point to the defect in the code, say what triggers it, and say why it got through. You don't fix product code; the fix goes through `/team-run`, starting with its spec. Read FLOW.md → "Ground rules" → Secrets: logs and data may hold secrets and personal data, so quote only the lines you need, redacted.

Files: the record `.dev-team/<slug>/rca.md`; evidence in `.dev-team/<slug>/rca/` (the report as given, the reproduction test or script, its output, screenshots, `fix.patch`). Work in `.dev-team/worktrees/rca-<slug>`.

**Confidence:** **confirmed** means the reproduction fails on `sha` and passes with the defect corrected; **likely** means the cause explains all the evidence but that proof wasn't possible; **uncertain** means candidates remain.

## Phase: mitigate

Only when users are affected right now. INPUTS: `rca/report.md`. Budget: about 15 tool calls. Find the quickest safe mitigation the user can apply (rollback, feature flag, config change, disabling a job), from the report, recent history (`git log --oneline -20`) and config. You never deploy, roll back, or change environments. SUMMARY: the options, recommended first, with how to apply each.

## Phase: investigate

INPUTS: `rca/report.md`, answers. OUTPUT: `rca.md` (template below), `rca/`. May be split into several runs (PARTIAL); on a rerun, continue from the Investigation table.
1. **Isolate.** `git worktree add --detach .dev-team/worktrees/rca-<slug> <sha>` (sha of `on <ref>`, default the committed `HEAD` of the user's branch), then the worktree setup from `PROJECT.md` → Build settings. All instrumentation, experiments and trial fixes happen there. Without git, work in the project root, revert every temporary change before finishing, and say so.
2. **Reproduce.** The smallest reliable reproduction, in this order: a failing automated test in the project's framework, a script or command. If only a browser reproduces it, write the exact steps in `rca/` and say the browser check wasn't run here. Copy the test or script and its failing output (`tail -n 40`) to `rca/`. Intermittent: run it enough times to state a failure rate. Can't reproduce: record what you tried and return NEEDS-INPUT: provide more information / continue from the evidence (lower confidence) / stop.
3. **Narrow it down.**
   - **When:** with a known-good ref and a scripted reproduction, `git bisect start <sha> <good>` and `git bisect run <repro>` in the worktree, then `git bisect reset`. Otherwise read the history of the affected code (`git log -p -- <paths> | head -n 200`).
   - **Where:** trace the path from the entry point (request, job, event, UI action) to the failure.
   - Check what changed around it: dependencies and lockfiles, config, schema and migrations, environment, data.
4. **Prove the cause.** List the hypotheses that fit the evidence. Test them one at a time, cheapest first, each with an experiment that would rule it out (a targeted log, a unit test, a changed input). Record every hypothesis in the Investigation table, including the ones ruled out. Ask "why" until you reach a cause the team can act on: the failing line, the wrong assumption behind it, why tests and review didn't catch it. Confirm it: correct the defect in the worktree, show the reproduction now passes and the full checks still do, and save the diff as `rca/fix.patch` (evidence, not the delivered fix). The cause must explain every symptom; if one is left, say so.
5. **Blast radius.** The same defect or pattern elsewhere (other callers, copies, sibling services, other repos in `PROJECT.md`), and data already written wrong that needs repair.
6. **Fix options.** 1–3 options, from the smallest change that removes the cause to a fuller one, each with files, risk and trade-offs; recommend one. `existing` mode: prefer the smallest change that fits. Add preventive actions that would have caught this earlier. A security vulnerability is said plainly; the fix's security review must cover it.
7. **Write `rca.md`** with every section filled; only what the evidence supports, the rest under Not verified.
8. SUMMARY in 5 lines or fewer: the symptom, root cause and confidence, blast radius, recommended fix. QUESTIONS (NEEDS-INPUT): which fix option; the Decision for each preventive action (in the fix / follow-up / won't do).

## Phase: finalize

INPUTS: `rca.md`, the user's decisions in NOTES.
Record the fix option and each preventive action's Decision, set `status: approved`, and remove the worktree (`git worktree remove .dev-team/worktrees/rca-<slug>`). Preventive actions marked follow-up go to `.dev-team/<slug>/followups.md`. `new` mode: add `<slug>` to `BACKLOG.md` with "Source: `.dev-team/<slug>/rca.md`", placed where NOTES say (default next for critical and major severity).

## `rca.md` template

```markdown
---
feature: <slug>
stage: rca
status: draft
ref: <branch or ref investigated>
sha: <commit investigated>
good: <last known-good ref, or unknown>
updated: <YYYY-MM-DD>
---

# RCA: <short description of the symptom>

## Summary
<What breaks, for whom, the root cause, and the recommended fix. 2–4 sentences.>

## Symptom
- Observed: <what happens, with the error or a short log excerpt>
- Expected: <what should happen>
- Where and when: <environment, version, since when, how often>
- Impact: <who is affected, what data, severity: critical | major | minor>
- Source: <ticket key/link, or "reported by the user">

## Reproduction
<The command or steps, the reproduction test in `rca/`, and its failing output on <sha>. Or "not reproduced", with what was tried.>

## Investigation
| # | Hypothesis | How tested | Result | Evidence |
|---|------------|------------|--------|----------|

## Root cause
- **Defect:** `path/to/file.py:42` — <what the code does wrong, and why>
- **Introduced:** <commit, PR, or ticket, from bisect or history; or unknown>
- **Trigger:** <the conditions that make it surface>
- **Why it got through:** <the missing test, validation, review check, or monitoring>
- **Confidence:** confirmed | likely | uncertain — <why>

## Blast radius
- <Other code paths, callers, or repos with the same defect or pattern, with paths>
- <Data already affected, and whether it needs repair>

## Fix options
1. **<Option> (recommended):** <the change, files, risk, and why>
2. **<Option>:** …

## Preventive actions
- <Regression test, validation, alert, or process change> — **Decision:** in the fix | follow-up | won't do (<reason>)

## Not verified
- <What you could not check, and why>
```
