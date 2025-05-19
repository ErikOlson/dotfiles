#!/bin/bash
set -e

echo "🚀 Starting bootstrap process..."

# --- Homebrew ---
if ! command -v brew >/dev/null 2>&1; then
    echo "🧪 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Ensure Homebrew is available in this shell
    eval "$(/opt/homebrew/bin/brew shellenv)"

    # Add to .zprofile if not already present
    if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        echo "✅ Added Homebrew to .zprofile"
    else
        echo "ℹ️  Homebrew shellenv already present in .zprofile"
    fi
else
    echo "✅ Homebrew already installed."
fi

# --- Nix ---
if ! command -v nix >/dev/null 2>&1; then
    echo "🧪 Installing Nix..."
    curl -L https://nixos.org/nix/install | sh

    # Try sourcing the environment immediately
    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        echo "🔄 Sourcing Nix environment into current shell..."
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    else
        echo "⚠️  Nix profile not found — open a new terminal session if needed."
    fi
else
    echo "✅ Nix already installed."
fi

# --- Install Brewfile packages ---
echo "📦 Installing Brewfile packages..."
brew bundle --file="$HOME/dotfiles/Brewfile"

# --- Symlink configs and set script permissions ---
"$HOME/dotfiles/setup.sh"

# --- Enable direnv-based global dev shell ---
if command -v direnv >/dev/null 2>&1; then
    if ! grep -Fxq 'use flake ~/dotfiles/dev-env' "$HOME/.envrc" 2>/dev/null; then
        echo "💡 Writing .envrc for global flake..."
        echo 'use flake ~/dotfiles/dev-env' > "$HOME/.envrc"
        direnv allow ~
    else
        echo "ℹ️  .envrc already configured for global flake"
    fi
else
    echo "⚠️  direnv not found — skipping .envrc setup."
fi

echo "✅ Bootstrap complete. You may want to restart your terminal or source ~/.zprofile."

