#!/usr/bin/env node

import crypto from 'node:crypto';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const pluginRoot = path.resolve(scriptDir, '..');
const sourceDir = path.join(pluginRoot, 'agents', 'codex');
const codexHome = path.resolve(process.env.CODEX_HOME || path.join(os.homedir(), '.codex'));
const targetDir = path.join(codexHome, 'agents');
const dataRoot = path.resolve(process.env.BALLCLUB_DATA || path.join(codexHome, 'ballclub'));
const statePath = path.join(dataRoot, 'config', 'codex-agent-state.json');

const args = new Set(process.argv.slice(2));
const install = args.has('--install');
const check = args.has('--check') || !install;
const force = args.has('--force');
const json = args.has('--json');

if (args.has('--help') || args.has('-h')) {
  console.log('Usage: node scripts/setup-codex-agents.mjs [--check|--install] [--force] [--json]');
  process.exit(0);
}

const allowed = new Set(['--check', '--install', '--force', '--json']);
const unknown = [...args].filter((arg) => !allowed.has(arg));
if (unknown.length > 0 || (args.has('--check') && args.has('--install')) || (force && !install)) {
  console.error('Invalid arguments. Use --help for usage.');
  process.exit(64);
}

function sha256(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function readIdentity(value) {
  if (value === null) return null;
  const read = (key) => value.match(new RegExp(`^${key}\\s*=\\s*"([^"]+)"\\s*$`, 'm'))?.[1] || null;
  const identity = {
    name: read('name'),
    model: read('model'),
    modelReasoningEffort: read('model_reasoning_effort'),
  };
  return Object.values(identity).every(Boolean) ? identity : null;
}

function sameIdentity(left, right) {
  return left && right
    && left.name === right.name
    && left.model === right.model
    && left.modelReasoningEffort === right.modelReasoningEffort;
}

async function readOptional(filePath) {
  try {
    return await fs.readFile(filePath, 'utf8');
  } catch (error) {
    if (error?.code === 'ENOENT') return null;
    throw error;
  }
}

async function loadState() {
  const raw = await readOptional(statePath);
  if (!raw) return { version: 1, files: {} };
  try {
    const parsed = JSON.parse(raw);
    if (parsed?.version === 1 && parsed.files && typeof parsed.files === 'object') return parsed;
  } catch {
    // An invalid state file must never authorize overwriting a user agent file.
  }
  return { version: 1, files: {} };
}

async function writeState(files) {
  await fs.mkdir(path.dirname(statePath), { recursive: true });
  const temporary = `${statePath}.${process.pid}.tmp`;
  await fs.writeFile(temporary, `${JSON.stringify({ version: 1, files }, null, 2)}\n`, 'utf8');
  await fs.rename(temporary, statePath);
}

async function loadProfiles(state) {
  const names = (await fs.readdir(sourceDir))
    .filter((name) => name.endsWith('.toml'))
    .sort((left, right) => left.localeCompare(right));

  return Promise.all(names.map(async (name) => {
    const sourcePath = path.join(sourceDir, name);
    const targetPath = path.join(targetDir, name);
    const source = await fs.readFile(sourcePath, 'utf8');
    const target = await readOptional(targetPath);
    const sourceHash = sha256(source);
    const targetHash = target === null ? null : sha256(target);
    const previousHash = state.files[name] || null;
    const sourceIdentity = readIdentity(source);
    const targetIdentity = readIdentity(target);

    let status = 'conflict';
    if (target === null) status = 'missing';
    else if (targetHash === sourceHash) status = 'current';
    else if (previousHash && targetHash === previousHash) status = 'managed-update';
    else if (sameIdentity(sourceIdentity, targetIdentity)) status = 'compatible';

    return { name, sourcePath, targetPath, source, target, sourceHash, targetHash, previousHash, status };
  }));
}

function summarize(profiles, installed = [], backedUp = []) {
  const counts = { missing: 0, current: 0, compatible: 0, 'managed-update': 0, conflict: 0 };
  for (const profile of profiles) counts[profile.status] += 1;
  return {
    codexHome,
    targetDir,
    statePath,
    counts,
    profiles: profiles.map(({ name, status }) => ({ name, status })),
    installed,
    backedUp,
  };
}

function printSummary(summary) {
  if (json) {
    console.log(JSON.stringify(summary, null, 2));
    return;
  }
  console.log(`Ballclub Codex agents: ${summary.targetDir}`);
  console.log(`current=${summary.counts.current} compatible=${summary.counts.compatible} missing=${summary.counts.missing} managed-update=${summary.counts['managed-update']} conflict=${summary.counts.conflict}`);
  for (const profile of summary.profiles) console.log(`${profile.status.padEnd(14)} ${profile.name}`);
  if (summary.installed.length > 0) console.log(`installed: ${summary.installed.join(', ')}`);
  if (summary.backedUp.length > 0) console.log(`backed up: ${summary.backedUp.join(', ')}`);
}

const state = await loadState();
const profiles = await loadProfiles(state);

if (check) {
  printSummary(summarize(profiles));
  process.exit(0);
}

await fs.mkdir(targetDir, { recursive: true });
const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
const backupDir = path.join(dataRoot, 'backups', 'codex-agents', timestamp);
const installedNames = [];
const backedUpNames = [];
const nextFiles = {};
let unresolvedConflicts = 0;

for (const profile of profiles) {
  if (profile.status === 'current') {
    nextFiles[profile.name] = profile.sourceHash;
    continue;
  }

  if (profile.status === 'compatible') continue;

  if (profile.status === 'conflict' && !force) {
    unresolvedConflicts += 1;
    if (profile.previousHash) nextFiles[profile.name] = profile.previousHash;
    continue;
  }

  if (profile.status === 'conflict' && force && profile.target !== null) {
    await fs.mkdir(backupDir, { recursive: true });
    await fs.writeFile(path.join(backupDir, profile.name), profile.target, 'utf8');
    backedUpNames.push(profile.name);
  }

  await fs.writeFile(profile.targetPath, profile.source, { encoding: 'utf8', mode: 0o600 });
  nextFiles[profile.name] = profile.sourceHash;
  installedNames.push(profile.name);
}

await writeState(nextFiles);
const finalProfiles = await loadProfiles({ version: 1, files: nextFiles });
const summary = summarize(finalProfiles, installedNames, backedUpNames);
printSummary(summary);

if (unresolvedConflicts > 0) {
  console.error('Conflicting Codex agent files were preserved. Re-run with --force only after explicit approval.');
  process.exit(2);
}
