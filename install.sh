#!/usr/bin/env bash
# Links this repo's Claude Code config into ~/.claude, one entry at a time. ~/.claude itself
# stays a real directory: credentials, history and session transcripts live there and never
# end up inside the dotfiles. Every top-level file or folder git tracks here is linked, apart
# from the repo's own files (install.sh, README.md, .gitignore), so a CLAUDE.md, agents/ or
# commands/ added later is picked up without touching this script.
# Safe to re-run: what's already linked is skipped.
#
#   ./install.sh            create the links
#   ./install.sh --dry-run  only show what would happen
set -euo pipefail

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

run() {
    if ((DRY_RUN)); then
        echo "    would run: $*"
    else
        "$@"
    fi
}

# link <file in this repo> <destination>: a real file already there is moved aside, never
# overwritten; an existing link to somewhere else is just re-pointed
link() {
    local src="$1" dest="$2"
    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
        echo "$dest: already linked"
        return
    fi
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        echo "$dest: moving the existing one to $dest.bak"
        run mv "$dest" "$dest.bak"
    fi
    echo "$dest: linking to $src"
    run ln -sfn "$src" "$dest"
}

run mkdir -p "$CLAUDE_DIR"

# The top-level entries git tracks, each once (agents/a.md and agents/b.md give agents)
entries="$(git -C "$REPO" ls-files | cut -d/ -f1 | sort -u)"
while read -r entry; do
    case "$entry" in
        "" | install.sh | README.md | .gitignore) continue ;;
    esac
    link "$REPO/$entry" "$CLAUDE_DIR/$entry"
done <<<"$entries"

# Before this was a submodule, ~/.claude was itself a clone of claude-config. That clone
# would now see its tracked files turned into links, so point out that it can go.
if [[ -e "$CLAUDE_DIR/.git" ]]; then
    echo
    echo "Note: $CLAUDE_DIR is still a git clone of its own. The config now lives in $REPO,"
    echo "so once anything in that clone is pushed, remove its .git and .gitignore:"
    echo "    rm -rf $CLAUDE_DIR/.git $CLAUDE_DIR/.gitignore"
fi

echo
echo "Done. Running Claude Code sessions pick the settings up on their next start."
