# Shared helpers for deploy.sh and undeploy.sh. Must stay bash 3.2 compatible (macOS default).

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TEAM_DIR="$SRC_DIR/team"
STANDARDS_DIR="$SRC_DIR/standards"
VERSION="$(cat "$SRC_DIR/VERSION")"
MODES="new existing"
HOSTS_ALL="cursor claude"

EXCLUDE_BEGIN="# >>> dev-team (local only, managed by deploy.sh)"
EXCLUDE_END="# <<< dev-team"

die() { echo "error: $*" >&2; exit 1; }

file_hash() { shasum -a 256 "$1" | awk '{print $1}'; }

# Sets TARGET and MANIFEST from a project path (default: current directory).
# HOSTS is a space-separated list of hosts to deploy to (cursor, claude).
resolve_target() {
  local path="${1:-$PWD}"
  [ -d "$path" ] || die "$path is not a directory"
  TARGET="$(cd "$path" && pwd -P)"
  case "$TARGET" in
    "$SRC_DIR"|"$SRC_DIR"/*) die "refusing to use the dev-team source repo as a project" ;;
  esac
  [ "$TARGET" != "$(cd "$HOME" && pwd -P)" ] || die "refusing to use your home directory: ~/.cursor and ~/.claude are global and would enable the team in every project"
  [ "$TARGET" != "/" ] || die "refusing to use /"
  MANIFEST="$TARGET/.dev-team/dev-team.manifest"
  LEGACY_MANIFEST="$TARGET/.cursor/dev-team.manifest"
}

# Parse a --host value into HOSTS (space-separated). Default: both.
set_hosts() {
  case "${1:-both}" in
    both) HOSTS="$HOSTS_ALL" ;;
    cursor|claude) HOSTS="$1" ;;
    *) die "unknown host '$1' (use: cursor, claude, or both)" ;;
  esac
}

# Prints the recorded hash for a project-relative path (e.g. .cursor/skills/team/SKILL.md).
manifest_hash() {
  [ -f "$MANIFEST" ] || return 0
  awk -F'\t' -v p="$1" '!/^#/ && $2 == p { print $1 }' "$MANIFEST"
}

manifest_paths() {
  [ -f "$MANIFEST" ] || return 0
  awk -F'\t' '!/^#/ && NF == 2 { print $2 }' "$MANIFEST"
}

manifest_mode() {
  if [ -f "$MANIFEST" ]; then
    sed -n 's/^# mode: //p' "$MANIFEST" | head -1
  elif [ -f "$LEGACY_MANIFEST" ]; then
    sed -n 's/^# mode: //p' "$LEGACY_MANIFEST" | head -1
  fi
}

manifest_hosts() {
  if [ -f "$MANIFEST" ]; then
    sed -n 's/^# hosts: //p' "$MANIFEST" | head -1
  elif [ -f "$LEGACY_MANIFEST" ]; then
    echo "cursor"
  fi
}

# Migrates the pre-0.8.0 Cursor-only manifest into MANIFEST (paths prefixed with .cursor/).
# No-op if the new manifest already exists or there is no legacy file.
migrate_legacy_manifest() {
  [ -f "$MANIFEST" ] && return 0
  [ -f "$LEGACY_MANIFEST" ] || return 0
  mkdir -p "$(dirname "$MANIFEST")"
  {
    echo "# dev-team manifest. Managed by deploy.sh/undeploy.sh in $SRC_DIR. Do not edit."
    echo "# version: $(sed -n 's/^# version: //p' "$LEGACY_MANIFEST" | head -1)"
    echo "# mode: $(sed -n 's/^# mode: //p' "$LEGACY_MANIFEST" | head -1)"
    echo "# hosts: cursor"
    echo "# deployed: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "# migrated-from: .cursor/dev-team.manifest"
    awk -F'\t' '!/^#/ && NF == 2 { print $1 "\t.cursor/" $2 }' "$LEGACY_MANIFEST"
  } > "$MANIFEST"
  rm -f "$LEGACY_MANIFEST"
  prune_dirs "$LEGACY_MANIFEST"
  echo "Migrated legacy .cursor/dev-team.manifest -> .dev-team/dev-team.manifest"
}

# Prints "source<TAB>host-relative" for every file deployed in a mode.
# host-relative is e.g. skills/team/SKILL.md or agents/team-backend-engineer.md.
list_sources() {
  local mode="$1" base rel
  {
    for base in "$TEAM_DIR/common" "$TEAM_DIR/$mode"; do
      [ -d "$base" ] || continue
      (cd "$base" && find . -type f ! -name '.DS_Store' | sed 's|^\./||') |
        while IFS= read -r rel; do printf '%s\t%s\n' "$base/$rel" "$rel"; done
    done
    if [ -d "$STANDARDS_DIR" ]; then
      (cd "$STANDARDS_DIR" && find . -type f ! -name '.DS_Store' | sed 's|^\./||') |
        while IFS= read -r rel; do printf '%s\t%s\n' "$STANDARDS_DIR/$rel" "skills/team/standards/$rel"; done
    fi
  } | sort -t "$(printf '\t')" -k2
}

# Prints "source<TAB>project-relative" for every (host × source) to deploy.
# project-relative is e.g. .cursor/skills/team/SKILL.md.
list_deploy_entries() {
  local mode="$1" host src rel
  for host in $HOSTS; do
    list_sources "$mode" | while IFS="$(printf '\t')" read -r src rel; do
      printf '%s\t.%s/%s\n' "$src" "$host" "$rel"
    done
  done
}

# Removes now-empty parent directories of a file, never going above the project root.
prune_dirs() {
  local d
  d="$(dirname "$1")"
  while [ "$d" != "$TARGET" ] && [ "${d#"$TARGET"/}" != "$d" ]; do
    rmdir "$d" 2>/dev/null || break
    d="$(dirname "$d")"
  done
}

# Sets GIT_EXCLUDE (path to the repo's info/exclude) and GIT_PREFIX (project path inside the repo).
# Returns 1 if the project is not inside a git repository.
resolve_git_exclude() {
  GIT_EXCLUDE=""; GIT_PREFIX=""
  command -v git >/dev/null 2>&1 || return 1
  GIT_EXCLUDE="$(git -C "$TARGET" rev-parse --git-path info/exclude 2>/dev/null)" || return 1
  case "$GIT_EXCLUDE" in /*) ;; *) GIT_EXCLUDE="$TARGET/$GIT_EXCLUDE" ;; esac
  GIT_EXCLUDE="$(cd "$(dirname "$(dirname "$GIT_EXCLUDE")")" && pwd)/info/exclude"
  GIT_PREFIX="$(git -C "$TARGET" rev-parse --show-prefix 2>/dev/null)"
}

has_exclude_block() {
  [ -f "$GIT_EXCLUDE" ] && grep -qxF "$EXCLUDE_BEGIN" "$GIT_EXCLUDE"
}

remove_exclude_block() {
  has_exclude_block || return 0
  local tmp
  tmp="$(mktemp)"
  awk -v b="$EXCLUDE_BEGIN" -v e="$EXCLUDE_END" '$0 == b { skip = 1; next } $0 == e { skip = 0; next } !skip' "$GIT_EXCLUDE" > "$tmp"
  cat "$tmp" > "$GIT_EXCLUDE"
  rm -f "$tmp"
}

# Writes the managed exclude block. Worktrees are always hidden. In existing mode,
# Cursor/Claude Code team files are hidden too; planning files under .dev-team/
# (PROJECT.md, STANDARDS.md, accept/, …) are left visible so colleagues can share them.
add_exclude_block() {
  local mode="$1" host
  remove_exclude_block
  mkdir -p "$(dirname "$GIT_EXCLUDE")"
  {
    echo "$EXCLUDE_BEGIN"
    echo "/${GIT_PREFIX}.dev-team/worktrees/"
    if [ "$mode" = "existing" ]; then
      for host in $HOSTS_ALL; do
        echo "/${GIT_PREFIX}.${host}/skills/team/"
        echo "/${GIT_PREFIX}.${host}/skills/team-*/"
        echo "/${GIT_PREFIX}.${host}/agents/team-*.md"
        echo "/${GIT_PREFIX}.${host}/dev-team.manifest"
      done
    fi
    echo "$EXCLUDE_END"
  } >> "$GIT_EXCLUDE"
}

# Prints dev-team worktrees registered with git for this project, one path per line.
list_team_worktrees() {
  git -C "$TARGET" worktree list --porcelain 2>/dev/null |
    sed -n 's/^worktree //p' | grep -F "$TARGET/.dev-team/worktrees/" || true
}

# Prints the project's .md files relative to TARGET, the same set /team-docs scans:
# git-ignored files are skipped in a git repo, common dependency and build folders otherwise.
list_project_docs() {
  (
    cd "$TARGET"
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git ls-files -co --exclude-standard -- '*.md' '*.MD'
    else
      find . \( -name node_modules -o -name .git -o -name vendor -o -name dist -o -name build \
        -o -name .venv -o -name venv -o -name __pycache__ -o -name target \) -prune \
        -o -type f \( -name '*.md' -o -name '*.MD' \) -print | sed 's|^\./||'
    fi
  ) | grep -v -e '^\.dev-team/' -e '^\.cursor/' -e '^\.claude/' | sort || true
}

# Prints lines from stdin with a two-space indent, at most $1 of them, then a count of the rest.
print_capped() {
  awk -v max="$1" 'NR <= max { print "  " $0 } END { if (NR > max) print "  ... and " NR - max " more" }'
}
