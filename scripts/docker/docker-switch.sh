#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   docker-switch.sh [desktop|colima|toggle] [--force]
# Default is "toggle". "--force" escalates quits if Desktop won't exit gracefully.

TARGET="${1:-toggle}"
FORCE="${2:-}"
STOP_WAIT_SECS="${STOP_WAIT_SECS:-10}"
DOCKER_TIMEOUT="${DOCKER_TIMEOUT:-180}"

have() { command -v "$1" >/dev/null 2>&1; }
desktop_is_running() { /usr/bin/pgrep -f "/Applications/Docker.app/Contents/MacOS/Docker" >/dev/null 2>&1; }

# --- Prompts (GUI via AppleScript, fallback to TTY) ---
prompt_open_desktop() {
  # Try GUI dialog; ignore errors if AppleScript unavailable
  osascript -e 'display dialog "Please OPEN Docker Desktop (Launchpad → Docker) and allow any prompts.\n\nClick Continue once Docker says it is running." buttons {"Continue"} default button "Continue"' >/dev/null 2>&1 || true
  # Also try to launch (harmless if already open)
  open -b com.docker.docker >/dev/null 2>&1 || open -a "Docker" >/dev/null 2>&1 || open -a "Docker Desktop" >/dev/null 2>&1 || true
  # TTY fallback
  if [ -t 0 ]; then
    echo "👉 Please OPEN Docker Desktop, then press [Enter] to continue…"
    read -r _ || true
  fi
}

prompt_quit_desktop() {
  osascript -e 'display dialog "Please QUIT Docker Desktop (Docker → Quit).\n\nClick Continue after it has quit." buttons {"Continue"} default button "Continue"' >/dev/null 2>&1 || true
  if [ -t 0 ]; then
    echo "👉 Please QUIT Docker Desktop now, then press [Enter] to continue…"
    read -r _ || true
  fi
}

# --- Colima helpers ---
stop_colima() { have colima && colima stop >/dev/null 2>&1 || true; }
start_colima() {
  have colima || { echo "Colima not installed (brew install colima)"; exit 1; }
  colima status >/dev/null 2>&1 || colima start
}
colima_sock()  { echo "$HOME/.colima/${COLIMA_PROFILE:-default}/docker.sock"; }

# --- Desktop socket helpers ---
desktop_sock() { echo "$HOME/.docker/run/docker.sock"; }

# --- Waits (socket-based; don’t depend on current context) ---
wait_for_desktop() {
  local i=0 sock; sock="$(desktop_sock)"
  while [ $i -lt "$DOCKER_TIMEOUT" ]; do
    [ -S "$sock" ] && break
    sleep 1; i=$((i+1))
  done
  while [ $i -lt "$DOCKER_TIMEOUT" ]; do
    DOCKER_HOST="unix://$sock" docker version >/dev/null 2>&1 && return 0
    sleep 1; i=$((i+1))
  done
  return 1
}
wait_for_colima() {
  local i=0 sock; sock="$(colima_sock)"
  while [ $i -lt "$DOCKER_TIMEOUT" ]; do
    [ -S "$sock" ] && break
    sleep 1; i=$((i+1))
  done
  while [ $i -lt "$DOCKER_TIMEOUT" ]; do
    DOCKER_HOST="unix://$sock" docker version >/dev/null 2>&1 && return 0
    sleep 1; i=$((i+1))
  done
  return 1
}

# --- Context sync (only AFTER daemon is ready) ---
set_context_for_backend() {
  command -v docker >/dev/null 2>&1 || return 0
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

# --- Current backend ---
current_backend() {
  if desktop_is_running; then echo desktop
  elif have colima && colima status >/dev/null 2>&1; then echo colima
  else echo none; fi
}

# Resolve target
if [[ "$TARGET" == "toggle" ]]; then
  CURR="$(current_backend)"
  if   [[ "$CURR" == "desktop" ]]; then TARGET="colima"
  elif [[ "$CURR" == "colima"  ]]; then TARGET="desktop"
  else TARGET="desktop"; fi
fi
if [[ "$TARGET" != "desktop" && "$TARGET" != "colima" ]]; then
  echo "Usage: $0 [desktop|colima|toggle] [--force]"; exit 2
fi

# Capture previous context to restore on failure
PREV_CTX="$(docker context show 2>/dev/null || echo default)"

echo "🔀 Switching to: $TARGET"

if [[ "$TARGET" == "desktop" ]]; then
  stop_colima || true
  prompt_open_desktop
  if ! wait_for_desktop; then
    echo "⚠️  Docker Desktop did not become ready in ${DOCKER_TIMEOUT}s."
    echo "   Open it from Launchpad/Finder and try again."
    docker context use "$PREV_CTX" >/dev/null 2>&1 || true
    exit 1
  fi
  set_context_for_backend desktop
else
  if desktop_is_running; then
    # Ask the user to quit; escalate only with --force
    prompt_quit_desktop
    if desktop_is_running; then
      if [[ "$FORCE" == "--force" ]]; then
        pkill -x "Docker Desktop" >/dev/null 2>&1 || true
        pkill -x Docker         >/dev/null 2>&1 || true
        pkill -f "/Applications/Docker.app/Contents/MacOS/Docker" >/dev/null 2>&1 || true
      else
        echo "⚠️  Docker Desktop still running. Re-run with '--force' to kill it, or quit it manually."
        docker context use "$PREV_CTX" >/dev/null 2>&1 || true
        exit 1
      fi
    fi
  fi
  start_colima
  if ! wait_for_colima; then
    echo "⚠️  Colima did not become ready in ${DOCKER_TIMEOUT}s."
    docker context use "$PREV_CTX" >/dev/null 2>&1 || true
    exit 1
  fi
  set_context_for_backend colima
fi

echo "✅ Docker ready on $TARGET"

