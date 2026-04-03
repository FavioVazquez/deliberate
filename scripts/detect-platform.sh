#!/usr/bin/env bash
set -euo pipefail

# deliberate -- Platform detection
# Detects which AI coding platforms are available and outputs JSON.

detect_claude_code() {
  local available=false
  local binary=""
  local method=""

  if command -v claude >/dev/null 2>&1; then
    available=true
    binary="$(command -v claude)"
    method="cli"
  fi

  # Check for config directory
  local config_dir=""
  if [[ -d "$HOME/.claude" ]]; then
    config_dir="$HOME/.claude"
  fi

  echo "{\"platform\":\"claude-code\",\"available\":$available,\"binary\":\"$binary\",\"method\":\"$method\",\"config_dir\":\"$config_dir\"}"
}

detect_windsurf() {
  local available=false
  local config_dir=""
  local global_skills_dir=""
  local workspace_skills_dir=""

  # Check for Windsurf config directories
  # Global skills: ~/.codeium/windsurf/skills/
  # Workspace skills: .windsurf/skills/ (in project root)
  if [[ -d "$HOME/.codeium/windsurf" ]]; then
    available=true
    config_dir="$HOME/.codeium/windsurf"
    global_skills_dir="$HOME/.codeium/windsurf/skills"
  fi
  if [[ -d ".windsurf" ]]; then
    available=true
    workspace_skills_dir="$PWD/.windsurf/skills"
  fi

  echo "{\"platform\":\"windsurf\",\"available\":$available,\"config_dir\":\"$config_dir\",\"global_skills_dir\":\"$global_skills_dir\",\"workspace_skills_dir\":\"$workspace_skills_dir\"}"
}

detect_cursor() {
  local available=false
  local config_dir=""

  if [[ -d "$HOME/.cursor" ]]; then
    available=true
    config_dir="$HOME/.cursor"
  fi

  echo "{\"platform\":\"cursor\",\"available\":$available,\"config_dir\":\"$config_dir\"}"
}

# Output all platforms
echo "{"
echo "  \"platforms\": ["
echo "    $(detect_claude_code),"
echo "    $(detect_windsurf),"
echo "    $(detect_cursor)"
echo "  ],"
echo "  \"node_available\": $(command -v node >/dev/null 2>&1 && echo true || echo false),"
echo "  \"node_version\": \"$(node --version 2>/dev/null || echo 'not installed')\""
echo "}"
