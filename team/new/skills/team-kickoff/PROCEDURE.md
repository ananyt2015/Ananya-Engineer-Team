# /team-kickoff procedure

Read by `team-analyst`, one phase at a time. Doc discovery is the `discover` phase of `skills/team-docs/PROCEDURE.md`.

## Common

You run project inception with product, architecture and engineering hats on. You turn the project docs into a rulebook and a plan the team can build feature by feature. You don't write product code; the first backlog feature (project foundation) goes through `/team-run`. This project is in `new` mode: read FLOW.md → "Which source wins" (`new` mode) and "Ground rules" → Secrets. "How docs combine" is in the Common section of `skills/team-docs/PROCEDURE.md`.

Work files live in `.dev-team/setup/`: `discovery.md`, `answers.md` (every user answer so far), `findings.md` (evidence and open questions). Drafts carry `status: draft`.

## Phase: study

INPUTS: `discovery.md`, `answers.md`. OUTPUT: `findings.md`, draft `STANDARDS.md` and `requirements.md`.
1. **Read the chosen docs** in full and note the topics each governs (kind and scope as agreed). No PRD or SRS anywhere: return NEEDS-INPUT asking where they are.
2. **Load the global standards** from `skills/team/standards/`. A file with only `<!-- … -->` placeholders counts as absent.
3. **If product code already exists** (the project is mid-way), study it before anything is designed:
   - Map the codebase and observe its conventions as the onboard procedure's study steps 3–4 do (`skills/team-onboard/PROCEDURE.md` is only installed in existing mode, so: stack, entry points, modules, data layer, API style, frontend, AI integrations; conventions with file-path evidence and a high/medium confidence tag).
   - Compare them with the rules. Where the code departs from a project doc or the standards, note it as a question: keep the code's way for consistency, or apply the rule to new code and plan to fix the old.
   - Find and verify the commands (install, dev server, test, lint, typecheck; run only read-only ones, output through `tail -n 40`) and work out the worktree setup (dependencies from the lockfile or symlinks; `.env` symlinked, never copied). Record which tests already fail.
   - Note which plan items the code appears to cover. Don't judge whether they're done; `/team-audit` does that.
4. **Draft `STANDARDS.md`** from `skills/team/STANDARDS_TEMPLATE.md`: for each topic start from the global standard, then apply the project docs (a project doc wins on any topic it covers; repo docs refine shared ones). Record every override in "Adjustments to my global standards". Add a section for each project-specific topic (e.g. "Manifest"). Cite every rule's source; summarise and point to the doc rather than copying schemas.
5. **Draft `requirements.md`**: every functional and non-functional requirement, one line each, with an ID (keep the documents' own IDs; otherwise `FR-1…`, `NFR-1…`), its source (document and section), and its owner if the product spans several repos (this repo, another by name, or shared). End with **Gaps and conflicts**: anything ambiguous, contradictory between docs, or missing (error cases, roles and permissions, data retention, performance targets, compliance).
6. **Write `findings.md`** and return NEEDS-INPUT (up to two rounds' worth, most important first, 6 per round): requirement gaps, conflicts between docs, important topics with no rule, owners you can't place, and places where existing code departs from the rules. Never edit the docs; if one should change, say so.

## Phase: design

INPUTS: `findings.md`, `answers.md`, the drafts. OUTPUT: final drafts of `STANDARDS.md`, `requirements.md`, plus `architecture.md`, `BACKLOG.md`, `PROJECT.md`.
1. Record the answers under "Decisions" in `STANDARDS.md` or in `requirements.md`.
2. **`architecture.md`**: stack, components and responsibilities, data model at entity level, external integrations, AI/LLM components, how each non-functional requirement is met, environments and deployment, repository structure, and a short decisions table with the options considered. It conforms to `STANDARDS.md`: where a project doc already decides something (e.g. `databases.md`), follow and reference it. Where code exists, describe the system as built and mark what is planned. Record each departure the user chose to keep.
3. **`BACKLOG.md`**: features in delivery order, grouped into milestones. Each has a slug, a one-line goal, the requirement IDs it covers, and dependencies. The first is `project-foundation` (repository structure, tooling, configs, test setup, CI, README per `STANDARDS.md`, plus the Commands and Worktree setup in `PROJECT.md`). Every requirement owned by this repo (or shared) appears in at least one feature. End the file with an empty `## Deferred` section (declined comment work and follow-ups go there).
   - **Plan docs** decide the order: their sprints become milestones, in their order, and each feature traces to its plan items (`Plan: sprint.md § Sprint 2, tasks 4–7`). Changing their order or grouping needs a question.
   - **Work built before kickoff** stays unticked and is marked "(built, not verified)"; work on an unmerged branch is marked "(on branch `<name>`)".
   - **Existing foundation**: `project-foundation` covers only what's missing, or is left out.
   - **Several repos**: requirements owned elsewhere don't become features. List what this repo needs from the others, and they from it, under `## Cross-repo dependencies` with the contract.
   ```markdown
   ## Milestone 1 — <name>
   - [ ] `project-foundation` — Repo, tooling, CI, test setup per standards. Covers: NFR-3, NFR-7. Depends: none
   - [ ] `user-auth` — Email and password sign-in. Covers: FR-1, FR-2, NFR-1. Depends: project-foundation

   ## Deferred
   ```
4. **`PROJECT.md`** from the template below.
5. SUMMARY for the user's approval: docs by kind, the main adjustments to the standards, requirement counts, decisions made, stack, milestones, the first three features, and whether the project needs a first git commit before building.

## `PROJECT.md` template

```markdown
---
feature: project
stage: project
status: draft
mode: new
updated: <YYYY-MM-DD>
---

# <Project name>

## Summary
<What the product is and who it is for, from the PRD. 2–3 sentences.>

## Project docs
| Doc | Kind | Scope | Governs | Hash |
|-----|------|-------|---------|------|
| `docs/PRD.md` | requirements | shared | product scope, user flows | 1a2b3c4d |

## Doc sources
- Scanned: `docs/` and every other `.md` in the repo (git-ignored files skipped)
- Ignored: <paths the user chose not to use>

## Product repos
<Only if the product spans several repos; otherwise "Single repo".>
| Repo | Owns | Local path | Base branch |
|------|------|------------|-------------|

## Stack
<Languages, frameworks, database, AI providers, hosting.>

## Commands
<Verified at kickoff if code already exists; otherwise filled in by project-foundation, and until then "not set up yet".>
- Install: … · Dev server: … (URL) · Test: … · Lint: … · Typecheck: …

## Build settings
- Worktree setup: <commands that make a fresh worktree runnable; verified at kickoff if code exists, otherwise filled in by project-foundation>
- Worktree helper: <script, or "none">
- Plan docs: <where sprints and tasks are listed, or "none">
- Max parallel engineers: 4
- Delivery preference: <unset until the first delivery>
```
