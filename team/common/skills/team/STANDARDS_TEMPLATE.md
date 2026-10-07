# `.dev-team/STANDARDS.md` template

Used by `/team-kickoff` and `/team-onboard`. Keep rules to one line each and point to the source doc for detail instead of copying it. Omit sections with no rules; add project-specific sections when a doc covers a topic not listed (e.g. a "Manifest" section from `docs/manifest.md`).

```markdown
---
feature: project
stage: standards
status: draft
mode: <new | existing>
updated: <YYYY-MM-DD>
---

# Standards for <project>

## Sources
| Priority | Source | Kind |
|----------|--------|------|
| 1 | `docs/databases.md` | project doc |
| 2 | `skills/team/standards/coding.md` | my global standard |
| 3 | code observation | observed (existing mode) |

## Rules

### Stack
### Project structure
### Naming
### Database
### API
### Code style and types
### Comments and documentation
<!-- Docstring/comment format (e.g. Google-style, TSDoc), required headers, language. The team always comments per COMMENTING.md; this section sets the style. -->
### Error handling and logging
### Security
### AI / LLM
### UI/UX
### Testing
### Git and workflow
### Definition of done

<!-- Rule format, one per line:
- <Imperative rule.> — `<source>` (§ <section>)
Observed conventions in existing mode add a confidence tag:
- Services are classes injected via `app/container.py`. — observed in `app/services/*.py` [high]
-->

## Adjustments to my global standards
| Topic | My standard says | This project does | Source |
|-------|------------------|-------------------|--------|

## Decisions
- <YYYY-MM-DD> <Conflict that was resolved with the user, and the answer>

## Not specified
- <Topic with no rule> — <who decides: the architect per feature, or ask the user>
```
