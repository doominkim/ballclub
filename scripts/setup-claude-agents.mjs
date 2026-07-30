#!/usr/bin/env node

import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';
import { runAgentSetup } from './setup-agent-files.mjs';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const pluginRoot = path.resolve(scriptDir, '..');
const claudeHome = path.resolve(process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude'));
const dataRoot = path.resolve(process.env.BALLCLUB_DATA || path.join(os.homedir(), '.codex', 'ballclub'));

function readIdentity(value) {
  if (value === null) return null;
  const read = (key) => value.match(new RegExp(`^${key}:\\s*([^\\s#]+)\\s*$`, 'm'))?.[1] || null;
  const identity = { name: read('name'), model: read('model'), effort: read('effort') };
  return Object.values(identity).every(Boolean) ? identity : null;
}

const status = await runAgentSetup({
  label: 'Claude Code',
  sourceDir: path.join(pluginRoot, 'rosters', 'claude'),
  targetDir: path.join(claudeHome, 'agents'),
  statePath: path.join(dataRoot, 'config', 'claude-agent-state.json'),
  backupRoot: path.join(dataRoot, 'backups', 'claude-agents'),
  extension: '.md',
  readIdentity,
});

process.exit(status);
