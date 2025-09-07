# === Zsh Config ===

# Load direnv (project shell environments)
eval "$(direnv hook zsh)"

# Load starship prompt (modern prompt with git/path info)
eval "$(starship init zsh)"

# Set editor
export EDITOR="nvim"

# Add ~/bin to path if you use it
export PATH="$HOME/bin:$PATH"

# Aliases
alias ll='ls -lah'
alias dev='nix develop ~/dotfiles/dev-env'

# Optional: list files on cd
cd() { builtin cd "$@" && ls; }

# Load machine-specific overrides if they exist
if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi

# Open files or vaults in Obsidian
obs() {
  # If an argument is provided, open that file/vault. Otherwise, just open the app.
  open -a "Obsidian" "$1"
}