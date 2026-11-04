#!/usr/bin/env bash
# Install or update the EG (elephant/goldfish) workflow into a project.
#
#   ./install.sh <target-project-dir>            first install; never overwrites existing files
#   ./install.sh <target-project-dir> --update   also overwrites EG-owned files with this template's version
#
# EG-owned (overwritten by --update): .github/eg/protocol.md, .github/eg/packs/general.md,
#   .github/agents/elephant.agent.md, .github/agents/goldfish-general-*.agent.md,
#   .github/skills/eg-*/SKILL.md, and the EG block in .github/copilot-instructions.md.
# Project-owned (never overwritten): .github/eg/profile.md, other packs and goldfish, everything else.

set -euo pipefail

usage() { echo "usage: $0 <target-project-dir> [--update]" >&2; exit 2; }

[ $# -ge 1 ] || usage
TARGET=$1
UPDATE=0
if [ $# -ge 2 ]; then
  [ "$2" = "--update" ] || usage
  UPDATE=1
fi
[ -d "$TARGET" ] || { echo "error: target directory not found: $TARGET" >&2; exit 1; }

SRC=$(cd "$(dirname "$0")" && pwd)
TARGET=$(cd "$TARGET" && pwd)
[ "$SRC" != "$TARGET" ] || { echo "error: target is the template itself" >&2; exit 1; }

BEGIN_MARK='<!-- EG:BEGIN -->'
END_MARK='<!-- EG:END -->'

installed=(); updated=(); unchanged=(); conflicts=(); kept=()

eg_owned_files() {
  cd "$SRC"
  echo ".github/eg/protocol.md"
  echo ".github/eg/packs/general.md"
  echo ".github/agents/elephant.agent.md"
  ls .github/agents/goldfish-general-*.agent.md
  ls .github/skills/eg-*/SKILL.md
}

copy_owned() {
  local rel=$1 src="$SRC/$1" dst="$TARGET/$1"
  if [ ! -e "$dst" ]; then
    mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"; installed+=("$rel")
  elif cmp -s "$src" "$dst"; then
    unchanged+=("$rel")
  elif [ $UPDATE -eq 1 ]; then
    cp "$src" "$dst"; updated+=("$rel")
  else
    conflicts+=("$rel")
  fi
}

for rel in $(eg_owned_files); do copy_owned "$rel"; done

# Project-owned profile: install only if absent.
PROFILE=".github/eg/profile.md"
if [ -e "$TARGET/$PROFILE" ]; then
  kept+=("$PROFILE")
else
  mkdir -p "$(dirname "$TARGET/$PROFILE")"; cp "$SRC/$PROFILE" "$TARGET/$PROFILE"; installed+=("$PROFILE")
fi

# EG block in copilot-instructions.md: create, append, or replace in place.
INSTR=".github/copilot-instructions.md"
BLOCK_FILE=$(mktemp)
trap 'rm -f "$BLOCK_FILE"' EXIT
awk -v b="$BEGIN_MARK" -v e="$END_MARK" '$0==b{on=1} on{print} $0==e{on=0}' "$SRC/$INSTR" > "$BLOCK_FILE"
[ -s "$BLOCK_FILE" ] || { echo "error: EG block not found in template $INSTR" >&2; exit 1; }

dst="$TARGET/$INSTR"
if [ ! -e "$dst" ]; then
  mkdir -p "$(dirname "$dst")"; cp "$BLOCK_FILE" "$dst"; installed+=("$INSTR (EG block)")
elif grep -qxF "$BEGIN_MARK" "$dst"; then
  grep -qxF "$END_MARK" "$dst" || { echo "error: $INSTR has $BEGIN_MARK without $END_MARK; fix it by hand" >&2; exit 1; }
  tmp=$(mktemp)
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" -v f="$BLOCK_FILE" '
    $0==b { while ((getline line < f) > 0) print line; skip=1; next }
    $0==e { skip=0; next }
    !skip { print }' "$dst" > "$tmp"
  if cmp -s "$tmp" "$dst"; then rm -f "$tmp"; unchanged+=("$INSTR (EG block)")
  elif [ $UPDATE -eq 1 ]; then mv "$tmp" "$dst"; updated+=("$INSTR (EG block)")
  else rm -f "$tmp"; conflicts+=("$INSTR (EG block)")
  fi
else
  { [ -s "$dst" ] && [ -n "$(tail -c1 "$dst")" ] && echo; echo; cat "$BLOCK_FILE"; } >> "$dst"
  installed+=("$INSTR (EG block appended)")
fi

# .gitignore entry for elephant working files.
GI="$TARGET/.gitignore"
if [ -e "$GI" ] && grep -qxE '/?\.eg-work/?' "$GI"; then
  unchanged+=(".gitignore (.eg-work/)")
else
  { [ -s "$GI" ] && [ -n "$(tail -c1 "$GI")" ] && echo; echo ".eg-work/"; } >> "$GI"
  installed+=(".gitignore (.eg-work/)")
fi

report() {
  local title=$1; shift
  [ $# -gt 0 ] || return 0
  echo "$title"
  local x; for x in "$@"; do echo "  $x"; done
}

echo "EG install into $TARGET"
report "installed:" ${installed[@]+"${installed[@]}"}
report "updated:" ${updated[@]+"${updated[@]}"}
report "unchanged:" ${unchanged[@]+"${unchanged[@]}"}
report "kept (project-owned):" ${kept[@]+"${kept[@]}"}
if [ ${#conflicts[@]} -gt 0 ]; then
  report "skipped (differs from template; rerun with --update to overwrite):" "${conflicts[@]}"
fi
echo
echo "Next: open the project in VS Code, select the 'elephant' agent, and run /eg-setup."
