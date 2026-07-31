import crypto from 'node:crypto';
import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

function sha256(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

async function readOptional(filePath) {
  try {
    return await fs.readFile(filePath, 'utf8');
  } catch (error) {
    if (error?.code === 'ENOENT') return null;
    throw error;
  }
}

export async function runAgentSetup({
  label,
  sourceDir,
  targetDir,
  statePath,
  backupRoot,
  extension,
  readIdentity,
  readSecurity = () => null,
}) {
  const args = new Set(process.argv.slice(2));
  const install = args.has('--install');
  const check = args.has('--check') || !install;
  const force = args.has('--force');
  const json = args.has('--json');

  if (args.has('--help') || args.has('-h')) {
    console.log(`Usage: node ${path.basename(process.argv[1])} [--check|--install] [--force] [--json]`);
    return 0;
  }

  const allowed = new Set(['--check', '--install', '--force', '--json']);
  const unknown = [...args].filter((arg) => !allowed.has(arg));
  if (unknown.length > 0 || (args.has('--check') && args.has('--install')) || (force && !install)) {
    console.error('Invalid arguments. Use --help for usage.');
    return 64;
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
      .filter((name) => name.endsWith(extension))
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
      const sourceSecurity = readSecurity(source);
      const targetSecurity = readSecurity(target);

      let status = 'conflict';
      if (target === null) status = 'missing';
      else if (targetHash === sourceHash) status = 'current';
      else if (previousHash && targetHash === previousHash) status = 'managed-update';
      else if (sourceIdentity && targetIdentity
        && Object.keys(sourceIdentity).every((key) => sourceIdentity[key] === targetIdentity[key])) status = 'compatible';

      const warnings = [];
      if (status === 'compatible' && sourceSecurity && targetSecurity) {
        const fields = Object.keys(sourceSecurity)
          .filter((key) => JSON.stringify(sourceSecurity[key]) !== JSON.stringify(targetSecurity[key]));
        if (fields.length > 0) warnings.push({ code: 'security-drift', fields });
      }

      return { name, targetPath, source, target, sourceHash, targetHash, previousHash, status, warnings };
    }));
  }

  function summarize(profiles, installed = [], backedUp = []) {
    const counts = { missing: 0, current: 0, compatible: 0, 'managed-update': 0, conflict: 0 };
    for (const profile of profiles) counts[profile.status] += 1;
    return {
      targetDir,
      statePath,
      counts,
      profiles: profiles.map(({ name, status, warnings }) => ({ name, status, warnings })),
      installed,
      backedUp,
    };
  }

  function printSummary(summary) {
    if (json) {
      console.log(JSON.stringify(summary, null, 2));
      return;
    }
    console.log(`Ballclub ${label} agents: ${summary.targetDir}`);
    console.log(`current=${summary.counts.current} compatible=${summary.counts.compatible} missing=${summary.counts.missing} managed-update=${summary.counts['managed-update']} conflict=${summary.counts.conflict}`);
    for (const profile of summary.profiles) {
      console.log(`${profile.status.padEnd(14)} ${profile.name}`);
      for (const warning of profile.warnings) {
        console.warn(`warning        ${profile.name} ${warning.code}: ${warning.fields.join(', ')}`);
      }
    }
    if (summary.installed.length > 0) console.log(`installed: ${summary.installed.join(', ')}`);
    if (summary.backedUp.length > 0) console.log(`backed up: ${summary.backedUp.join(', ')}`);
  }

  const state = await loadState();
  const profiles = await loadProfiles(state);

  if (check) {
    printSummary(summarize(profiles));
    return 0;
  }

  await fs.mkdir(targetDir, { recursive: true });
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupDir = path.join(backupRoot, timestamp);
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
    console.error(`Conflicting ${label} agent files were preserved. Re-run with --force only after explicit approval.`);
    return 2;
  }
  return 0;
}
