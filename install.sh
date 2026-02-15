#!/usr/bin/env bash
# install.sh — Symlink workflow scripts to ~/.local/bin/
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$BIN_DIR"

for script in "$REPO_DIR"/bin/*; do
    name=$(basename "$script")
    target="$BIN_DIR/$name"

    if [[ -e "$target" && ! -L "$target" ]]; then
        echo "  Backing up existing $target → ${target}.bak"
        mv "$target" "${target}.bak"
    fi

    ln -sf "$script" "$target"
    echo "  $name → $target"
done

echo ""
echo "Done. Add this line to ~/.config/tmux/tmux.conf (before the TPM run line):"
echo ""
echo "  source-file ~/Documents/code/tmux-personal-ai-config/tmux-workflow.conf"
