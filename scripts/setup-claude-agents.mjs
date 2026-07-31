#!/usr/bin/env node

import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';
import { dataRoot } from './ballclub-lib.mjs';
import { runAgentSetup } from './setup-agent-files.mjs';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const pluginRoot = path.resolve(scriptDir, '..');
const claudeHome = path.resolve(process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude'));
const runtimeDataRoot = path.resolve(dataRoot('claude'));

function readIdentity(value) {
  if (value === null) return null;
  const read = (key) => value.match(new RegExp(`^${key}:\\s*([^\\s#]+)\\s*$`, 'm'))?.[1] || null;
  const identity = { name: read('name'), model: read('model'), effort: read('effort') };
  return Object.values(identity).every(Boolean) ? identity : null;
}

function readSecurity(value) {
  if (value === null) return null;
  const frontmatter = value.match(/^---\s*\r?\n([\s\S]*?)\r?\n---\s*(?:\r?\n|$)/)?.[1] || '';
  const readList = (key) => {
    const raw = frontmatter.match(new RegExp(`^${key}:\\s*(.*?)\\s*$`, 'm'))?.[1];
    if (raw === undefined) return null;
    return raw.split(',').map((item) => item.trim()).filter(Boolean).sort();
  };
  return {
    tools: readList('tools'),
    disallowedTools: readList('disallowedTools'),
  };
}

const status = await runAgentSetup({
  label: 'Claude Code',
  sourceDir: path.join(pluginRoot, 'rosters', 'claude'),
  targetDir: path.join(claudeHome, 'agents'),
  statePath: path.join(runtimeDataRoot, 'config', 'claude-agent-state.json'),
  backupRoot: path.join(runtimeDataRoot, 'backups', 'claude-agents'),
  extension: '.md',
  readIdentity,
  readSecurity,
});

process.exit(status);
