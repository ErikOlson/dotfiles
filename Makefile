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

# --- Docker Targets ---
DOCKER_HELPERS := ./scripts/docker
DOCKER_BACKEND ?= auto   # override like: make DOCKER_BACKEND=colima docker-up

.PHONY: docker-up docker-down docker-down-force docker-backend docker-switch docker-switch-to-desktop docker-switch-to-colima docker-switch-to-colima-force docker-toggle

docker-up:
	@$(DOCKER_HELPERS)/docker-bootstrap.sh --backend $(DOCKER_BACKEND) --start --timeout 90

docker-down:
	@# graceful quit Desktop (both names) + brief wait
	@osascript -e 'quit app "Docker Desktop"' >/dev/null 2>&1 || true
	@osascript -e 'quit app "Docker"' >/dev/null 2>&1 || true
	@i=0; while /usr/bin/pgrep -f "/Applications/Docker.app/Contents/MacOS/Docker" >/dev/null 2>&1 && [ $$i -lt 10 ]; do sleep 1; i=$$((i+1)); done
	@# stop Colima gracefully
	@command -v colima >/dev/null 2>&1 && colima stop >/dev/null 2>&1 || true
	@echo "Docker backends: graceful stop requested"

docker-down-force:
	@osascript -e 'quit app "Docker Desktop"' >/dev/null 2>&1 || true
	@osascript -e 'quit app "Docker"' >/dev/null 2>&1 || true
	@pkill -x "Docker Desktop" >/dev/null 2>&1 || true
	@pkill -x Docker >/dev/null 2>&1 || true
	@pkill -f "/Applications/Docker.app/Contents/MacOS/Docker" >/dev/null 2>&1 || true
	@command -v colima >/dev/null 2>&1 && colima stop >/dev/null 2>&1 || true
	@echo "Docker backends: FORCE stop requested"

docker-backend:
	@/bin/echo -n "backend: "; \
	if /usr/bin/pgrep -f "Docker Desktop.app" >/dev/null 2>&1; then echo desktop; \
	elif command -v colima >/dev/null 2>&1 && colima status >/dev/null 2>&1; then echo colima; \
	else echo none; fi

# Parameterized switch (requires: make docker-switch TARGET=desktop|colima)
docker-switch:
	@case "$(TARGET)" in desktop|colima) ;; \
	  *) echo "Usage: make docker-switch TARGET=desktop|colima"; exit 2;; \
	esac
	@$(DOCKER_HELPERS)/docker-switch.sh $(TARGET)

# Clear, explicit switchers
docker-switch-to-desktop:
	@$(DOCKER_HELPERS)/docker-switch.sh desktop

docker-switch-to-colima:
	@$(DOCKER_HELPERS)/docker-switch.sh colima

docker-switch-to-colima-force:
	@$(DOCKER_HELPERS)/docker-switch.sh colima --force

# Auto-toggle to "the other" backend (no script changes needed)
docker-toggle:
	@CURR=none; \
	if /usr/bin/pgrep -f "Docker Desktop.app" >/dev/null 2>&1; then CURR=desktop; \
	elif command -v colima >/dev/null 2>&1 && colima status >/dev/null 2>&1; then CURR=colima; fi; \
	if [ "$$CURR" = "desktop" ]; then TARGET=colima; \
	elif [ "$$CURR" = "colima" ]; then TARGET=desktop; \
	else TARGET="$(DOCKER_BACKEND)"; [ "$$TARGET" = "auto" ] && TARGET=desktop; fi; \
	echo "Switching $$CURR -> $$TARGET"; \
	$(DOCKER_HELPERS)/docker-switch.sh $$TARGET

.PHONY: docker-context docker-context-use-desktop docker-context-use-colima docker-sync-context

docker-context:
	@echo -n "context: "; docker context show

docker-context-use-desktop:
	@docker context use desktop-linux 2>/dev/null || docker context use default

docker-context-use-colima:
	@docker context use colima

# Ensure context matches the active backend
docker-sync-context:
	@if /usr/bin/pgrep -f "Docker Desktop.app" >/dev/null 2>&1; then \
		echo "sync: desktop → context desktop-linux/default"; \
		docker context use desktop-linux 2>/dev/null || docker context use default; \
	elif command -v colima >/dev/null 2>&1 && colima status >/dev/null 2>&1; then \
		echo "sync: colima → context colima"; \
		docker context use colima; \
	else \
		echo "sync: no backend running"; \
	fi

.PHONY: docker-status
docker-status:
	@BACKEND=none; \
	if /usr/bin/pgrep -f "Docker Desktop.app" >/dev/null 2>&1; then BACKEND=desktop; \
	elif command -v colima >/dev/null 2>&1 && colima status >/dev/null 2>&1; then BACKEND=colima; fi; \
	CONTEXT=$$(docker context show 2>/dev/null || echo none); \
	echo "backend: $$BACKEND"; \
	echo "context: $$CONTEXT"; \
	if [ "$$BACKEND" = desktop ] && [ "$$CONTEXT" != desktop-linux ] && [ "$$CONTEXT" != default ]; then \
	  echo "(!) mismatch: CLI is not pointed at Desktop"; \
	fi; \
	if [ "$$BACKEND" = colima ] && [ "$$CONTEXT" != colima ]; then \
	  echo "(!) mismatch: CLI is not pointed at Colima"; \
	fi

