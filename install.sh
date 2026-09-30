#!/bin/sh
# install.sh: put the skill where Claude Code looks for it, on this machine.
#
# Usage: install.sh            copy, check, and compare
#        install.sh --check    copy nothing; compare what is installed with this checkout
#
# Copies the three files under skill/ into ~/.claude/skills/handoff and touches
# nothing else there.  Creates ~/.claude/handoffs and, only if this machine has
# none, a limits.json holding the defaults from examples/.
#
# It never writes the machine label, a roster, a paths file, a rules file or a
# ledger.  Those are yours, and the last lines it prints say which are missing.
#
# After copying it runs the installed check.sh, then prints the sha256 of each
# installed file beside the same file in this checkout.  Exit status: 0 if the
# checks passed and every sum matches, else 1.
#
# Environment:
#     CLAUDE_CONFIG_DIR   where Claude Code keeps its files (default ~/.claude)
#     HANDOFF_HOME        the base directory (default ~/.claude/handoffs)

set -eu

REPO=$(cd "$(dirname "$0")" && pwd)
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/handoff"
BASE="${HANDOFF_HOME:-$HOME/.claude/handoffs}"
FILES="SKILL.md scripts/handoff scripts/check.sh"
MODE=${1:-install}

case "$MODE" in
    install|--check) ;;
    *) echo "usage: install.sh [--check]" >&2; exit 1 ;;
esac

sum() {  # sum FILE: its sha256, or the word missing
    if [ ! -f "$1" ]; then
        echo missing
    elif command -v sha256sum > /dev/null 2>&1; then
        sha256sum "$1" | cut -d' ' -f1
    else
        shasum -a 256 "$1" | cut -d' ' -f1
    fi
}

if [ "$MODE" = install ]; then
    mkdir -p "$DEST/scripts" "$BASE"
    for file in $FILES; do
        cp "$REPO/skill/$file" "$DEST/$file"
    done
    chmod +x "$DEST/scripts/handoff" "$DEST/scripts/check.sh"
    if [ ! -f "$BASE/limits.json" ]; then
        cp "$REPO/examples/limits.json" "$BASE/limits.json"
        echo "wrote $BASE/limits.json with the defaults; the ceilings are yours to set"
    fi
    "$DEST/scripts/check.sh" > "$BASE/.check.out" 2>&1 && CHECKS=passed || CHECKS=failed
    tail -1 "$BASE/.check.out"
    if [ "$CHECKS" = failed ]; then
        grep '^FAIL' "$BASE/.check.out" || true
    fi
    rm -f "$BASE/.check.out"
else
    CHECKS=passed
fi

SAME=yes
for file in $FILES; do
    here=$(sum "$REPO/skill/$file")
    there=$(sum "$DEST/$file")
    if [ "$here" = "$there" ]; then
        printf 'same     %s  %s\n' "$there" "$file"
    else
        SAME=no
        printf 'DIFFERS  %s  %s  (this checkout: %s)\n' "$there" "$file" "$here"
    fi
done

if [ -f "$DEST/roster.json" ]; then
    echo "note: $DEST/roster.json is left from an older install; the script no longer reads it"
fi
if [ ! -f "$BASE/machine" ]; then
    echo "missing: $BASE/machine; write this machine's label into it"
fi
if ! ls "$BASE"/*/roster.json > /dev/null 2>&1; then
    echo "missing: no project has a roster under $BASE; see README.md, Quick start"
fi

[ "$CHECKS" = passed ] && [ "$SAME" = yes ]
