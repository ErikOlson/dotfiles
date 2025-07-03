#!/bin/bash
set -e

echo "🚀 Starting bootstrap process..."

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
    echo "🧪 Installing Nix (multi-user)..."
    curl -L https://nixos.org/nix/install | sh
else
    echo "✅ Nix already installed."
fi

# --- Ensure nix is sourced in .zprofile ---
if ! grep -q 'nix-daemon.sh' "$HOME/.zprofile"; then
    echo "🔧 Adding Nix environment to .zprofile..."
    {
      echo ''
      echo '# Load Nix (multi-user install)'
      echo 'if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then'
      echo '  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      echo 'fi'
    } >> "$HOME/.zprofile"
else
    echo "ℹ️  Nix already present in .zprofile"
fi

# --- Load Nix into current shell ---
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

