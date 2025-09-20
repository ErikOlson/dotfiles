#!/bin/bash
set -euo pipefail

DOTFILES="${HOME}/dotfiles"
BACKUP_DIR="${HOME}/.dotfiles_backup"

mkdir -p "${HOME}/.config"
mkdir -p "${BACKUP_DIR}"

backup_and_link() {
  local src="$1"
  local dest="$2"
  local filename backup_path
  filename="$(basename "$dest")"
  backup_path="${BACKUP_DIR}/${filename}.backup.$(date +%Y%m%d%H%M%S)"

  # 🛡 Skip if already correctly symlinked
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "⚠️  $dest already symlinks to $src — skipping"
    return
  fi

  # Backup existing non-symlink (file/dir)
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mv "$dest" "$backup_path"
    echo "💾 Backed up $dest to $backup_path"
  fi

  # -n: do not follow symlink if dest is a symlink to a dir
  ln -sfn "$src" "$dest"
  echo "🔗 Linked $src -> $dest"
}

echo "🔧 Symlinking config files with backups to ${BACKUP_DIR}..."
backup_and_link "${DOTFILES}/.zprofile"                "${HOME}/.zprofile"
backup_and_link "${DOTFILES}/.zshrc"                   "${HOME}/.zshrc"
backup_and_link "${DOTFILES}/.envrc"                   "${HOME}/.envrc"
backup_and_link "${DOTFILES}/config/nvim"              "${HOME}/.config/nvim"
backup_and_link "${DOTFILES}/config/ghostty"           "${HOME}/.config/ghostty"
backup_and_link "${DOTFILES}/config/starship.toml"     "${HOME}/.config/starship.toml"

echo "🔒 Making .sh scripts executable..."
find "${DOTFILES}" -type f -name "*.sh" -exec chmod +x {} \;

echo
echo "📄 Final symlink status:"
ls -l "${HOME}/.zprofile" "${HOME}/.zshrc" "${HOME}/.envrc" \
      "${HOME}/.config/nvim" "${HOME}/.config/ghostty" "${HOME}/.config/starship.toml" 2>/dev/null || true

# 🐳 Docker: add aliases & print backend (no auto-start during setup)
# Requires: scripts/docker/docker-bootstrap.sh (from our earlier step)
DOCKER_HELPERS="${DOTFILES}/scripts/docker"
if [ -x "${DOCKER_HELPERS}/docker-bootstrap.sh" ]; then
  "${DOCKER_HELPERS}/docker-bootstrap.sh" --backend "${DOCKER_BACKEND:-auto}" || true
fi

echo "✅ Setup script complete. Symlinks, permissions, and Docker aliases ready."

