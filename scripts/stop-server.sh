#!/usr/bin/env bash
set -euo pipefail

# Stop a deliberate visual companion server session.
#
# Usage:
#   stop-server.sh                  Auto-discover and stop all running sessions
#   stop-server.sh SESSION_DIR      Stop a specific session (coordinator use)

stop_session() {
  local SESSION_DIR="$1"
  local STATE_DIR="$SESSION_DIR/state"
  local SERVER_JS="$SESSION_DIR/server.js"

  if [[ ! -d "$SESSION_DIR" ]]; then
    echo "Session directory not found: $SESSION_DIR" >&2
    return 1
  fi

  local PIDS
  PIDS=$(pgrep -f "$SERVER_JS" 2>/dev/null || true)

  if [[ -n "$PIDS" ]]; then
    echo "$PIDS" | xargs kill 2>/dev/null || true
    echo "Server stopped (session: $SESSION_DIR)"
  else
    echo "No running server found for session: $SESSION_DIR"
  fi

  # Mark as stopped
  mkdir -p "$STATE_DIR"
  echo "$(date +%s)" > "$STATE_DIR/server-stopped"

  # Clean up /tmp sessions only
  if [[ "$SESSION_DIR" == /tmp/* ]]; then
    rm -rf "$SESSION_DIR"
    echo "Temporary session cleaned up."
  fi
}

# ── With explicit SESSION_DIR arg (coordinator use) ────────────────────────
if [[ $# -ge 1 ]]; then
  stop_session "$1"
  exit 0
fi

# ── No args: auto-discover all running deliberate companion sessions ────────
STOPPED=0

# Search project-local sessions (.deliberate/companion/)
for SERVER_JS in .deliberate/companion/*/server.js; do
  [[ -f "$SERVER_JS" ]] || continue
  SESSION_DIR="$(dirname "$SERVER_JS")"
  PIDS=$(pgrep -f "$SERVER_JS" 2>/dev/null || true)
  if [[ -n "$PIDS" ]]; then
    echo "$PIDS" | xargs kill 2>/dev/null || true
    echo "Server stopped (session: $SESSION_DIR)"
    mkdir -p "$SESSION_DIR/state"
    echo "$(date +%s)" > "$SESSION_DIR/state/server-stopped"
    STOPPED=$((STOPPED + 1))
  fi
done

# Search /tmp sessions
for SERVER_JS in /tmp/deliberate-companion/*/server.js; do
  [[ -f "$SERVER_JS" ]] || continue
  SESSION_DIR="$(dirname "$SERVER_JS")"
  PIDS=$(pgrep -f "$SERVER_JS" 2>/dev/null || true)
  if [[ -n "$PIDS" ]]; then
    echo "$PIDS" | xargs kill 2>/dev/null || true
    echo "Server stopped (session: $SESSION_DIR)"
    rm -rf "$SESSION_DIR"
    echo "Temporary session cleaned up."
    STOPPED=$((STOPPED + 1))
  fi
done

# Fallback: kill any node process running a deliberate server.js
if [[ "$STOPPED" -eq 0 ]]; then
  PIDS=$(pgrep -f "deliberate-companion.*/server.js" 2>/dev/null || true)
  if [[ -n "$PIDS" ]]; then
    echo "$PIDS" | xargs kill 2>/dev/null || true
    echo "Server stopped."
    STOPPED=$((STOPPED + 1))
  fi
fi

if [[ "$STOPPED" -eq 0 ]]; then
  echo "No running deliberate visual companion server found."
fi
