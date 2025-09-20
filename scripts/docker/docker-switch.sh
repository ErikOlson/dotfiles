#!/usr/bin/env bash
set -euo pipefail

# docker-switch.sh
# Switch between Docker Desktop and Colima.
# Usage:
#   scripts/docker/docker-switch.sh desktop|colima

TARGET="${1:-}"
if [[ "$TARGET" != "desktop" && "$TARGET" != "colima" ]]; then
  echo "Usage: $0 desktop|colima"; exit 1
fi

have() { command -v "$1" >/dev/null 2>&1; }

stop_desktop() { osascript -e 'quit app "Docker"' >/dev/null 2>&1 || true; }
stop_colima()  { have colima && colima stop >/dev/null 2>&1 || true; }
start_desktop(){ open -g -a "Docker" || true; }
start_colima() {
  if ! have colima; then
    echo "Colima not installed. brew install colima"; exit 1
  fi
  colima status >/dev/null 2>&1 || colima start
}

echo "🔀 Switching to: $TARGET"
if [ "$TARGET" = "desktop" ]; then
  stop_colima
  start_desktop
else
  stop_desktop
  start_colima
fi

echo "⏳ Waiting for Docker daemon..."
i=0; while [ $i -lt 60 ]; do
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    echo "✅ Docker ready on $TARGET"
    exit 0
  fi
  sleep 1; i=$((i+1))
done
echo "⚠️  Timed out waiting for Docker on $TARGET"
exit 1

