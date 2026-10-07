# Working together with the same AI dev team

We stay aligned through **`main` only**. Your friend (and anyone else) only pulls
`main` — they do not need feature branches, sprint branches, or our local tool folders.

You need:

1. Access to the **dev-team** repo (contains `deploy.sh`).
2. Access to the **product** repo.
3. Cursor **or** Claude Code (both work).

---

## What lives on `main` (this is what we share)

Commit and push these to **`main`**:

| On `main` | Why |
|-----------|-----|
| `.dev-team/PROJECT.md` | Project profile |
| `.dev-team/STANDARDS.md` | Shared rulebook — same review bar for everyone |
| Other `.dev-team/` planning files (`accept/`, `audit/`, `sprints/`, feature specs, …) | Shared status and decisions |
| Product docs (`docs/`, `sprint.md`, `tasks.md`, …) | Source of truth |

**Not** on `main` (local only — deploy already keeps them out of git):

- `.cursor/skills/`, `.cursor/agents/`
- `.claude/skills/`, `.claude/agents/`
- `.dev-team/worktrees/`

Feature work (e.g. `sprint-2`) stays on its branch until someone merges it to **`main`**.
After that, a normal `git pull origin main` is enough for everyone.

---

## One-time setup

### Person who sets up first (once)

```bash
# 1. Same team version
cd /path/to/dev-team && git pull && cat VERSION

# 2. On product repo, on main
cd /path/to/product
git checkout main && git pull origin main
/path/to/dev-team/deploy.sh . --mode existing

# 3. Setup once (skip if .dev-team/STANDARDS.md already exists on main)
# In Cursor or Claude Code:
#   /team-onboard

# 4. Put the rulebook on main
git add .dev-team/PROJECT.md .dev-team/STANDARDS.md
git add .dev-team/    # anything else setup created; worktrees/ won't be added
git status           # confirm no .cursor/ or .claude/ team files are staged
git commit -m "Add shared dev-team rulebook"
git push origin main
```

### Everyone else (including your friend — `main` only)

```bash
cd /path/to/dev-team && git pull && cat VERSION   # same VERSION as the rest of us

cd /path/to/product
git checkout main
git pull origin main

/path/to/dev-team/deploy.sh . --mode existing
# Optional: --host cursor   or   --host claude
```

Then check:

- `.dev-team/PROJECT.md` and `.dev-team/STANDARDS.md` are present (from `main`).
- **Do not** re-run `/team-onboard` / `/team-kickoff` — that would fork the rulebook.
- In the editor, `/team` should see the shared setup.

When the team is upgraded: pull **dev-team**, note `VERSION`, re-run `deploy.sh` in the
product repo, then `git pull origin main` for any `.dev-team/` updates.

---

## Day-to-day (same commands in Cursor and Claude Code)

| Goal | Command |
|------|---------|
| Status | `/team` |
| Docs changed → then **commit to main** | `/team-docs` |
| Build something | `/team-plan …` → `/team run` → deliver **to main** (or PR into main) |
| Review & merge a branch **into main** | `/team-accept origin/<branch>` |
| After author pushes fixes | `/team-accept recheck …` then `merge …` |
| Validate work already on main | `/team-audit <sprint>` |

Type the command yourself — the team does not start on its own.

After any accept/audit/docs stage that updates `.dev-team/`, **commit and push to `main`**
so the next `git pull origin main` picks it up.

---

## Merging `sprint-2` when friends only pull `main`

`sprint-2` can stay on `origin/sprint-2`. Your friend never needs that branch.

**On your machine** (or whoever accepts):

```bash
git checkout main && git pull origin main
git fetch origin
```

```text
/team-accept origin/sprint-2
```

Approve review → merge into **`main`** (merge commit / squash / rebase, or open a PR
**into main**). Push `main` when you confirm.

Also commit any new `.dev-team/accept/…` files **on main** and push.

**Your friend:**

```bash
git checkout main
git pull origin main
```

They now have sprint-2 code + the shared accept record. No other branch required.

---

## Rules

1. **Shared truth is `main`.** Rulebook, accept/audit records, and delivered code land there.
2. **One rulebook.** Don’t each re-run setup; change docs → `/team-docs` → push to `main`.
3. **Same `VERSION`** of the dev-team repo before a shared accept or sprint.
4. **Pull `main` before** accept/build/docs so you see each other’s `.dev-team/` updates.
5. **Don’t push to the author’s branch** unless they ask; `/team-accept` doesn’t by default.

---

## Quick check

```bash
git branch --show-current    # should be main for day-to-day sync
git pull origin main
test -f .dev-team/PROJECT.md && test -f .dev-team/STANDARDS.md && echo "rulebook: ok"
test -f .cursor/skills/team/SKILL.md -o -f .claude/skills/team/SKILL.md && echo "skills: ok"
head -5 .dev-team/dev-team.manifest
```

| Symptom | Fix |
|---------|-----|
| `/team-*` missing | `deploy.sh` in this repo |
| Different rules | `git pull origin main`; same `VERSION` + redeploy |
| Friend missing sprint-2 | It isn’t on `main` yet — finish `/team-accept` and push `main` |
| Want team gone locally | `/path/to/dev-team/undeploy.sh .` (keeps `.dev-team/` on disk) |

More detail: `README.md` in the **dev-team** repo.
