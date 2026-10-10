# Changelog

## 0.10.0 — 2026-10-10

Rebuilt the team around a conductor and fresh agents to stop runaway token use and stalled runs.

**Why.** v0.9 runs used up to about 150M tokens. Most of one 11-hour session (about 8 hours) was spent locked out by
Claude usage limits. The main sinks were a lead chat that read every spec, design and diff; about 41k tokens of tool
and skill listings in every subagent; full test and build output in engineer sessions; comment passes over whole
codebases; and approval stops at every stage.

**Pipeline**
- `/team-run` is the main entry point: a conductor that keeps only `pipeline.md`, frontmatter and short agent
  reports, and runs every step in a fresh subagent with paths, not contents.
- Tracks: `quick` (small changes, picked automatically), `light`, `full`. The tech lead confirms or escalates.
- One planned stop, at delivery. A short FYI after the design. `gated` restores the spec and design approvals.
- Up to 4 engineers build in parallel (`Max parallel engineers`); verifiers merge one at a time.
- At most 25 agents per chat; then the conductor says how to resume.
- Stage commands (`/team-plan` … `/team-qa`) are thin wrappers for `/team-run <slug> only <step>`.

**Usage limits and switching tools**
- State is written before every agent starts, so a limit or crash loses nothing.
- `pipeline.md` records the holding conductor (`cursor-…` or `claude-…`) and a heartbeat. Stale holds (30 minutes)
  are taken over; running steps rerun as a new attempt in a new worktree and branch.
- Agents check their attempt before committing or merging and stop with `SUPERSEDED` if it was replaced.

**Comments**
- Engineers write only why-comments while building.
- At delivery the user is asked whether to comment the touched functions. Yes: new `team-commenter` agent, then a
  verifier commit. No: a `## Deferred` entry in `BACKLOG.md` listing the touched files and functions (not on the quick
  track).

**Agents**
- New: `team-commenter`, `team-analyst` (runs one `PROCEDURE.md` phase at a time).
- Every agent has a `tools:` allowlist (Claude Code; Cursor ignores it), so subagents no longer load every MCP server
  and skill listing. Playwright tools only for the UI/UX engineer and QA.
- Context rules and tool-call budgets in every agent: `rg`, line-range reads, `tail -n 40`, handoff notes of 40 lines
  or fewer, reports of 15 lines or fewer.
- Reviewer, security reviewer and QA also serve `/team-accept` and `/team-audit` (`MODE: accept | audit`).

**Commands converted to agents**
- `/team-onboard`, `/team-kickoff`, `/team-docs`, `/team-accept`, `/team-audit`, `/team-rca`: a thin `SKILL.md` asks
  and approves in the chat; `team-analyst` and the review agents do the reading and writing.

**Deploy**
- New `team/hosts/<host>/` for host-only files: `.cursor/rules/dev-team.mdc` and `.claude/CLAUDE.md`, an
  always-loaded rule that routes work through `/team-run`. A project's own `.claude/CLAUDE.md` is never overwritten.
- Existing mode hides these files from git too.

**Upgrading a project from 0.9**
- Redeploy. Projects set up by 0.9 keep working: `/team-run` adopts existing feature folders. Re-running setup is
  optional but adds `Max parallel engineers` to `PROJECT.md` (default 4 when missing).
- If you created `.cursor/rules/dev-team.mdc` or `.claude/CLAUDE.md` by hand, delete them (or use `--force` for the
  `.mdc`) so deploy can manage them.
