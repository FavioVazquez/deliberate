#!/usr/bin/env bash
set -euo pipefail

# deliberate -- Platform-aware installer
# Installs agent definitions and skill protocol to the correct directories.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=false
CLAUDE_DIR="$HOME/.claude"
WINDSURF_DIR=""
PLATFORM=""
SCOPE="workspace"

usage() {
  cat <<EOF
Usage: install.sh [OPTIONS]

Install deliberate agents and skill to your AI coding platform.

Options:
  --claude-dir DIR    Custom Claude config directory (default: ~/.claude)
  --windsurf-dir DIR  Custom Windsurf skills directory
  --platform PLATFORM Force specific platform (claude-code, windsurf, cursor, all)
  --global            Install globally (available in all workspaces)
  --dry-run           Show what would be installed without installing
  -h, --help          Show this help

Examples:
  ./install.sh                        # Auto-detect platform, workspace install
  ./install.sh --global               # Auto-detect platform, global install
  ./install.sh --platform claude-code # Install for Claude Code only
  ./install.sh --platform all         # Install for all detected platforms
  ./install.sh --dry-run              # Preview installation
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude-dir) CLAUDE_DIR="$2"; shift 2 ;;
    --windsurf-dir) WINDSURF_DIR="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --global) SCOPE="global"; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

log() {
  echo "[deliberate] $1"
}

copy_file() {
  local src="$1"
  local dst="$2"

  if [[ "$DRY_RUN" == "true" ]]; then
    log "  (dry-run) $src -> $dst"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    log "  $src -> $dst"
  fi
}

install_claude_code() {
  log "Installing for Claude Code..."
  local agents_dir="$CLAUDE_DIR/agents"
  local skill_dir="$CLAUDE_DIR/skills/deliberate"

  # Core agents
  for agent_file in "$SCRIPT_DIR/agents"/*.md; do
    local name="$(basename "$agent_file")"
    copy_file "$agent_file" "$agents_dir/deliberate-$name"
  done

  # Specialist agents
  for agent_file in "$SCRIPT_DIR/agents/specialists"/*.md; do
    local name="$(basename "$agent_file")"
    copy_file "$agent_file" "$agents_dir/deliberate-$name"
  done

  # Skill protocol
  copy_file "$SCRIPT_DIR/SKILL.md" "$skill_dir/SKILL.md"
  copy_file "$SCRIPT_DIR/BRAINSTORM.md" "$skill_dir/BRAINSTORM.md"

  # Configs
  copy_file "$SCRIPT_DIR/configs/defaults.yaml" "$skill_dir/configs/defaults.yaml"
  copy_file "$SCRIPT_DIR/configs/provider-model-slots.example.yaml" "$skill_dir/configs/provider-model-slots.example.yaml"

  # Scripts
  copy_file "$SCRIPT_DIR/scripts/start-server.sh" "$skill_dir/scripts/start-server.sh"
  copy_file "$SCRIPT_DIR/scripts/stop-server.sh" "$skill_dir/scripts/stop-server.sh"
  copy_file "$SCRIPT_DIR/scripts/frame-template.html" "$skill_dir/scripts/frame-template.html"
  copy_file "$SCRIPT_DIR/scripts/helper.js" "$skill_dir/scripts/helper.js"
  copy_file "$SCRIPT_DIR/scripts/detect-platform.sh" "$skill_dir/scripts/detect-platform.sh"

  # Templates
  copy_file "$SCRIPT_DIR/templates/deliberation-output.md" "$skill_dir/templates/deliberation-output.md"
  copy_file "$SCRIPT_DIR/templates/brainstorm-output.md" "$skill_dir/templates/brainstorm-output.md"

  # Make scripts executable
  if [[ "$DRY_RUN" != "true" ]]; then
    chmod +x "$skill_dir/scripts/start-server.sh"
    chmod +x "$skill_dir/scripts/stop-server.sh"
    chmod +x "$skill_dir/scripts/detect-platform.sh"
  fi

  log "Claude Code installation complete."
  log "  Agents: $agents_dir/deliberate-*.md"
  log "  Skill: $skill_dir/SKILL.md"
}

install_windsurf() {
  log "Installing for Windsurf..."

  local target_dir
  if [[ -n "$WINDSURF_DIR" ]]; then
    target_dir="$WINDSURF_DIR"
  elif [[ "$SCOPE" == "global" ]]; then
    target_dir="$HOME/.codeium/windsurf/skills/deliberate"
  else
    target_dir="$PWD/.windsurf/skills/deliberate"
  fi

  # Skill protocol
  copy_file "$SCRIPT_DIR/SKILL.md" "$target_dir/SKILL.md"
  copy_file "$SCRIPT_DIR/BRAINSTORM.md" "$target_dir/BRAINSTORM.md"

  # Agents (bundled with skill since Windsurf doesn't have a global agents dir)
  for agent_file in "$SCRIPT_DIR/agents"/*.md; do
    local name="$(basename "$agent_file")"
    copy_file "$agent_file" "$target_dir/agents/$name"
  done

  for agent_file in "$SCRIPT_DIR/agents/specialists"/*.md; do
    local name="$(basename "$agent_file")"
    copy_file "$agent_file" "$target_dir/agents/specialists/$name"
  done

  # Configs
  copy_file "$SCRIPT_DIR/configs/defaults.yaml" "$target_dir/configs/defaults.yaml"
  copy_file "$SCRIPT_DIR/configs/provider-model-slots.example.yaml" "$target_dir/configs/provider-model-slots.example.yaml"

  # Scripts
  copy_file "$SCRIPT_DIR/scripts/start-server.sh" "$target_dir/scripts/start-server.sh"
  copy_file "$SCRIPT_DIR/scripts/stop-server.sh" "$target_dir/scripts/stop-server.sh"
  copy_file "$SCRIPT_DIR/scripts/frame-template.html" "$target_dir/scripts/frame-template.html"
  copy_file "$SCRIPT_DIR/scripts/helper.js" "$target_dir/scripts/helper.js"
  copy_file "$SCRIPT_DIR/scripts/detect-platform.sh" "$target_dir/scripts/detect-platform.sh"

  # Templates
  copy_file "$SCRIPT_DIR/templates/deliberation-output.md" "$target_dir/templates/deliberation-output.md"
  copy_file "$SCRIPT_DIR/templates/brainstorm-output.md" "$target_dir/templates/brainstorm-output.md"

  if [[ "$DRY_RUN" != "true" ]]; then
    chmod +x "$target_dir/scripts/start-server.sh"
    chmod +x "$target_dir/scripts/stop-server.sh"
    chmod +x "$target_dir/scripts/detect-platform.sh"
  fi

  log "Windsurf installation complete."
  log "  Skill: $target_dir/"
}

# Auto-detect or use specified platform
if [[ -z "$PLATFORM" ]]; then
  log "Auto-detecting platforms..."
  if [[ -d "$CLAUDE_DIR" ]] || command -v claude >/dev/null 2>&1; then
    PLATFORM="claude-code"
  elif [[ -d "$HOME/.codeium/windsurf" ]] || [[ -d ".windsurf" ]]; then
    PLATFORM="windsurf"
  else
    log "No supported platform detected. Use --platform to specify."
    log "Supported: claude-code, windsurf, cursor, all"
    exit 1
  fi
fi

case "$PLATFORM" in
  claude-code)
    install_claude_code
    ;;
  windsurf)
    install_windsurf
    ;;
  cursor)
    # Cursor uses same structure as Windsurf for skills
    WINDSURF_DIR="${WINDSURF_DIR:-$PWD/.cursor/skills/deliberate}"
    install_windsurf
    ;;
  all)
    if [[ -d "$CLAUDE_DIR" ]] || command -v claude >/dev/null 2>&1; then
      install_claude_code
    fi
    install_windsurf
    ;;
  *)
    echo "Unknown platform: $PLATFORM" >&2
    exit 1
    ;;
esac

log ""
if [[ "$PLATFORM" == "claude-code" ]]; then
  log "Done. Start a new session and try: /deliberate \"your question here\""
else
  log "Done. Start a new session and try: @deliberate or just ask a complex decision question."
fi
