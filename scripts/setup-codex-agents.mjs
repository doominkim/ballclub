#!/usr/bin/env node

import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';
import { dataRoot } from './ballclub-lib.mjs';
import { runAgentSetup } from './setup-agent-files.mjs';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const pluginRoot = path.resolve(scriptDir, '..');
const codexHome = path.resolve(process.env.CODEX_HOME || path.join(os.homedir(), '.codex'));
const runtimeDataRoot = path.resolve(dataRoot('codex'));

function readIdentity(value) {
  if (value === null) return null;
  const read = (key) => value.match(new RegExp(`^${key}\\s*=\\s*"([^"]+)"\\s*$`, 'm'))?.[1] || null;
  const identity = {
    name: read('name'),
    model: read('model'),
    effort: read('model_reasoning_effort'),
  };
  return Object.values(identity).every(Boolean) ? identity : null;
}

const status = await runAgentSetup({
  label: 'Codex',
  sourceDir: path.join(pluginRoot, 'agents', 'codex'),
  targetDir: path.join(codexHome, 'agents'),
  statePath: path.join(runtimeDataRoot, 'config', 'codex-agent-state.json'),
  backupRoot: path.join(runtimeDataRoot, 'backups', 'codex-agents'),
  extension: '.toml',
  readIdentity,
});

process.exit(status);
