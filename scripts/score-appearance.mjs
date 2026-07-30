#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import { atomicWriteJson, dataRoot } from './ballclub-lib.mjs';

function parseArgs(argv) {
  const result = {};
  for (let index = 0; index < argv.length; index += 1) {
    const key = argv[index];
    if (!key.startsWith('--')) continue;
    result[key.slice(2)] = argv[index + 1];
    index += 1;
  }
  return result;
}

function fail(message) {
  process.stderr.write(`${message}\n`);
  process.exit(1);
}

const args = parseArgs(process.argv.slice(2));
const eventPath = path.resolve(args.event || '');
const allowedRoot = path.resolve(dataRoot(), 'events');
const allowedResults = new Set(['hit', 'walk', 'out', 'error', 'unscored']);

if (!eventPath || !fs.existsSync(eventPath)) fail('Existing --event path is required.');
if (eventPath !== allowedRoot && !eventPath.startsWith(`${allowedRoot}${path.sep}`)) {
  fail('Event path must stay inside the Ballclub events directory.');
}
if (!allowedResults.has(args.result)) fail('Use --result hit, walk, out, error, or unscored.');

const event = JSON.parse(fs.readFileSync(eventPath, 'utf8'));
if (!['player', 'manager'].includes(event.category)) {
  fail('Only player and manager appearances can receive scores.');
}

const homeRun = String(args['home-run'] || 'false').toLowerCase() === 'true';
const rbi = Number.parseInt(args.rbi || '0', 10);
if (!Number.isInteger(rbi) || rbi < 0) fail('--rbi must be a non-negative integer.');
if (homeRun && args.result !== 'hit') fail('A home run must also be a hit.');

event.score = {
  result: args.result,
  homeRun,
  rbi,
  evidence: args.evidence ? String(args.evidence).slice(0, 240) : null,
  reviewedAt: args.result === 'unscored' ? null : new Date().toISOString()
};

atomicWriteJson(eventPath, event);
process.stdout.write(`${JSON.stringify({ eventPath, score: event.score })}\n`);
