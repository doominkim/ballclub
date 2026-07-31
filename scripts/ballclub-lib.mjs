import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const PLAYER_RE = /^(?:[1-5]setter|[1-4]batter|[1-3]bench)$/;
export const COACHES = new Set(['chief-coach', 'coach', 'assistant-coach']);

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const pluginRoot = path.resolve(scriptDir, '..');
const runtimeCache = new Map();

export function detectHarness(env = process.env) {
  const requested = env.BALLCLUB_HARNESS?.trim().toLowerCase();
  if (requested === 'codex' || requested === 'claude') return requested;
  if (env.CLAUDE_PLUGIN_ROOT) return 'claude';
  if (env.PLUGIN_ROOT || env.CODEX_THREAD_ID) return 'codex';
  return 'codex';
}

export function dataRoot(harness = detectHarness()) {
  if (process.env.BALLCLUB_DATA) return process.env.BALLCLUB_DATA;
  const configDir = harness === 'claude' ? '.claude' : '.codex';
  return path.join(os.homedir(), configDir, 'ballclub');
}

export function kstDateKey(value = new Date()) {
  const date = value instanceof Date ? value : new Date(value);
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Seoul',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  }).formatToParts(date);
  const get = (type) => parts.find((part) => part.type === type)?.value;
  return `${get('year')}-${get('month')}-${get('day')}`;
}

export function safeId(value, fallback = 'unknown') {
  const normalized = String(value || fallback).replace(/[^a-zA-Z0-9._-]/g, '-');
  return normalized || fallback;
}

export function readJsonLines(filePath) {
  if (!filePath || !fs.existsSync(filePath)) return [];
  return fs.readFileSync(filePath, 'utf8')
    .split(/\r?\n/)
    .filter(Boolean)
    .flatMap((line) => {
      try {
        return [JSON.parse(line)];
      } catch {
        return [];
      }
    });
}

export function atomicWriteJson(filePath, value) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  const tempPath = `${filePath}.${process.pid}.${Date.now()}.tmp`;
  fs.writeFileSync(tempPath, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
  fs.renameSync(tempPath, filePath);
}

export function collectJsonFiles(rootDir) {
  if (!fs.existsSync(rootDir)) return [];
  const result = [];
  const stack = [rootDir];
  while (stack.length) {
    const current = stack.pop();
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      const absolute = path.join(current, entry.name);
      if (entry.isDirectory()) stack.push(absolute);
      else if (entry.isFile() && entry.name.endsWith('.json')) result.push(absolute);
    }
  }
  return result.sort();
}

function readCanonicalRuntime(agentType, harness) {
  const isPlayer = PLAYER_RE.test(agentType || '');
  if (!isPlayer && !COACHES.has(agentType)) return null;

  const filePath = harness === 'claude'
    ? path.join(pluginRoot, 'rosters', 'claude', `${agentType}.md`)
    : path.join(pluginRoot, 'agents', 'codex', `${agentType}.toml`);
  if (!fs.existsSync(filePath)) return null;

  const value = fs.readFileSync(filePath, 'utf8');
  if (harness === 'claude') {
    const read = (key) => {
      const match = value.match(new RegExp(`^${key}:\\s*(?:"([^"]+)"|'([^']+)'|([^\\s#]+))\\s*$`, 'm'));
      return match?.[1] || match?.[2] || match?.[3] || null;
    };
    return { model: read('model'), effort: read('effort'), provider: 'anthropic' };
  }

  const read = (key) => value.match(new RegExp(`^${key}\\s*=\\s*"([^"]+)"\\s*$`, 'm'))?.[1] || null;
  return { model: read('model'), effort: read('model_reasoning_effort'), provider: 'openai' };
}

export function expectedRuntime(agentType, harness = detectHarness()) {
  const activeHarness = harness === 'claude' ? 'claude' : 'codex';
  const cacheKey = `${activeHarness}:${agentType || ''}`;
  if (!runtimeCache.has(cacheKey)) {
    runtimeCache.set(cacheKey, readCanonicalRuntime(agentType, activeHarness));
  }
  return runtimeCache.get(cacheKey);
}

export function formatNumber(value) {
  return new Intl.NumberFormat('ko-KR').format(Number(value || 0));
}

export function formatAverage(hits, atBats) {
  if (!atBats) return '-';
  return (hits / atBats).toFixed(3).replace(/^0/, '');
}
