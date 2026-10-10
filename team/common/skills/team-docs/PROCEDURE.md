# /team-docs procedure

Read by `team-analyst`, one phase at a time. `/team-kickoff` and `/team-onboard` use the `discover` phase.

## Common

You keep the team's understanding of the project in step with the project's own docs, wherever they live. Projects often keep product-wide docs (PRD, SRS, manifest) in `docs/`, synced across several repos, while docs that only make sense for one repo (its database, its sprint plan, its task list) stay elsewhere in that repo. You never edit the docs themselves.

**Kinds.** Every doc gets one or more:
- **requirements**: what to build (PRD, SRS, user stories, feature specs)
- **standard**: rules for how to build it (e.g. `databases.md`, `manifest.md`, API conventions, naming, deployment, security policy, design system)
- **plan**: the user's own plan and progress (e.g. `sprint.md`, `tasks.md`, a roadmap): which work belongs to which sprint, in what order, and what is done
- **reference**: context with no rules (research, glossary, meeting notes)
- **ignored**: not a project doc (changelogs, licences, a package's README, test fixtures)

**Scope.** **shared** (the same doc exists in the product's other repos, usually synced copies of the PRD, SRS, manifest) or **repo** (specific to this repo).

**How docs combine** (refines FLOW.md → "Which source wins"):
- Repo docs refine shared docs for this repo. Both apply.
- Real contradictions get asked, never assumed. The answer goes under "Decisions" in `STANDARDS.md`, with the doc that should probably change.
- Plan docs decide what and when (sprint, order, done). They never override requirements or standards. Plan work no requirement covers, or that contradicts one: ask.
- Requirements belong to repos. Work owned by another repo never enters this repo's backlog; it is a cross-repo dependency with the agreed contract.

**Scanning.** In a git repo: `git ls-files -co --exclude-standard -- '*.md' '*.MD'`. Otherwise `find . -name '*.md'`, pruning `node_modules`, `.git`, `vendor`, `dist`, `build`, `.venv`, `venv`, `__pycache__`, `target`. Always skip `.dev-team/` (except `.dev-team/docs/`), `.cursor/` and `.claude/`. Also note `.pdf`, `.docx` and `.txt` under `docs/`; convert `.docx` with `textutil -convert txt "<file>" -output /tmp/<name>.txt`. Short hash: `shasum -a 256 <file> | cut -c1-8`.

## Phase: discover

For setup (`/team-kickoff`, `/team-onboard`). OUTPUT: `.dev-team/setup/discovery.md`.
1. Scan. Group the files: `docs/`, the repo root, other folders. Skim each one (title, headings, first lines only) and propose a kind and scope with a one-line reason. Propose **ignored** for changelogs, licences, codes of conduct, issue and PR templates, and READMEs of individual packages or vendored code. In `existing` mode, a PR template or `CONTRIBUTING.md` is a **standard**. Also list `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, `.claude/rules/`, ADRs and `.github/` templates.
2. Product repos: if the docs mention other repos, or the same docs appear synced elsewhere, the product spans several repos. Note which, and where they might be checked out (sibling folders).
3. Write `discovery.md`: the grouped table (path, proposed kind, scope, reason) and the product-repos guess.
4. Return NEEDS-INPUT with one round:
   - Which docs to use: a multi-select per group with your recommendation. `new` mode: recommend everything under `docs/`, and files elsewhere only when they look like project docs.
   - Kind or scope of any doc you're unsure of.
   - Product repos (which, what each owns, local paths), if it applies.
   - `existing` mode also: other docs outside the repo (paths) or to paste; and "No docs — learn from the code".
   - `existing` mode also: may the team run the read-only checks (test, lint, typecheck) and prove a worktree setup (creates and removes a temporary worktree, may install dependencies from the lockfile)?

## Phase: scan

For `/team-docs` and `/team-docs status`. OUTPUT: `.dev-team/setup/docs-scan.md`.
1. Scan, then compare with `PROJECT.md` → Project docs and Doc sources:
   - **Changed**: the hash differs. Summarise what changed in each (headings and the changed sections only).
   - **Added**: a new file that isn't listed and isn't ignored. Propose a kind and scope.
   - **Removed**: listed but gone (or moved: match by content hash and name before calling it removed).
   - **Unclassified**: files outside `docs/` never offered before.
2. **Drift.** For each shared doc and each product repo with a local path, compare it with the same file there (same relative path, else same name). Report every copy that differs, with a summary. Don't pick a winner. Never edit another repo.
3. Write `docs-scan.md`. If nothing changed, reply DONE saying so. Otherwise, unless NOTES say `status`, return NEEDS-INPUT in one round: include or ignore each added and unclassified doc (with kind and scope), confirm removals, which copy is current for each drift.

## Phase: propose

INPUTS: `docs-scan.md`, the answers. OUTPUT: `.dev-team/setup/docs-proposal.md`.
1. Read the added and changed docs in full.
2. Write the proposed adjustments, each with why:
   - **`STANDARDS.md`**: rules added, changed or removed, each citing its doc. `existing` mode: re-check the observed conventions the changed docs touch.
   - **`requirements.md`** (`new` mode): new or changed requirements get new IDs; removed ones are marked removed, never renumbered. Owner per requirement if several repos.
   - **Architecture and backlog** (`new` mode): affected sections of `architecture.md` and backlog features. New requirements owned by this repo become backlog features; requirements now owned by another repo move to the cross-repo list.
   - **Plan alignment**: compare the plan docs with `BACKLOG.md`, `.dev-team/sprints/` and each feature's `tasks.md` or `pipeline.md`. List work in a different sprint or order, work the plan marks done that the team hasn't delivered, and work delivered that the plan still shows open. Propose updates to the team's files, and the exact edits for plan docs.
   - **In-progress features** whose spec or design depends on a changed doc: recommend rerunning their spec or design step (`/team-run <slug> only spec`).
3. SUMMARY: the proposal in 8 lines or fewer.

## Phase: apply

INPUTS: `docs-proposal.md`, the user's approval (and which plan-doc edits they approved) in NOTES.
Apply the approved changes to the team's artifacts, then update `PROJECT.md` → Project docs (hashes), Doc sources, Product repos, and `updated:`. Edit a plan doc only for an edit the user approved; never edit any other project doc. The changed `PROJECT.md` and `STANDARDS.md` hashes make the next `/team-run` rebuild `.dev-team/context/`.
