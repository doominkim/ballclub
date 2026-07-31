#!/usr/bin/env node

import { spawnSync } from 'node:child_process';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';
import { detectHarness } from './ballclub-lib.mjs';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));

function emit(payload) {
  process.stdout.write(`${JSON.stringify(payload)}\n`);
}

const harness = detectHarness(process.env);
const setupScript = path.join(scriptDir, harness === 'claude'
  ? 'setup-claude-agents.mjs'
  : 'setup-codex-agents.mjs');
const result = spawnSync(process.execPath, [setupScript, '--install', '--json'], {
  encoding: 'utf8',
  env: process.env,
  stdio: ['ignore', 'pipe', 'pipe'],
});

if (result.error || (result.status !== 0 && result.status !== 2)) {
  emit({
    harness,
    status: 'degraded',
    reason: result.error?.message || result.stderr.trim() || `setup exited with ${result.status}`,
  });
  process.exit(0);
}

let summary;
try {
  summary = JSON.parse(result.stdout);
} catch {
  emit({ harness, status: 'degraded', reason: 'setup returned invalid JSON' });
  process.exit(0);
}

const conflicts = summary.profiles
  .filter((profile) => profile.status === 'conflict')
  .map((profile) => profile.name);
const installed = Array.isArray(summary.installed) ? summary.installed : [];
const warnings = summary.profiles.flatMap((profile) =>
  (profile.warnings || []).map((warning) => ({ profile: profile.name, ...warning }))
);

emit({
  harness,
  status: conflicts.length > 0 ? 'conflicts' : installed.length > 0 ? 'synced' : 'current',
  installed,
  conflicts,
  warnings,
  targetDir: summary.targetDir,
});
