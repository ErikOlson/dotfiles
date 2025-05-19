#!/bin/bash
set -e

DOTFILES="$HOME/dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup"

mkdir -p "$HOME/.config"
mkdir -p "$BACKUP_DIR"

backup_and_link() {
    local src=$1
    local dest=$2
    local filename
    filename=$(basename "$dest")
    local backup_path="$BACKUP_DIR/$filename.backup.$(date +%Y%m%d%H%M%S)"

    # 🛡 Skip if already correctly symlinked
    if [ -L "$dest" ] && [ "$(readlink "$dest")" == "$src" ]; then
        echo "⚠️  $dest already symlinks to $src — skipping"
        return
    fi

    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "$backup_path"
        echo "💾 Backed up $dest to $backup_path"
    fi

    ln -sf "$src" "$dest"
    echo "🔗 Linked $src -> $dest"
}

echo "🔧 Symlinking config files with backups to $BACKUP_DIR..."
backup_and_link "$DOTFILES/.zprofile" "$HOME/.zprofile"
backup_and_link "$DOTFILES/.zshrc" "$HOME/.zshrc"
backup_and_link "$DOTFILES/config/nvim" "$HOME/.config/nvim"
backup_and_link "$DOTFILES/config/ghostty" "$HOME/.config/ghostty"

echo "🔒 Making .sh scripts executable..."
find "$DOTFILES" -type f -name "*.sh" -exec chmod +x {} \;

echo "✅ Setup script complete. Symlinks and permissions set."

