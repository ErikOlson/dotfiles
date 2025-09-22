#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   docker-switch.sh [desktop|colima|toggle] [--force]
# Default is "toggle". "--force" escalates quits if Desktop won't exit gracefully.

TARGET="${1:-toggle}"
FORCE="${2:-}"                         # pass "--force" to allow hard-kill when stopping Desktop
STOP_WAIT_SECS="${STOP_WAIT_SECS:-10}" # graceful quit wait
DOCKER_TIMEOUT="${DOCKER_TIMEOUT:-180}"# daemon readiness wait (seconds)

have() { command -v "$1" >/dev/null 2>&1; }

# --- Desktop detection/launch helpers ---
desktop_is_running() { /usr/bin/pgrep -f "/Applications/Docker.app/Contents/MacOS/Docker" >/dev/null 2>&1; }

start_desktop() {
  # Launch by bundle id (robust), then foreground so prompts are visible
  open -b com.docker.docker || open -a "Docker" || open -a "Docker Desktop" || true
  osascript -e 'tell application id "com.docker.docker" to activate' >/dev/null 2>&1 || true
}

stop_desktop_graceful() {
  osascript -e 'quit app "Docker Desktop"' >/dev/null 2>&1 || true
  osascript -e 'quit app "Docker"'         >/dev/null 2>&1 || true
  for _ in $(seq 1 "$STOP_WAIT_SECS"); do
    desktop_is_running || return 0
    sleep 1
  done
  return 1
}

stop_desktop_hard() {
  pkill -x "Docker Desktop" >/dev/null 2>&1 || true
  pkill -x Docker           >/dev/null 2>&1 || true
  pkill -f "/Applications/Docker.app/Contents/MacOS/Docker" >/dev/null 2>&1 || true
  for _ in $(seq 1 5); do desktop_is_running || return 0; sleep 1; done
  return 1
}

# --- Colima helpers ---
stop_colima() { have colima && colima stop >/dev/null 2>&1 || true; }

start_colima() {
  have colima || { echo "Colima not installed (brew install colima)"; exit 1; }
  colima status >/dev/null 2>&1 || colima start
}

# --- Context sync (only call AFTER daemon is ready) ---
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

# --- Socket-based readiness checks (don’t depend on current docker context) ---
desktop_sock() { echo "$HOME/.docker/run/docker.sock"; }
colima_sock()  { echo "$HOME/.colima/${COLIMA_PROFILE:-default}/docker.sock"; }

wait_for_desktop() {
  local i=0 sock; sock="$(desktop_sock)"
  # wait for socket file to appear
  while [ $i -lt "$DOCKER_TIMEOUT" ]; do
    [ -S "$sock" ] && break
    sleep 1; i=$((i+1))
  done
  # then wait for daemon to respond on that socket
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
    DOCKER_HOST="unix://$sock" docker version >/dev/null 2;&1 && return 0
    sleep 1; i=$((i+1))
  done
  return 1
}

# --- Current backend (best-effort) ---
current_backend() {
  if desktop_is_running; then echo desktop
  elif have colima && colima status >/dev/null 2>&1; then echo colima
  else echo none; fi
}

# Resolve TARGET (toggle -> the other one; default to desktop if none)
if [[ "$TARGET" == "toggle" ]]; then
  CURR="$(current_backend)"
  if   [[ "$CURR" == "desktop" ]]; then TARGET="colima"
  elif [[ "$CURR" == "colima"  ]]; then TARGET="desktop"
  else TARGET="desktop"; fi
fi
if [[ "$TARGET" != "desktop" && "$TARGET" != "colima" ]]; then
  echo "Usage: $0 [desktop|colima|toggle] [--force]"; exit 2
fi

# capture previous context so we can restore on failure
PREV_CTX="$(docker context show 2>/dev/null || echo default)"

echo "🔀 Switching to: $TARGET"

if [[ "$TARGET" == "desktop" ]]; then
  stop_colima || true
  start_desktop
  if ! wait_for_desktop; then
    echo "⚠️  Docker Desktop didn’t come up in time."
    echo "   Tip: click the Docker icon in Launchpad/Finder to surface any first-run prompts."
    # don’t change context on failure; restore if it was changed elsewhere
    docker context use "$PREV_CTX" >/dev/null 2>&1 || true
    exit 1
  fi
  set_context_for_backend desktop
else
  # stop Desktop gracefully; escalate only if --force supplied
  if desktop_is_running; then
    if ! stop_desktop_graceful; then
      if [[ "$FORCE" == "--force" ]]; then
        stop_desktop_hard || true
      else
        echo "⚠️  Docker Desktop still running. Quit it or re-run with --force."
        docker context use "$PREV_CTX" >/dev/null 2>&1 || true
        exit 1
      fi
    fi
  fi
  start_colima
  if ! wait_for_colima; then
    echo "⚠️  Colima didn’t come up in time."
    docker context use "$PREV_CTX" >/dev/null 2>&1 || true
    exit 1
  fi
  set_context_for_backend colima
fi

echo "✅ Docker ready on $TARGET"

