#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Deploy the dev team into a project (copies files into <project>/.cursor/ and/or .claude/).

Usage: deploy.sh [project-path] --mode new|existing [--host cursor|claude|both] [--force] [--dry-run]

  project-path      Project to deploy into. Default: current directory.
  --mode new        Starting from scratch: kickoff from PRD + SRS, my standards are law.
                    Team files can be committed to the project.
  --mode existing   Joining a running project: onboard to its codebase and conventions,
                    which win over my standards. Skill folders stay out of git via
                    .git/info/exclude (local only). Commit .dev-team/ planning files so
                    colleagues stay aligned; worktrees are always ignored.
  --host both       Install for Cursor and Claude Code (default). Colleagues on either tool
                    get the same team. Use --host cursor or --host claude to install one.
  --force           Overwrite files you edited locally in the project.
  --dry-run         Show what would change without writing anything.

--mode is required on first deploy. Re-run without it to update a project
to the latest team in its current mode; pass it to switch modes.
EOF
}

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

force=0
dry=0
mode=""
host_arg="both"
target_arg=""
while [ $# -gt 0 ]; do
  case "$1" in
    --force) force=1 ;;
    --dry-run) dry=1 ;;
    --mode) [ $# -ge 2 ] || die "--mode needs a value: new or existing"; mode="$2"; shift ;;
    --mode=*) mode="${1#--mode=}" ;;
    --host) [ $# -ge 2 ] || die "--host needs a value: cursor, claude, or both"; host_arg="$2"; shift ;;
    --host=*) host_arg="${1#--host=}" ;;
    -h|--help) usage; exit 0 ;;
    -*) usage >&2; die "unknown option: $1" ;;
    *) [ -z "$target_arg" ] || die "only one project path allowed"; target_arg="$1" ;;
  esac
  shift
done

resolve_target "$target_arg"
[ -d "$TEAM_DIR/common" ] || die "team definitions not found at $TEAM_DIR/common"

if [ "$dry" -eq 0 ]; then
  migrate_legacy_manifest
fi

previous_mode="$(manifest_mode)"
if [ -z "$mode" ]; then
  [ -n "$previous_mode" ] || { usage >&2; echo >&2; die "first deploy to this project: choose --mode new or --mode existing"; }
  mode="$previous_mode"
fi
case " $MODES " in *" $mode "*) ;; *) die "unknown mode '$mode' (use: $MODES)" ;; esac

# Default --host both installs for Cursor and Claude Code. Pass --host cursor or
# --host claude to install only one (removes the other host's team files on update).
set_hosts "$host_arg"

new_manifest="$(mktemp)"
entries="$(mktemp)"
entry_rels="$(mktemp)"
trap 'rm -f "$new_manifest" "$entries" "$entry_rels"' EXIT

list_deploy_entries "$mode" > "$entries"
cut -f2 "$entries" > "$entry_rels"
dupe="$(sort "$entry_rels" | uniq -d | head -1)"
[ -z "$dupe" ] || die "two source files map to the same destination: $dupe"

installed=0; updated=0; unchanged=0; skipped=0; removed=0

report() { printf '  %-10s %s\n' "$1" "$2"; }

copy_file() {
  [ "$dry" -eq 1 ] && return 0
  mkdir -p "$(dirname "$2")"
  cp "$1" "$2"
}

echo "Deploying dev-team v$VERSION ($mode mode; hosts: $HOSTS) -> $TARGET"
[ -n "$previous_mode" ] && [ "$previous_mode" != "$mode" ] && echo "Switching mode: $previous_mode -> $mode"
[ "$dry" -eq 1 ] && echo "(dry run: nothing will be written)"
echo

while IFS="$(printf '\t')" read -r src rel; do
  dest="$TARGET/$rel"
  new="$(file_hash "$src")"
  old="$(manifest_hash "$rel")"

  if [ ! -e "$dest" ]; then
    copy_file "$src" "$dest"; report install "$rel"; installed=$((installed + 1))
    printf '%s\t%s\n' "$new" "$rel" >> "$new_manifest"
    continue
  fi

  cur="$(file_hash "$dest")"
  if [ "$cur" = "$new" ]; then
    unchanged=$((unchanged + 1))
    printf '%s\t%s\n' "$new" "$rel" >> "$new_manifest"
  elif { [ -n "$old" ] && [ "$cur" = "$old" ]; } || [ "$force" -eq 1 ]; then
    copy_file "$src" "$dest"; report update "$rel"; updated=$((updated + 1))
    printf '%s\t%s\n' "$new" "$rel" >> "$new_manifest"
  elif [ -n "$old" ]; then
    report KEPT "$rel (edited in this project; --force to overwrite)"; skipped=$((skipped + 1))
    printf '%s\t%s\n' "$old" "$rel" >> "$new_manifest"
  else
    report KEPT "$rel (not created by dev-team; --force to overwrite)"; skipped=$((skipped + 1))
  fi
done < "$entries"

# Files deployed earlier that this mode/host set no longer includes.
while IFS= read -r rel; do
  grep -qxF "$rel" "$entry_rels" && continue
  dest="$TARGET/$rel"
  [ -e "$dest" ] || continue
  if [ "$(file_hash "$dest")" = "$(manifest_hash "$rel")" ] || [ "$force" -eq 1 ]; then
    if [ "$dry" -eq 0 ]; then rm -f "$dest"; prune_dirs "$dest"; fi
    report remove "$rel"; removed=$((removed + 1))
  else
    report KEPT "$rel (no longer part of the team but edited here; now yours)"; skipped=$((skipped + 1))
  fi
done < <(manifest_paths)

if [ "$dry" -eq 0 ]; then
  mkdir -p "$(dirname "$MANIFEST")"
  {
    echo "# dev-team manifest. Managed by deploy.sh/undeploy.sh in $SRC_DIR. Do not edit."
    echo "# version: $VERSION"
    echo "# mode: $mode"
    echo "# hosts: $HOSTS"
    echo "# deployed: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    cat "$new_manifest"
  } > "$MANIFEST"
  # Drop the legacy Cursor-only manifest if a migration left it behind somehow.
  [ -f "$LEGACY_MANIFEST" ] && rm -f "$LEGACY_MANIFEST" && prune_dirs "$LEGACY_MANIFEST"
fi

echo
echo "Installed $installed, updated $updated, unchanged $unchanged, kept $skipped, removed $removed."

git_note=""
if resolve_git_exclude; then
  [ "$dry" -eq 1 ] || add_exclude_block "$mode"
  if [ "$mode" = "existing" ]; then
    git_note="Skill folders are hidden from git via $GIT_EXCLUDE (local only). Commit .dev-team/ planning files (not worktrees/) so colleagues stay aligned."
  else
    git_note="Build worktrees (.dev-team/worktrees/) are hidden from git via $GIT_EXCLUDE; team files and other .dev-team/ docs can be committed."
  fi
else
  git_note="Not a git repository: nothing hidden from version control, and builds will run without worktree isolation."
fi

if [ -f "$TARGET/.dev-team/PROJECT.md" ]; then
  project_mode="$(sed -n 's/^mode: //p' "$TARGET/.dev-team/PROJECT.md" | head -1)"
  if [ -n "$project_mode" ] && [ "$project_mode" != "$mode" ]; then
    echo
    echo "warning: .dev-team/PROJECT.md was written for '$project_mode' mode. Re-run project setup (/team-kickoff or /team-onboard)."
  fi
fi

[ "$dry" -eq 1 ] && exit 0
echo
[ -n "$git_note" ] && echo "$git_note"
all_docs="$(list_project_docs)"
docs_in_docs="$(printf '%s\n' "$all_docs" | grep '^docs/' || true)"
docs_elsewhere="$(printf '%s\n' "$all_docs" | grep -v -e '^docs/' -e '^$' || true)"
count() { [ -n "$1" ] && printf '%s\n' "$1" | wc -l | tr -d ' ' || echo 0; }
hosts_msg=""
case " $HOSTS " in *" cursor "*) hosts_msg="${hosts_msg:+$hosts_msg or }Cursor" ;; esac
case " $HOSTS " in *" claude "*) hosts_msg="${hosts_msg:+$hosts_msg or }Claude Code" ;; esac
hosts_msg=" ($hosts_msg)"
if [ "$mode" = "new" ]; then
  if [ -n "$docs_in_docs" ]; then
    echo "Project docs in docs/ that /team-kickoff will read ($(count "$docs_in_docs")):"
    printf '%s\n' "$docs_in_docs" | print_capped 30
  else
    echo "warning: no .md files in $TARGET/docs/. Put the PRD, SRS, and docs shared across"
    echo "         repos (e.g. manifest.md) there; /team-kickoff will ask if it can't find them."
  fi
  if [ -n "$docs_elsewhere" ]; then
    echo "Other .md files in the repo; /team-kickoff will ask which are project docs ($(count "$docs_elsewhere")):"
    printf '%s\n' "$docs_elsewhere" | print_capped 15
  fi
  echo
  echo "Next$hosts_msg: /team-kickoff"
else
  if [ -n "$all_docs" ]; then
    echo ".md files in the repo; /team-onboard will ask which to use ($(count "$all_docs")):"
    printf '%s\n' "$all_docs" | print_capped 15
    echo
  fi
  echo "Next$hosts_msg: /team-onboard (it will ask which project docs you have; none is fine)"
fi
echo "Later, when docs change: /team-docs"
echo "Remove with: $SRC_DIR/undeploy.sh $TARGET"
