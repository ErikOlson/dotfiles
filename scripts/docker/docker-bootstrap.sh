#!/usr/bin/env bash
set -euo pipefail

# docker-bootstrap.sh
# Helper for portable Docker env: add aliases, detect backend,
# optionally start and wait (socket-based), then sync CLI context.
#
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

# --- Desktop helpers ---
desktop_is_running() { /usr/bin/pgrep -f "/Applications/Docker.app/Contents/MacOS/Docker" >/dev/null 2>&1; }
desktop_app_present() { [ -d "/Applications/Docker.app" ] || [ -d "$HOME/Applications/Docker.app" ]; }
desktop_sock() { echo "$HOME/.docker/run/docker.sock"; }

start_desktop() {
  # Launch by bundle id (robust) and bring to foreground so prompts are visible
  open -b com.docker.docker || open -a "Docker" || open -a "Docker Desktop" || true
  osascript -e 'tell application id "com.docker.docker" to activate' >/dev/null 2>&1 || true
}

wait_for_desktop() {
  local i=0 sock; sock="$(desktop_sock)"
  log -n "⏳ Waiting for Docker Desktop (timeout ${TIMEOUT}s)"
  # wait until socket appears
  while [ $i -lt "$TIMEOUT" ]; do
    [ -S "$sock" ] && break
    [ "$QUIET" -eq 0 ] && printf "."
    sleep 1; i=$((i+1))
  done
  # then wait until daemon on that socket responds
  while [ $i -lt "$TIMEOUT" ]; do
    DOCKER_HOST="unix://$sock" docker version >/dev/null 2>&1 && { [ "$QUIET" -eq 0 ] && echo ""; return 0; }
    [ "$QUIET" -eq 0 ] && printf "."
    sleep 1; i=$((i+1))
  done
  [ "$QUIET" -eq 0 ] && echo ""
  log "⚠️  Timed out waiting for Docker Desktop."
  return 1
}

# --- Colima helpers ---
colima_sock()  { echo "$HOME/.colima/${COLIMA_PROFILE:-default}/docker.sock"; }

start_colima() {
  log "🐳 Starting Colima..."
  have colima || { log "ℹ️  Colima not installed. brew install colima"; return 1; }
  colima status >/dev/null 2>&1 || colima start
}

wait_for_colima() {
  local i=0 sock; sock="$(colima_sock)"
  log -n "⏳ Waiting for Colima (timeout ${TIMEOUT}s)"
  while [ $i -lt "$TIMEOUT" ]; do
    [ -S "$sock" ] && break
    [ "$QUIET" -eq 0 ] && printf "."
    sleep 1; i=$((i+1))
  done
  while [ $i -lt "$TIMEOUT" ]; do
    DOCKER_HOST="unix://$sock" docker version >/dev/null 2>&1 && { [ "$QUIET" -eq 0 ] && echo ""; return 0; }
    [ "$QUIET" -eq 0 ] && printf "."
    sleep 1; i=$((i+1))
  done
  [ "$QUIET" -eq 0 ] && echo ""
  log "⚠️  Timed out waiting for Colima."
  return 1
}

# --- Context sync (call only AFTER daemon is ready) ---
set_context_for_backend() {
  have docker || return 0
  case "$1" in
    desktop)
      if docker context ls --format '{{.Name}}' | grep -qx 'desktop-linux'; then
        docker context use desktop-linux >/dev/null 2>&1 || true
      else
        docker context use default >/dev/null 2>&1 || true
      fi
      ;;
    colima)
      if docker context ls --format '{{.Name}}' | grep -qx 'colima'; then
        docker context use colima >/dev/null 2>&1 || true
      fi
      ;;
  esac
}

choose_backend() {
  case "$BACKEND" in
    desktop|colima) echo "$BACKEND"; return;;
    auto|"")
      if desktop_is_running || desktop_app_present; then
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

maybe_add_aliases() {
  [ "$ADD_ALIASES" -eq 1 ] || return 0
  local z="$HOME/.zshrc"
  grep -q "# --- docker dotfiles aliases ---" "$z" 2>/dev/null && return 0
  cat >> "$z" <<'ZRC'

# --- docker dotfiles aliases ---
alias docker-desktop='open -b com.docker.docker || open -a Docker'
alias docker-colima-start='colima start'
alias docker-colima-stop='colima stop'
alias docker-which-backend='
  if /usr/bin/pgrep -f "/Applications/Docker.app/Contents/MacOS/Docker" >/dev/null 2>&1; then
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
    -h|--help) sed -n '1,200p' "$0"; exit 0;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

maybe_add_aliases

CHOSEN="$(choose_backend)"
log "backend: $CHOSEN"

if [ "$DO_START" -eq 1 ]; then
  case "$CHOSEN" in
    desktop)
      start_desktop
      if wait_for_desktop; then
        set_context_for_backend desktop
        log "✅ Docker Desktop is ready."
      else
        log "💡 Tip: open Docker Desktop from Launchpad/Finder to surface any first-run prompts."
        exit 1
      fi
      ;;
    colima)
      if start_colima && wait_for_colima; then
        set_context_for_backend colima
        log "✅ Colima is ready."
      else
        exit 1
      fi
      ;;
    none)
      log "ℹ️  No Docker backend found. Install Docker Desktop (cask) or Colima (brew)."
      exit 0
      ;;
  esac
fi

