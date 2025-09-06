.PHONY: all bootstrap setup dev versions update clean doctor lint backup brew flake

# --- Primary flow ---
all: bootstrap

bootstrap:
	./bootstrap.sh

setup:
	./setup.sh

dev:
	nix develop ~/dotfiles/dev-env

# --- Package management ---

brew:
	@echo "🍺 Updating Homebrew bundle..."
	brew bundle --file=~/dotfiles/Brewfile
	@echo "✅ Homebrew packages installed/updated."

flake:
	cd ~/dotfiles/dev-env && nix --extra-experimental-features 'nix-command flakes' flake update
	@echo "❄️ Flake updated."

update: brew flake
	@echo "✅ System packages updated (brew + nix flake)."

clean:
	nix-collect-garbage -d
	@echo "🧹 Cleaned up unused Nix packages."

# --- Utility targets (versions, health, lint, backup) ---
versions:
	@echo "🧪 Tool versions in current shell:"
	@which go && go version
	@which rustc && rustc --version
	@which zig && zig version
	@which odin && odin version
	@which node && node -v
	@which python3 && python3 --version
	@which clang && clang --version | head -n 1
	@which g++ && g++ --version | head -n 1

doctor:
	@echo "🩺 Checking environment..."
	@command -v brew >/dev/null || echo "❌ Homebrew not found"
	@command -v nix >/dev/null || echo "❌ Nix not found"
	@command -v direnv >/dev/null || echo "❌ direnv not found"
	@test -f ~/.zshrc && echo "✅ .zshrc present" || echo "❌ .zshrc missing"
	@test -f ~/.zprofile && echo "✅ .zprofile present" || echo "❌ .zprofile missing"
	@test -f ~/.envrc && echo "✅ .envrc present" || echo "❌ .envrc missing"
	@direnv status | grep "Found RC file" || echo "⚠️  direnv not active in this shell"
	@which odin && odin version || echo "⚠️  odin not found (expected in nix dev shell)"

lint:
	@echo "🔍 Linting dotfiles setup..."
	@shellcheck ./bootstrap.sh
	@shellcheck ./setup.sh
	@echo "✅ Scripts pass shellcheck (or warnings shown above)."

backup:
	@echo "📦 Backing up existing dotfiles to ~/.dotfiles_backup..."
	@mkdir -p ~/.dotfiles_backup
	@for file in .zshrc .zprofile .envrc; do \
		if [ -e "$$HOME/$$file" ] && [ ! -L "$$HOME/$$file" ]; then \
			cp "$$HOME/$$file" "$$HOME/.dotfiles_backup/$$file.backup.$$(date +%Y%m%d%H%M%S)"; \
			echo "💾 Backed up $$file"; \
		fi \
	done

