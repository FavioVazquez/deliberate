#!/usr/bin/env node

'use strict';

const { execSync, spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const ROOT = path.resolve(__dirname, '..');
const INSTALL_SCRIPT = path.join(ROOT, 'install.sh');

const args = process.argv.slice(2);

function usage() {
  console.log(`
  deliberate -- Multi-agent deliberation for AI coding assistants
  Agreement is a bug.

  Usage:
    npx @faviovazquez/deliberate              Auto-detect platform and install
    npx @faviovazquez/deliberate --platform X Install for specific platform
    npx @faviovazquez/deliberate --dry-run    Preview installation
    npx @faviovazquez/deliberate --help       Show this help

  Platforms: claude-code, windsurf, cursor, all

  After installation, open your AI coding assistant and try:
    /deliberate "should we migrate from REST to GraphQL?"

  Learn more: https://github.com/FavioVazquez/deliberate
`);
}

if (args.includes('--help') || args.includes('-h')) {
  usage();
  process.exit(0);
}

// Forward all arguments to install.sh
console.log('');
console.log('  deliberate installer');
console.log('  Agreement is a bug.');
console.log('');

// Check for bash
try {
  execSync('which bash', { stdio: 'pipe' });
} catch (e) {
  console.error('Error: bash is required. Please install bash and try again.');
  process.exit(1);
}

// Make install.sh executable
try {
  fs.chmodSync(INSTALL_SCRIPT, '755');
} catch (e) {
  // May already be executable
}

// Run install.sh with forwarded arguments
const installArgs = args.length > 0 ? args : [];
const child = spawn('bash', [INSTALL_SCRIPT, ...installArgs], {
  stdio: 'inherit',
  cwd: ROOT
});

child.on('close', (code) => {
  process.exit(code || 0);
});
