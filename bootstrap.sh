#!/bin/bash
set -e

echo "🚀 Starting bootstrap process..."

# --- OS Detection ---
OS="$(uname)"
case "$OS" in
  Darwin)
    echo "🖥️  macOS detected"
    ;;
  Linux)
    echo "⚠️  Linux detected — this script doesn't yet support Linux. Exiting."
    # TODO: Add Linux support in the future
    exit 1
    ;;
  MINGW* | MSYS* | CYGWIN* | Windows_NT)
    echo "❌ Windows is not supported by this bootstrap script."
    exit 1
    ;;
  *)
    echo "❓ Unknown OS: $OS — exiting for safety."
    exit 1
    ;;
esac

# --- Shell check ---
echo "🕵️  Detected shell: $SHELL"
if [[ "$SHELL" != */zsh ]]; then
  echo "⚠️  Warning: This setup is optimized for Zsh, not $SHELL"
fi

# --- Homebrew ---
if ! command -v brew >/dev/null 2>&1; then
    echo "🧪 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
else
    echo "✅ Homebrew already installed."
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- Nix ---
if ! command -v nix >/dev/null 2>&1; then
    echo "🧪 Installing Nix (multi-user, no profile modification)..."
    curl -L https://nixos.org/nix/install | sh -s -- --no-modify-profile
else
    echo "✅ Nix already installed."
fi

# --- Check if .zprofile is configured for Nix ---
ZPROFILE="$HOME/.zprofile"
if [ ! -f "$ZPROFILE" ]; then
    echo "⚠️  No .zprofile found in home directory."
    echo "🔧 You may need to run setup.sh to symlink your dotfiles version."
elif ! grep -q 'nix-daemon.sh' "$ZPROFILE"; then
    echo "⚠️  .zprofile exists but does not include Nix sourcing."
    echo "👉  Please update your dotfiles/.zprofile or re-run setup.sh to apply it."
else
    echo "✅ Nix sourcing found in .zprofile"
fi

# --- Load Nix into current shell (helpful right after install) ---
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# --- Install Brewfile packages ---
if [ -f "$HOME/dotfiles/Brewfile" ]; then
    echo "📦 Installing Brewfile packages..."
    brew bundle --file="$HOME/dotfiles/Brewfile"
else
    echo "⚠️  No Brewfile found at ~/dotfiles/Brewfile"
fi

# --- Symlink configs and set permissions ---
if [ -x "$HOME/dotfiles/setup.sh" ]; then
    echo "🔗 Running dotfile setup script..."
    "$HOME/dotfiles/setup.sh"
else
    echo "⚠️  No executable setup.sh found in ~/dotfiles"
fi

# --- Setup direnv global flake ---
if command -v direnv >/dev/null 2>&1; then
    if ! grep -Fxq 'use flake ~/dotfiles/dev-env' "$HOME/.envrc" 2>/dev/null; then
        echo "💡 Writing .envrc for global flake..."
        echo 'use flake ~/dotfiles/dev-env' > "$HOME/.envrc"
        direnv allow ~
    else
        echo "ℹ️  .envrc already configured"
    fi
else
    echo "⚠️  direnv not found — skipping .envrc setup."
fi

echo "✅ Bootstrap complete. Restart your terminal or run: exec $SHELL -l"

