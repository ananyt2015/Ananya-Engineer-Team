#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Remove the dev team from a project.

Usage: undeploy.sh [project-path] [--force] [--dry-run]

  project-path  Project to remove the team from. Default: current directory.
  --force       Also remove files you edited locally in the project, and undeploy
                even if build worktrees still exist (they are left in place).
  --dry-run     Show what would be removed without deleting anything.

Only files recorded in <project>/.dev-team/dev-team.manifest are touched
(or the legacy <project>/.cursor/dev-team.manifest). Feature artifacts in
<project>/.dev-team/ other than the manifest are never deleted.
EOF
}

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

force=0
dry=0
target_arg=""
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    --dry-run) dry=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) usage >&2; die "unknown option: $arg" ;;
    *) [ -z "$target_arg" ] || die "only one project path allowed"; target_arg="$arg" ;;
  esac
done

resolve_target "$target_arg"

if [ -f "$MANIFEST" ]; then
  :
elif [ -f "$LEGACY_MANIFEST" ]; then
  if [ "$dry" -eq 1 ]; then
    echo "(dry run: would migrate .cursor/dev-team.manifest -> .dev-team/dev-team.manifest)"
    # Temporary view of legacy paths so dry-run can list removals.
    MANIFEST="$(mktemp)"
    trap 'rm -f "$MANIFEST"' EXIT
    awk -F'\t' '!/^#/ && NF == 2 { print $1 "\t.cursor/" $2 }' "$LEGACY_MANIFEST" > "$MANIFEST"
  else
    migrate_legacy_manifest
  fi
else
  die "dev-team is not deployed in $TARGET (no .dev-team/dev-team.manifest)"
fi

[ -f "$MANIFEST" ] || die "dev-team is not deployed in $TARGET"

active_worktrees="$(list_team_worktrees)"
if [ -n "$active_worktrees" ] && [ "$force" -eq 0 ]; then
  echo "These dev-team build worktrees still exist and may hold undelivered work:" >&2
  printf '%s\n' "$active_worktrees" | sed 's/^/  /' >&2
  die "deliver or remove them first (git worktree remove <path>), or re-run with --force to undeploy anyway"
fi

echo "Removing dev-team from $TARGET"
[ "$dry" -eq 1 ] && echo "(dry run: nothing will be deleted)"
echo

removed=0; kept=0
while IFS= read -r rel; do
  dest="$TARGET/$rel"
  [ -e "$dest" ] || continue
  if [ "$(file_hash "$dest")" = "$(manifest_hash "$rel")" ] || [ "$force" -eq 1 ]; then
    if [ "$dry" -eq 0 ]; then rm -f "$dest"; prune_dirs "$dest"; fi
    printf '  %-10s %s\n' remove "$rel"; removed=$((removed + 1))
  else
    printf '  %-10s %s\n' KEPT "$rel (edited in this project; --force to remove)"; kept=$((kept + 1))
  fi
done < <(manifest_paths)

if [ "$dry" -eq 0 ]; then
  rm -f "$MANIFEST"
  prune_dirs "$MANIFEST"
  [ -f "$LEGACY_MANIFEST" ] && rm -f "$LEGACY_MANIFEST" && prune_dirs "$LEGACY_MANIFEST"
fi

if resolve_git_exclude && has_exclude_block; then
  if [ -n "$active_worktrees" ]; then
    echo "  kept       git exclude block, so the remaining build worktrees stay hidden from git"
  else
    [ "$dry" -eq 1 ] || remove_exclude_block
    echo "  removed    dev-team block from $GIT_EXCLUDE"
  fi
fi

echo
echo "Removed $removed, kept $kept."
[ -d "$TARGET/.dev-team" ] && echo "Feature artifacts in .dev-team/ were left in place. Delete or move them if git should not see them."
exit 0
