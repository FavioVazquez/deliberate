#!/usr/bin/env bash
set -euo pipefail

# Stop a deliberate visual companion server session

if [[ $# -lt 1 ]]; then
  echo "Usage: stop-server.sh SESSION_DIR" >&2
  exit 1
fi

SESSION_DIR="$1"
STATE_DIR="$SESSION_DIR/state"

if [[ ! -d "$SESSION_DIR" ]]; then
  echo "Session directory not found: $SESSION_DIR" >&2
  exit 1
fi

# Read server info to find the process
if [[ -f "$STATE_DIR/server-info" ]]; then
  # Find the node process serving this session
  SERVER_JS="$SESSION_DIR/server.js"
  PIDS=$(pgrep -f "$SERVER_JS" 2>/dev/null || true)

  if [[ -n "$PIDS" ]]; then
    echo "$PIDS" | xargs kill 2>/dev/null || true
    echo "Server stopped."
  else
    echo "No running server found for this session."
  fi
fi

# Mark as stopped
echo "$(date +%s)" > "$STATE_DIR/server-stopped"

# Clean up /tmp sessions only
if [[ "$SESSION_DIR" == /tmp/* ]]; then
  rm -rf "$SESSION_DIR"
  echo "Temporary session cleaned up."
else
  echo "Session files preserved at: $SESSION_DIR"
fi
