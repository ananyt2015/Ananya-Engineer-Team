---
name: team-docs
description: Project docs lead of the dev team. Scans docs/ and every other .md file in the repo (repo-level docs such as databases.md, sprint.md, tasks.md), classifies each one, tracks which are shared with the product's other repos and which are specific to this repo, checks synced copies for drift, and adjusts STANDARDS.md, the requirement index, the backlog, and the plan to match. Use only when the user invokes /team-docs, or when /team-kickoff or /team-onboard run doc discovery.
disable-model-invocation: true
---

# /team-docs — Project docs

You keep the team's understanding of the project in step with the project's own docs, wherever they live. Projects often keep product-wide docs (PRD, SRS, manifest) in `docs/`, synced across several repos, while docs that only make sense for one repo (its database, its sprint plan, its task list) stay elsewhere in that repo. You find all of them, work out what each one governs, and adjust the team's artifacts to match. You never edit the docs themselves without the user's approval.

Read `skills/team/FLOW.md` first.

## Usage

- `/team-docs` — scan, show what changed, and adjust the team's artifacts with the user's approval.
- `/team-docs status` — scan and report only; change nothing.

Setup runs the Discovery section below: `/team-kickoff` in `new` mode, `/team-onboard` in `existing` mode. Before setup, `/team-docs` only reports what it finds and tells the user to run setup.

## Doc kinds and scope

Every doc gets a **kind**:
- **requirements**: what to build (PRD, SRS, user stories, feature specs)
- **standard**: rules for how to build it (e.g. `databases.md`, `manifest.md`, API conventions, naming, deployment, security policy, design system)
- **plan**: the user's own plan and progress (e.g. `sprint.md`, `tasks.md`, a roadmap): which work belongs to which sprint, in what order, and what is done
- **reference**: context with no rules (research, glossary, meeting notes)
- **ignored**: not a project doc (changelogs, licences, a package's README, test fixtures)

A doc can have more than one kind (e.g. a SRS that also sets API rules). Every doc also gets a **scope**:
- **shared**: the same doc exists in the product's other repos (usually synced copies of the PRD, SRS, manifest)
- **repo**: specific to this repo

## Discovery

1. **Scan** for `.md` files (and `.MD`):
   - In a git repo: `git ls-files -co --exclude-standard -- '*.md' '*.MD'`, which covers tracked and untracked files but skips anything `.gitignore` hides (dependencies, build output).
   - Otherwise: `find . -name '*.md'`, pruning `node_modules`, `.git`, `vendor`, `dist`, `build`, `.venv`, `venv`, `__pycache__`, and `target`.
   - Always skip `.dev-team/` (except `.dev-team/docs/`, which holds copies of docs the user provided from outside the repo), `.cursor/`, and `.claude/`.
   - Also note `.pdf`, `.docx`, and `.txt` files under `docs/`. Read PDFs and text directly; convert `.docx` with `textutil -convert txt "<file>" -output /tmp/<name>.txt`.
2. **Group** the files: `docs/`, the repo root, and other folders. Skim each one (title, headings, first lines), and propose a kind and scope for each with a one-line reason. Propose **ignored** for changelogs, licences, codes of conduct, issue and PR templates, and READMEs of individual packages or vendored code. In `existing` mode, a PR template or `CONTRIBUTING.md` is a **standard** (team process).
3. **Product repos.** If the docs mention other repos, or the same docs appear synced elsewhere, the product spans several repos. Ask which repos those are, what each one owns, and, optionally, where each one is checked out on this machine (so you can check shared docs for drift).
4. **Ask** with AskQuestion, in one round:
   - Which docs to use, as a multi-select per group with your recommendation preselected. In `new` mode, recommend everything under `docs/`; recommend files elsewhere only when they look like project docs.
   - Confirm or correct the kind and scope of any doc where you are unsure.
   - The product repos question, if it applies.
   In `existing` mode, add the options from `/team-onboard` step 2: docs outside the repo (paths) or pasted content, and "No docs — learn from the code".
5. **Read** every selected doc in full and note the topics it governs. If a doc's purpose is still unclear, ask.
6. **Record** in `PROJECT.md` (the setup skill's template has these sections):
   - **Project docs**: one row per selected doc, with its kind, scope, what it governs, and a short hash (`shasum -a 256 <file> | cut -c1-8`).
   - **Doc sources**: what was scanned, plus every path the user chose to ignore, so later scans don't ask about them again.
   - **Product repos**, if any: one row per repo with what it owns and its local path if known, marking this repo.

## How docs combine

These refine the precedence in FLOW.md → "Which source wins"; they don't replace it.

- **Repo docs refine shared docs** for this repo. A shared manifest might name the services; this repo's `databases.md` defines this repo's schema. Both apply.
- **Real contradictions get asked**, never assumed. The answer goes under "Decisions" in `STANDARDS.md`, and you tell the user which doc should probably change.
- **Plan docs decide what and when**: which work is in which sprint, the order, and what is done. They never override requirements (what to build) or standards (how). If a plan doc lists work no requirement covers, or contradicts a requirement, ask.
- **Requirements belong to repos.** When the product spans several repos, each requirement is marked as owned by this repo, another repo, or shared. Work for another repo never enters this repo's backlog. It is recorded as a cross-repo dependency, with what both sides must agree on (e.g. the API contract).

## Reconcile (`/team-docs`)

1. **Gate.** `PROJECT.md` must exist; if not, run Discovery, show what you found, and tell the user to run `/team-kickoff` (new) or `/team-onboard` (existing), which will use it. Stop.
2. **Scan** as in Discovery, then compare with the Project docs table and Doc sources:
   - **Changed**: the hash differs. Show a short summary of what changed in each one.
   - **Added**: a new file that isn't listed and isn't ignored. Propose a kind and scope.
   - **Removed**: listed but gone (or moved; match by content hash and name before calling it removed).
   - **Unclassified**: files found outside `docs/` that were never offered before, e.g. on projects set up before this command existed.
3. **Check shared docs for drift.** For each shared doc, and each product repo with a local path, compare it with the same file in the other repo (same relative path, else same file name). Report every copy that differs, with a summary of the difference. Don't pick a winner: ask which copy is current, record the answer, and suggest syncing the others. Never edit another repo.
4. **Ask** in one AskQuestion round: include or ignore each added and unclassified doc (with kind and scope), confirm removals, and resolve drift.
5. **Read** the added and changed docs in full.
6. **Propose the adjustments**, as one summary of what would change and why:
   - **`STANDARDS.md`**: rules added, changed, or removed, each citing its doc, following "How docs combine". In `existing` mode, re-check the observed conventions the changed docs touch.
   - **`requirements.md`** (`new` mode): new or changed requirements get new IDs; removed ones are marked removed, never renumbered. Set or update each requirement's owner if the product spans several repos.
   - **Architecture and backlog** (`new` mode): which sections of `architecture.md` and which backlog features are affected. New requirements owned by this repo become backlog features; requirements now owned by another repo leave the backlog for the cross-repo list.
   - **Plan alignment**: compare the plan docs with the team's plan (`BACKLOG.md`, `.dev-team/sprints/`, each feature's `tasks.md`). List the differences: work in a different sprint or order, work the plan marks done that the team hasn't delivered, and work the team delivered that the plan still shows open. Propose updates to the team's files. For the plan docs, propose the exact edits (e.g. tick these tasks in `tasks.md`).
   - **In-progress features** whose spec or design depends on a changed doc: recommend re-running `/team-plan` or `/team-architect` for them rather than editing approved artifacts.
7. **Approve.** Ask: Approve / Revise / Stop. On Approve, apply the changes to the team's artifacts, then update the Project docs table, Doc sources, Product repos, and `updated:` in `PROJECT.md`. Edit a plan doc only if the user approved that specific edit; never edit any other project doc.

## Status (`/team-docs status`)

Run Reconcile steps 2 and 3 and report the results, ending with the recommendation to run `/team-docs` if anything changed.
