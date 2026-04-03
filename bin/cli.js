#!/usr/bin/env node

'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');
const readline = require('readline');

const ROOT = path.resolve(__dirname, '..');
const pkg = require(path.join(ROOT, 'package.json'));

// ─── Colors ────────────────────────────────────────────────────────────────
const blue   = '\x1b[38;5;33m';
const cyan   = '\x1b[36m';
const green  = '\x1b[32m';
const yellow = '\x1b[33m';
const dim    = '\x1b[2m';
const bold   = '\x1b[1m';
const reset  = '\x1b[0m';

// ─── Argument parsing ──────────────────────────────────────────────────────
const args = process.argv.slice(2);
const hasClaude   = args.includes('--claude') || args.includes('--claude-code');
const hasWindsurf = args.includes('--windsurf');
const hasCursor   = args.includes('--cursor');
const hasAll      = args.includes('--all');
const hasGlobal   = args.includes('--global') || args.includes('-g');
const hasLocal    = args.includes('--local')  || args.includes('-l');
const hasDryRun   = args.includes('--dry-run');
const hasHelp     = args.includes('--help') || args.includes('-h');
const hasUninstall = args.includes('--uninstall') || args.includes('-u');

let selectedPlatforms = [];
if (hasAll)      selectedPlatforms = ['claude-code', 'windsurf'];
if (hasClaude)   selectedPlatforms.push('claude-code');
if (hasWindsurf) selectedPlatforms.push('windsurf');
if (hasCursor)   selectedPlatforms.push('cursor');

// ─── Banner ────────────────────────────────────────────────────────────────
const banner = `
${blue}  ██████╗ ███████╗██╗     ██╗██████╗ ███████╗██████╗  █████╗ ████████╗███████╗
  ██╔══██╗██╔════╝██║     ██║██╔══██╗██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔════╝
  ██║  ██║█████╗  ██║     ██║██████╔╝█████╗  ██████╔╝███████║   ██║   █████╗
  ██║  ██║██╔══╝  ██║     ██║██╔══██╗██╔══╝  ██╔══██╗██╔══██║   ██║   ██╔══╝
  ██████╔╝███████╗███████╗██║██████╔╝███████╗██║  ██║██║  ██║   ██║   ███████╗
  ╚═════╝ ╚══════╝╚══════╝╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝${reset}

  ${dim}Agreement is a bug.${reset}
  ${dim}v${pkg.version} · Multi-agent deliberation for AI coding assistants${reset}
`;

// ─── Help text ─────────────────────────────────────────────────────────────
const helpText = `
  ${yellow}Usage:${reset} npx @faviovazquez/deliberate [platform] [scope] [options]

  ${yellow}Platforms:${reset}
    ${cyan}--claude${reset}      Claude Code  (~/.claude/)
    ${cyan}--windsurf${reset}    Windsurf     (~/.codeium/windsurf/)
    ${cyan}--cursor${reset}      Cursor       (.cursor/skills/)
    ${cyan}--all${reset}         All detected platforms

  ${yellow}Scope:${reset}
    ${cyan}-g, --global${reset}  Install to global config directory (recommended)
    ${cyan}-l, --local${reset}   Install to current project directory

  ${yellow}Options:${reset}
    ${cyan}--dry-run${reset}        Preview without installing
    ${cyan}-u, --uninstall${reset}  Remove deliberate files
    ${cyan}-h, --help${reset}       Show this help

  ${yellow}Examples:${reset}
    ${dim}# Interactive install (prompts for platform and scope)${reset}
    npx @faviovazquez/deliberate

    ${dim}# Install for Claude Code globally${reset}
    npx @faviovazquez/deliberate --claude --global

    ${dim}# Install for all platforms globally${reset}
    npx @faviovazquez/deliberate --all --global

    ${dim}# Preview installation${reset}
    npx @faviovazquez/deliberate --claude --global --dry-run
`;

// ─── Path helpers ──────────────────────────────────────────────────────────
function getGlobalDir(platform) {
  switch (platform) {
    case 'claude-code': return path.join(os.homedir(), '.claude');
    case 'windsurf':    return path.join(os.homedir(), '.codeium', 'windsurf');
    case 'cursor':      return path.join(process.cwd(), '.cursor');
    default:            return path.join(os.homedir(), '.claude');
  }
}

function getLocalDir(platform) {
  switch (platform) {
    case 'claude-code': return path.join(process.cwd(), '.claude');
    case 'windsurf':    return path.join(process.cwd(), '.windsurf');
    case 'cursor':      return path.join(process.cwd(), '.cursor');
    default:            return path.join(process.cwd(), '.claude');
  }
}

function getPlatformLabel(platform) {
  const labels = { 'claude-code': 'Claude Code', 'windsurf': 'Windsurf', 'cursor': 'Cursor' };
  return labels[platform] || platform;
}

function tildePath(p) {
  return p.replace(os.homedir(), '~');
}

// ─── File copy ─────────────────────────────────────────────────────────────
let fileCount = 0;

function copyFile(src, dest) {
  if (hasDryRun) {
    console.log(`    ${dim}(dry-run)${reset} ${tildePath(dest)}`);
    return;
  }
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.copyFileSync(src, dest);
  fileCount++;
}

function copyDir(srcDir, destDir) {
  if (!fs.existsSync(srcDir)) return;
  for (const entry of fs.readdirSync(srcDir, { withFileTypes: true })) {
    const src = path.join(srcDir, entry.name);
    const dest = path.join(destDir, entry.name);
    if (entry.isDirectory()) {
      copyDir(src, dest);
    } else {
      copyFile(src, dest);
    }
  }
}

function makeExecutable(filePath) {
  if (hasDryRun || !fs.existsSync(filePath)) return;
  try { fs.chmodSync(filePath, '755'); } catch { /* ignore */ }
}

// ─── Install functions ─────────────────────────────────────────────────────
function installClaudeCode(isGlobal) {
  const baseDir = isGlobal ? getGlobalDir('claude-code') : getLocalDir('claude-code');
  const agentsDir = path.join(baseDir, 'agents');
  const skillDir  = path.join(baseDir, 'skills', 'deliberate');
  const locationLabel = tildePath(baseDir);

  console.log(`\n  Installing for ${cyan}Claude Code${reset} → ${cyan}${locationLabel}${reset}\n`);

  // Core agents
  const agentsSrc = path.join(ROOT, 'agents');
  for (const f of fs.readdirSync(agentsSrc)) {
    if (!f.endsWith('.md')) continue;
    copyFile(path.join(agentsSrc, f), path.join(agentsDir, `deliberate-${f}`));
  }
  // Specialist agents
  const specSrc = path.join(agentsSrc, 'specialists');
  if (fs.existsSync(specSrc)) {
    for (const f of fs.readdirSync(specSrc)) {
      if (!f.endsWith('.md')) continue;
      copyFile(path.join(specSrc, f), path.join(agentsDir, `deliberate-${f}`));
    }
  }
  console.log(`  ${green}✓${reset} Installed 17 agents to ${tildePath(agentsDir)}/`);

  // Skill protocol
  copyFile(path.join(ROOT, 'SKILL.md'), path.join(skillDir, 'SKILL.md'));
  copyFile(path.join(ROOT, 'BRAINSTORM.md'), path.join(skillDir, 'BRAINSTORM.md'));
  console.log(`  ${green}✓${reset} Installed skill protocol to ${tildePath(skillDir)}/`);

  // Configs
  copyDir(path.join(ROOT, 'configs'), path.join(skillDir, 'configs'));
  console.log(`  ${green}✓${reset} Installed configs`);

  // Scripts
  copyDir(path.join(ROOT, 'scripts'), path.join(skillDir, 'scripts'));
  makeExecutable(path.join(skillDir, 'scripts', 'start-server.sh'));
  makeExecutable(path.join(skillDir, 'scripts', 'stop-server.sh'));
  makeExecutable(path.join(skillDir, 'scripts', 'detect-platform.sh'));
  console.log(`  ${green}✓${reset} Installed visual companion scripts`);

  // Templates
  copyDir(path.join(ROOT, 'templates'), path.join(skillDir, 'templates'));
  console.log(`  ${green}✓${reset} Installed output templates`);

  console.log(`\n  ${green}Done!${reset} Open Claude Code and try: ${cyan}/deliberate "your question here"${reset}`);
}

function installWindsurf(isGlobal) {
  const baseDir = isGlobal ? getGlobalDir('windsurf') : getLocalDir('windsurf');
  const skillDir = path.join(baseDir, 'skills', 'deliberate');
  const locationLabel = tildePath(skillDir);

  console.log(`\n  Installing for ${cyan}Windsurf${reset} → ${cyan}${locationLabel}${reset}\n`);

  // Skill protocol
  copyFile(path.join(ROOT, 'SKILL.md'), path.join(skillDir, 'SKILL.md'));
  copyFile(path.join(ROOT, 'BRAINSTORM.md'), path.join(skillDir, 'BRAINSTORM.md'));
  console.log(`  ${green}✓${reset} Installed skill protocol`);

  // Agents (bundled with skill)
  copyDir(path.join(ROOT, 'agents'), path.join(skillDir, 'agents'));
  console.log(`  ${green}✓${reset} Installed 17 agents`);

  // Configs, Scripts, Templates
  copyDir(path.join(ROOT, 'configs'), path.join(skillDir, 'configs'));
  copyDir(path.join(ROOT, 'scripts'), path.join(skillDir, 'scripts'));
  copyDir(path.join(ROOT, 'templates'), path.join(skillDir, 'templates'));
  makeExecutable(path.join(skillDir, 'scripts', 'start-server.sh'));
  makeExecutable(path.join(skillDir, 'scripts', 'stop-server.sh'));
  makeExecutable(path.join(skillDir, 'scripts', 'detect-platform.sh'));
  console.log(`  ${green}✓${reset} Installed configs, scripts, templates`);

  console.log(`\n  ${green}Done!${reset} Open Windsurf and try: ${cyan}@deliberate${reset} or just ask a complex decision question.`);
}

function installCursor(isGlobal) {
  // Cursor is always workspace-local
  const skillDir = path.join(process.cwd(), '.cursor', 'skills', 'deliberate');
  const locationLabel = tildePath(skillDir);

  console.log(`\n  Installing for ${cyan}Cursor${reset} → ${cyan}${locationLabel}${reset}\n`);

  copyFile(path.join(ROOT, 'SKILL.md'), path.join(skillDir, 'SKILL.md'));
  copyFile(path.join(ROOT, 'BRAINSTORM.md'), path.join(skillDir, 'BRAINSTORM.md'));
  copyDir(path.join(ROOT, 'agents'), path.join(skillDir, 'agents'));
  copyDir(path.join(ROOT, 'configs'), path.join(skillDir, 'configs'));
  copyDir(path.join(ROOT, 'scripts'), path.join(skillDir, 'scripts'));
  copyDir(path.join(ROOT, 'templates'), path.join(skillDir, 'templates'));
  makeExecutable(path.join(skillDir, 'scripts', 'start-server.sh'));
  makeExecutable(path.join(skillDir, 'scripts', 'stop-server.sh'));
  makeExecutable(path.join(skillDir, 'scripts', 'detect-platform.sh'));
  console.log(`  ${green}✓${reset} Installed skill, agents, configs, scripts, templates`);

  console.log(`\n  ${green}Done!${reset} Open Cursor and try: ${cyan}@deliberate${reset} or just ask a complex decision question.`);
}

// ─── Uninstall ─────────────────────────────────────────────────────────────
function uninstall(platform, isGlobal) {
  const label = getPlatformLabel(platform);
  let removed = 0;

  if (platform === 'claude-code') {
    const baseDir = isGlobal ? getGlobalDir('claude-code') : getLocalDir('claude-code');
    console.log(`\n  Uninstalling from ${cyan}${label}${reset} at ${cyan}${tildePath(baseDir)}${reset}\n`);

    // Remove agents
    const agentsDir = path.join(baseDir, 'agents');
    if (fs.existsSync(agentsDir)) {
      for (const f of fs.readdirSync(agentsDir)) {
        if (f.startsWith('deliberate-') && f.endsWith('.md')) {
          fs.unlinkSync(path.join(agentsDir, f)); removed++;
        }
      }
      if (removed > 0) console.log(`  ${green}✓${reset} Removed ${removed} agent files`);
    }

    // Remove skill dir
    const skillDir = path.join(baseDir, 'skills', 'deliberate');
    if (fs.existsSync(skillDir)) {
      fs.rmSync(skillDir, { recursive: true });
      console.log(`  ${green}✓${reset} Removed skills/deliberate/`);
      removed++;
    }
  } else {
    const baseDir = platform === 'windsurf'
      ? (isGlobal ? getGlobalDir('windsurf') : getLocalDir('windsurf'))
      : path.join(process.cwd(), '.cursor');
    const skillDir = path.join(baseDir, 'skills', 'deliberate');
    console.log(`\n  Uninstalling from ${cyan}${label}${reset} at ${cyan}${tildePath(skillDir)}${reset}\n`);

    if (fs.existsSync(skillDir)) {
      fs.rmSync(skillDir, { recursive: true });
      console.log(`  ${green}✓${reset} Removed skills/deliberate/`);
      removed++;
    }
  }

  if (removed === 0) console.log(`  ${yellow}⚠${reset} No deliberate files found.`);
  else console.log(`\n  ${green}Done!${reset} deliberate uninstalled from ${label}.`);
}

// ─── Detect platforms ──────────────────────────────────────────────────────
function detectPlatforms() {
  const detected = [];
  if (fs.existsSync(path.join(os.homedir(), '.claude'))) detected.push('claude-code');
  if (fs.existsSync(path.join(os.homedir(), '.codeium', 'windsurf'))) detected.push('windsurf');
  if (fs.existsSync(path.join(process.cwd(), '.windsurf'))) {
    if (!detected.includes('windsurf')) detected.push('windsurf');
  }
  if (fs.existsSync(path.join(process.cwd(), '.cursor'))) detected.push('cursor');
  return detected;
}

// ─── Interactive prompt ────────────────────────────────────────────────────
async function promptUser() {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  const ask = (q) => new Promise(resolve => rl.question(q, resolve));

  const detected = detectPlatforms();

  console.log(`  ${yellow}Select platform:${reset}`);
  console.log(`    1) Claude Code  ${dim}(${detected.includes('claude-code') ? green + 'detected' + reset : dim + 'not detected' + reset}${dim})${reset}`);
  console.log(`    2) Windsurf     ${dim}(${detected.includes('windsurf') ? green + 'detected' + reset : dim + 'not detected' + reset}${dim})${reset}`);
  console.log(`    3) Cursor       ${dim}(workspace only)${reset}`);
  console.log(`    4) All detected ${dim}(${detected.length > 0 ? detected.map(getPlatformLabel).join(', ') : 'none detected'})${reset}`);

  const platformChoice = await ask(`\n  ${bold}Platform [1-4]:${reset} `);
  const platformMap = {
    '1': ['claude-code'],
    '2': ['windsurf'],
    '3': ['cursor'],
    '4': detected.length > 0 ? detected : ['claude-code'],
  };
  const platforms = platformMap[platformChoice.trim()] || ['claude-code'];

  // Only ask scope if not cursor-only
  let isGlobal = true;
  const hasCursorOnly = platforms.length === 1 && platforms[0] === 'cursor';
  if (!hasCursorOnly) {
    console.log(`\n  ${yellow}Install scope:${reset}`);
    console.log(`    1) ${green}Global${reset} ${dim}(recommended)${reset} — available in all projects`);
    console.log(`    2) Local — current project only`);
    const scopeChoice = await ask(`\n  ${bold}Scope [1-2]:${reset} `);
    isGlobal = scopeChoice.trim() !== '2';
  } else {
    isGlobal = false; // Cursor is always workspace-local
  }

  rl.close();
  return { platforms, isGlobal };
}

// ─── Entry point ───────────────────────────────────────────────────────────
async function main() {
  console.log(banner);

  if (hasHelp) { console.log(helpText); process.exit(0); }

  let platforms = selectedPlatforms;
  let isGlobal = hasGlobal || !hasLocal;

  if (platforms.length === 0 && !hasUninstall) {
    const result = await promptUser();
    platforms = result.platforms;
    isGlobal = result.isGlobal;
  } else if (platforms.length === 0 && hasUninstall) {
    console.error(`  ${yellow}Error:${reset} Specify a platform to uninstall from.`);
    console.error(`  Example: npx @faviovazquez/deliberate --claude --global --uninstall`);
    process.exit(1);
  }

  console.log('');
  for (const platform of platforms) {
    fileCount = 0;
    if (hasUninstall) {
      uninstall(platform, isGlobal);
    } else {
      switch (platform) {
        case 'claude-code': installClaudeCode(isGlobal); break;
        case 'windsurf':    installWindsurf(isGlobal); break;
        case 'cursor':      installCursor(isGlobal); break;
        default:
          console.error(`  ${yellow}Unknown platform:${reset} ${platform}`);
          process.exit(1);
      }
    }
  }

  if (!hasUninstall) {
    console.log(`\n  ${dim}Learn more: https://github.com/FavioVazquez/deliberate${reset}`);
  }
}

main().catch(err => {
  console.error(`  Error: ${err.message}`);
  process.exit(1);
});
