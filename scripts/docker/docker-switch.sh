#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   docker-switch.sh [desktop|colima|toggle] [--force]
# Default is "toggle". "--force" escalates quits if Desktop won't exit gracefully.

TARGET="${1:-toggle}"
FORCE=${2:-}
STOP_WAIT_SECS="${STOP_WAIT_SECS:-10}"

have() { command -v "$1" >/dev/null 2>&1; }
desktop_is_running() { /usr/bin/pgrep -f "/Applications/Docker.app/Contents/MacOS/Docker" >/dev/null 2>&1; }

stop_desktop_graceful() {
  osascript -e 'quit app "Docker Desktop"' >/dev/null 2>&1 || true
  osascript -e 'quit app "Docker"' >/dev/null 2>&1 || true
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

stop_colima() { have colima && colima stop >/dev/null 2>&1 || true; }

start_desktop() {
  # Launch & bring to front so first-run prompts are visible
  open -a "Docker" || open -a "Docker Desktop" || true
  osascript -e 'tell application "Docker" to activate' >/dev/null 2>&1 || \
  osascript -e 'tell application "Docker Desktop" to activate' >/dev/null 2>&1 || true
}

start_colima(){
  have colima || { echo "Colima not installed (brew install colima)"; exit 1; }
  colima status >/dev/null 2>&1 || colima start
}

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

current_backend() {
  if desktop_is_running; then echo desktop
  elif have colima && colima status >/dev/null 2>&1; then echo colima
  else echo none; fi
}

# capture previous context so we can restore on failure
PREV_CTX="$(docker context show 2>/dev/null || echo default)"

echo "🔀 Switching to: $TARGET"

if [[ "$TARGET" == "desktop" ]]; then
  stop_colima
  start_desktop
else
  # stop Desktop gracefully; only escalate with --force (if you added that)
  if desktop_is_running; then
    if ! stop_desktop_graceful; then
      echo "⚠️  Docker Desktop still running. Quit it or re-run with --force."
      exit 1
    fi
  fi
  start_colima
fi

# Wait for daemon (unchanged logic, just capture success)
ok=0
for i in $(seq 1 60); do
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    ok=1; break
  fi
  sleep 1
done

if [ "$ok" -eq 1 ]; then
  # ✅ only set CLI context once the daemon is actually up
  set_context_for_backend "$TARGET"
  echo "✅ Docker ready on $TARGET"
  exit 0
else
  echo "⚠️  Timed out waiting for Docker on $TARGET"
  # restore previous context so you’re not left pointing to a dead socket
  docker context use "$PREV_CTX" >/dev/null 2>&1 || true
  exit 1
fi

