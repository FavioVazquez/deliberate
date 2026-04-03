#!/usr/bin/env bash
set -euo pipefail

# deliberate visual companion server
# Watches a directory for HTML files and serves the newest one to a browser.
# User interactions (clicks, selections) are recorded as JSONL events.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR=""
HOST="127.0.0.1"
URL_HOST=""
PORT=0
FOREGROUND=false

usage() {
  cat <<EOF
Usage: start-server.sh [OPTIONS]

Options:
  --project-dir DIR   Project root for persistent storage (recommended)
  --host HOST         Bind address (default: 127.0.0.1)
  --url-host HOST     Hostname for printed URL (default: same as --host)
  --port PORT         Port to listen on (default: random available)
  --foreground        Run in foreground (for Codex, Gemini CLI)
  -h, --help          Show this help
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-dir) PROJECT_DIR="$2"; shift 2 ;;
    --host) HOST="$2"; shift 2 ;;
    --url-host) URL_HOST="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --foreground) FOREGROUND=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Find available port if not specified
if [[ "$PORT" == "0" ]]; then
  PORT=$(python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()" 2>/dev/null || echo "52341")
fi

[[ -z "$URL_HOST" ]] && URL_HOST="$HOST"
[[ "$URL_HOST" == "0.0.0.0" ]] && URL_HOST="localhost"

# Create session directory
TIMESTAMP=$(date +%s)
PID_PREFIX="$$"

if [[ -n "$PROJECT_DIR" ]]; then
  SESSION_DIR="$PROJECT_DIR/.deliberate/companion/${PID_PREFIX}-${TIMESTAMP}"
else
  SESSION_DIR="/tmp/deliberate-companion/${PID_PREFIX}-${TIMESTAMP}"
fi

SCREEN_DIR="$SESSION_DIR/content"
STATE_DIR="$SESSION_DIR/state"

mkdir -p "$SCREEN_DIR" "$STATE_DIR"

# Write the frame template and helper to the session
cp "$SCRIPT_DIR/frame-template.html" "$SESSION_DIR/frame-template.html"
cp "$SCRIPT_DIR/helper.js" "$SESSION_DIR/helper.js"

# Create the server script (Node.js)
cat > "$SESSION_DIR/server.js" << 'SERVEREOF'
const http = require('http');
const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const HOST = args[0] || '127.0.0.1';
const PORT = parseInt(args[1] || '52341', 10);
const SCREEN_DIR = args[2];
const STATE_DIR = args[3];
const SESSION_DIR = args[4];

const FRAME_TEMPLATE = fs.readFileSync(path.join(SESSION_DIR, 'frame-template.html'), 'utf8');
const HELPER_JS = fs.readFileSync(path.join(SESSION_DIR, 'helper.js'), 'utf8');

let inactivityTimer = null;
const INACTIVITY_TIMEOUT = 30 * 60 * 1000; // 30 minutes

function resetInactivityTimer() {
  if (inactivityTimer) clearTimeout(inactivityTimer);
  inactivityTimer = setTimeout(() => {
    console.log('Inactivity timeout reached. Shutting down.');
    fs.writeFileSync(path.join(STATE_DIR, 'server-stopped'), Date.now().toString());
    process.exit(0);
  }, INACTIVITY_TIMEOUT);
}

function getNewestFile() {
  try {
    const files = fs.readdirSync(SCREEN_DIR)
      .filter(f => f.endsWith('.html'))
      .map(f => ({
        name: f,
        mtime: fs.statSync(path.join(SCREEN_DIR, f)).mtimeMs
      }))
      .sort((a, b) => b.mtime - a.mtime);
    return files.length > 0 ? files[0].name : null;
  } catch (e) {
    return null;
  }
}

function wrapInFrame(content, filename) {
  // If content is a full HTML document, just inject the helper script
  if (content.trim().startsWith('<!DOCTYPE') || content.trim().startsWith('<html')) {
    return content.replace('</body>', `<script>${HELPER_JS}</script></body>`);
  }
  // Otherwise, wrap in frame template
  return FRAME_TEMPLATE
    .replace('{{CONTENT}}', content)
    .replace('{{HELPER_JS}}', HELPER_JS)
    .replace('{{FILENAME}}', filename || 'deliberate');
}

function getMimeType(ext) {
  const types = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'application/javascript',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.svg': 'image/svg+xml'
  };
  return types[ext] || 'text/plain';
}

const server = http.createServer((req, res) => {
  resetInactivityTimer();

  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // POST /events -- record user interaction
  if (req.method === 'POST' && req.url === '/events') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      const eventsFile = path.join(STATE_DIR, 'events');
      fs.appendFileSync(eventsFile, body + '\n');
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end('{"status":"ok"}');
    });
    return;
  }

  // GET /events -- read events
  if (req.method === 'GET' && req.url === '/events') {
    const eventsFile = path.join(STATE_DIR, 'events');
    if (fs.existsSync(eventsFile)) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(fs.readFileSync(eventsFile, 'utf8'));
    } else {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end('');
    }
    return;
  }

  // GET /status -- health check
  if (req.url === '/status') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'running', newest: getNewestFile() }));
    return;
  }

  // GET / -- serve newest HTML file wrapped in frame
  if (req.url === '/' || req.url === '/index.html') {
    const newest = getNewestFile();
    if (!newest) {
      const waiting = `
        <div style="display:flex;align-items:center;justify-content:center;min-height:60vh;flex-direction:column">
          <h2 style="color:var(--text-primary,#e0e0e0);font-family:system-ui">deliberate</h2>
          <p style="color:var(--text-secondary,#999);font-family:system-ui">Waiting for content...</p>
        </div>`;
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(wrapInFrame(waiting, 'waiting'));
      return;
    }
    const content = fs.readFileSync(path.join(SCREEN_DIR, newest), 'utf8');
    // Clear events when new screen is served
    const eventsFile = path.join(STATE_DIR, 'events');
    if (fs.existsSync(eventsFile)) fs.unlinkSync(eventsFile);

    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(wrapInFrame(content, newest));
    return;
  }

  // Serve static files from screen_dir
  const filePath = path.join(SCREEN_DIR, req.url.slice(1));
  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    const ext = path.extname(filePath);
    res.writeHead(200, { 'Content-Type': getMimeType(ext) });
    res.end(fs.readFileSync(filePath));
    return;
  }

  res.writeHead(404);
  res.end('Not found');
});

server.listen(PORT, HOST, () => {
  const info = {
    type: 'server-started',
    port: PORT,
    url: `http://${args[5] || HOST}:${PORT}`,
    screen_dir: SCREEN_DIR,
    state_dir: STATE_DIR,
    session_dir: SESSION_DIR
  };

  // Write server info for retrieval
  fs.writeFileSync(path.join(STATE_DIR, 'server-info'), JSON.stringify(info, null, 2));

  // Output to stdout for the launching script
  console.log(JSON.stringify(info));

  resetInactivityTimer();
});

process.on('SIGTERM', () => {
  fs.writeFileSync(path.join(STATE_DIR, 'server-stopped'), Date.now().toString());
  process.exit(0);
});
process.on('SIGINT', () => {
  fs.writeFileSync(path.join(STATE_DIR, 'server-stopped'), Date.now().toString());
  process.exit(0);
});
SERVEREOF

# Auto-detect environment
IS_CODEX=false
[[ -n "${CODEX_CI:-}" ]] && IS_CODEX=true

# Launch the server
if [[ "$FOREGROUND" == "true" ]] || [[ "$IS_CODEX" == "true" ]]; then
  # Foreground mode: blocks the shell
  exec node "$SESSION_DIR/server.js" "$HOST" "$PORT" "$SCREEN_DIR" "$STATE_DIR" "$SESSION_DIR" "$URL_HOST"
else
  # Background mode: detach and return immediately
  nohup node "$SESSION_DIR/server.js" "$HOST" "$PORT" "$SCREEN_DIR" "$STATE_DIR" "$SESSION_DIR" "$URL_HOST" > /dev/null 2>&1 &
  SERVER_PID=$!

  # Wait briefly for the server to start and write server-info
  for i in 1 2 3 4 5; do
    if [[ -f "$STATE_DIR/server-info" ]]; then
      cat "$STATE_DIR/server-info"
      exit 0
    fi
    sleep 0.5
  done

  # If server-info wasn't written, something went wrong
  echo '{"type":"error","message":"Server failed to start within 2.5 seconds"}' >&2
  exit 1
fi
