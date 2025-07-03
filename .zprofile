# Add Homebrew to path
eval "$(/opt/homebrew/bin/brew shellenv)"

# Load Nix (multi-user install)
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
