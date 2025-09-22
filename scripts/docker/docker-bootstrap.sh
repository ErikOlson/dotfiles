#!/usr/bin/env bash
set -euo pipefail

# docker-bootstrap.sh
# Helper for portable Docker env: add aliases, detect backend, optionally start and wait.
# Usage:
#   scripts/docker/docker-bootstrap.sh [--backend desktop|colima|auto] [--start] [--timeout SECS] [--no-aliases] [--quiet]
#
# Env:
#   DOCKER_BACKEND=desktop|colima|auto   (default: auto)

BACKEND="${DOCKER_BACKEND:-auto}"
TIMEOUT=60
ADD_ALIASES=1
QUIET=0
DO_START=0

log() { [ "$QUIET" -eq 0 ] && echo "$@"; }
have() { command -v "$1" >/dev/null 2>&1; }

choose_backend() {
  case "$BACKEND" in
    desktop|colima) echo "$BACKEND"; return;;
    auto|"")
      if /usr/bin/pgrep -f "Docker Desktop.app" >/dev/null 2>&1 || [ -d "/Applications/Docker.app" ]; then
        echo "desktop"; return
      fi
      if have colima; then
        echo "colima"; return
      fi
      echo "none"; return
      ;;
    *) echo "none"; return;;
  esac
}

start_desktop() {
  # Launch & bring to front so first-run prompts are visible
  open -a "Docker" || open -a "Docker Desktop" || true
  osascript -e 'tell application "Docker" to activate' >/dev/null 2>&1 || \
  osascript -e 'tell application "Docker Desktop" to activate' >/dev/null 2>&1 || true
}
start_colima()   { log "🐳 Starting Colima..."; colima status >/dev/null 2>&1 || colima start; }

wait_for_docker() {
  local i=0
  log -n "⏳ Waiting for Docker daemon (timeout ${TIMEOUT}s)"
  while [ $i -lt "$TIMEOUT" ]; do
    if have docker && docker info >/dev/null 2>&1; then
      log ""
      log "✅ Docker is ready."
      return 0
    fi
    [ "$QUIET" -eq 0 ] && printf "."
    sleep 1
    i=$((i+1))
  done
  log ""
  log "⚠️  Timed out waiting for Docker."
  return 1
}

maybe_add_aliases() {
  [ "$ADD_ALIASES" -eq 1 ] || return 0
  local z="$HOME/.zshrc"
  grep -q "# --- docker dotfiles aliases ---" "$z" 2>/dev/null && return 0
  cat >> "$z" <<'ZRC'

# --- docker dotfiles aliases ---
alias docker-desktop='open -a Docker'
alias docker-colima-start='colima start'
alias docker-colima-stop='colima stop'
alias docker-which-backend='
  if /usr/bin/pgrep -f "Docker Desktop.app" >/dev/null 2>&1; then
    echo "desktop"
  elif command -v colima >/dev/null 2>&1 && colima status >/dev/null 2>&1; then
    echo "colima"
  else
    echo "none"
  fi
'
ZRC
  log "🧩 Added Docker aliases to ~/.zshrc"
}

# --- args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --backend) BACKEND="${2:-auto}"; shift 2;;
    --timeout) TIMEOUT="${2:-60}"; shift 2;;
    --no-aliases) ADD_ALIASES=0; shift;;
    --start) DO_START=1; shift;;
    --quiet) QUIET=1; shift;;
    -h|--help) sed -n '1,80p' "$0"; exit 0;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

maybe_add_aliases

CHOSEN="$(choose_backend)"
log "backend: $CHOSEN"

if [ "$DO_START" -eq 1 ]; then
  case "$CHOSEN" in
    desktop) start_desktop ;;
    colima)
      if ! have colima; then
        log "ℹ️  Colima not installed. Install with 'brew install colima' or use --backend desktop."
        exit 0
      fi
      start_colima
      ;;
    none)
      log "ℹ️  No Docker backend found. Install Docker Desktop (cask) or Colima (brew)."
      exit 0
      ;;
  esac
  have docker && wait_for_docker || true
fi

