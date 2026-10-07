---
name: team-kickoff
description: Project kickoff for a new project built from scratch. Reads every .md file under docs/ (PRD, SRS, and project-specific docs such as databases.md or manifest.md) plus the repo-level docs the user selects (such as a repo's own databases.md, sprint.md, or tasks.md), adjusts my global standards into a project rulebook, and produces the project profile, standards, requirement index, architecture, and backlog in .dev-team/. Use only when the user invokes /team-kickoff or /team runs project setup in new mode.
disable-model-invocation: true
---

# /team-kickoff — New Project Kickoff

You run project inception with the whole team's hats on: product, architecture, and engineering. You turn the project docs into a rulebook and a plan the team can execute feature by feature. You do not write product code; the first backlog feature (project foundation) goes through the normal flow.

Read `skills/team/FLOW.md` first. This project is in `new` mode.

Arguments: none for a full kickoff. `refresh` runs `/team-docs` (`skills/team-docs/SKILL.md` → Reconcile).

## Steps

1. **Find the docs.** Follow `skills/team-docs/SKILL.md` → Discovery. It scans `docs/` and every other `.md` file in the repo, so repo-specific docs kept outside `docs/` (this repo's `databases.md`, `sprint.md`, `tasks.md`) are found too. It also asks which product repos exist if the product spans several.
   - If no PRD or SRS turns up anywhere, ask the user where they are.

2. **Classify every doc** by kind (requirements, standard, plan, reference) and scope (shared or repo), as Discovery describes, and note the topics each one governs. "How docs combine" in that skill says how shared docs, repo docs, and plan docs fit together.

3. **Load my global standards** from `skills/team/standards/`. Note which are still templates.

   **If product code already exists** (the project is mid-way, e.g. sprint 1 is built), study it before designing anything, so the team builds on it instead of starting over:
   - Map the codebase and observe its conventions as `/team-onboard` steps 4–5 do, with file paths as evidence.
   - Compare the conventions with the rules from steps 1–4. Where the code departs from a project doc or my standards, note it for step 6: keep the code's way for consistency, or apply the rule to new code and plan to fix the old.
   - Find and verify the commands (install, dev server, test, lint, typecheck) and the worktree setup as `/team-onboard` step 7 does, so the team can build in worktrees right away. Record which tests already fail.
   - Note which plan items the code appears to cover. Don't judge whether they're done; `/team-audit` does that with evidence.

4. **Write `.dev-team/STANDARDS.md`** using `skills/team/STANDARDS_TEMPLATE.md`:
   - For each topic, start from my global standard, then apply the project docs: a project doc wins on any topic it covers, and repo docs refine shared docs for this repo ("How docs combine" in `team-docs`). Record every override in "Adjustments to my global standards".
   - Add a section for each project-specific topic the docs introduce (e.g. "Manifest" from `manifest.md`).
   - Cite the source of every rule. Summarise and point to the doc for detail; don't copy schemas or long specs.
   - List conflicts *between* project docs, and topics covered by nothing, for step 6.

5. **Index the requirements** in `.dev-team/requirements.md`:
   - Every functional and non-functional requirement from the requirements docs, one line each, with an ID. Keep the documents' own IDs if they have them; otherwise assign `FR-1…` and `NFR-1…`.
   - The source of each (document and section).
   - If the product spans several repos (`PROJECT.md` → Product repos), the owner of each: this repo, another repo by name, or shared. Ask about any you can't place.
   - A **Gaps and conflicts** section: anything ambiguous, contradictory between docs, or missing (error cases, roles and permissions, data retention, performance targets, compliance).

6. **Resolve open points.** Ask the user about requirement gaps, conflicts between docs, important topics with no rule, and places where existing code departs from the rules, in one or two AskQuestion rounds, most important first. Record answers under "Decisions" in `STANDARDS.md` or in `requirements.md`. Never edit the docs themselves; if a doc should change, say so.

7. **Design the system** in `.dev-team/architecture.md`: stack, components and responsibilities, data model at entity level, external integrations, AI/LLM components if any, how each non-functional requirement is met, environments and deployment, repository structure, and a short decisions table with the options considered. It must conform to `STANDARDS.md`: where a project doc already decides something (e.g. the database design in `databases.md`), follow and reference it instead of redesigning it. Where code already exists, describe the system as built, and mark what is planned but not built yet. Record each departure from the rules that the user chose to keep as a decision.

8. **Build the backlog** in `.dev-team/BACKLOG.md`: features in delivery order, grouped into milestones. Each feature has a slug, a one-line goal, the requirement IDs it covers, and dependencies. The first feature is `project-foundation`: repository structure, tooling, configs, test setup, CI, and README per `STANDARDS.md`, plus the Commands and Worktree setup in `PROJECT.md`. If the project is not yet a git repo with a first commit, ask the user to create one before building, so the team can work in isolated worktrees. Every requirement ID owned by this repo (or shared) appears in at least one feature.
   - **Plan docs** (e.g. `sprint.md`, `tasks.md`): the backlog follows them. Use their sprints as milestones, in their order, and trace each feature to the plan items it covers (`Plan: sprint.md § Sprint 2, tasks 4–7`). Ask before changing their order or grouping.
   - **Work built before kickoff**: features the plan shows as done, or that the code appears to cover, stay unticked and are marked "(built, not verified)". `/team-audit` ticks them once verified. Work that lives on a branch not merged yet, such as a teammate's sprint, is marked "(on branch `<name>`)".
   - **Existing code**: if the foundation (structure, tooling, tests, CI) already exists, `project-foundation` covers only what is missing from it per `STANDARDS.md`, or is left out if nothing is.
   - **Several repos**: requirements owned by another repo don't become features here. List what this repo needs from the others, and what the others need from it, under `## Cross-repo dependencies`, with the contract both sides must agree on (e.g. an API endpoint and its shape).

   ```markdown
   ## Milestone 1 — <name>
   - [ ] `project-foundation` — Repo, tooling, CI, test setup per standards. Covers: NFR-3, NFR-7. Depends: none
   - [ ] `user-auth` — Email and password sign-in. Covers: FR-1, FR-2, NFR-1. Depends: project-foundation
   ```

9. **Write `.dev-team/PROJECT.md`** using the template below.

10. **Approve.** Summarise: docs found by kind, the main adjustments to my standards, requirement counts, decisions made, stack, milestones, and the first three features. Ask: Approve / Revise / Stop. On Approve, set all five documents to `approved` and tell the user the next step:
   - No code yet: `/team-plan project-foundation`.
   - Work built before kickoff: `/team-audit <first built sprint>`, adding `against <branch>` for any teammate's branch not merged yet. Then build the gaps it finds, and accept pending branches with `/team-accept`.

## Refresh (`/team-kickoff refresh`)

Follow `skills/team-docs/SKILL.md` → Reconcile. It is the same as `/team-docs`.

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
| `docs/manifest.md` | standard | shared | services, ports, environments | 9c0d1e2f |
| `databases.md` | standard | repo | this repo's schema conventions, migrations | 5e6f7a8b |
| `sprint.md` | plan | repo | sprint contents and order | 3a4b5c6d |

## Doc sources
- Scanned: `docs/` and every other `.md` in the repo (git-ignored files skipped)
- Ignored: <paths the user chose not to use, e.g. `CHANGELOG.md`, `packages/ui/README.md`>

## Product repos
<Only if the product spans several repos; otherwise "Single repo".>
| Repo | Owns | Local path |
|------|------|------------|
| <this repo> (this repo) | <e.g. API and database> | . |
| <web> | <e.g. web app> | <../web, or unknown> |

## Stack
<Languages, frameworks, database, AI providers, hosting.>

## Commands
<Verified at kickoff if code already exists; otherwise filled in by project-foundation, and until then "not set up yet".>
- Install: … · Dev server: … (URL) · Test: … · Lint: … · Typecheck: …

## Build settings
- Worktree setup: <commands that make a fresh worktree runnable; verified at kickoff if code exists, otherwise filled in by project-foundation>
- Max parallel engineers: 4
- Delivery preference: <unset until the first delivery>
```
