import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

export const PLAYER_RE = /^(?:[1-5]setter|[1-4]batter|[1-3]bench)$/;
export const COACHES = new Set(['chief-coach', 'coach', 'assistant-coach']);

export function dataRoot() {
  return process.env.BALLCLUB_DATA || path.join(os.homedir(), '.codex', 'ballclub');
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

export function expectedRuntime(agentType) {
  const match = /^(\d)(setter|batter|bench)$/.exec(agentType || '');
  if (match) {
    const [, number, family] = match;
    const efforts = {
      setter: { '1': 'max', '2': 'xhigh', '3': 'high', '4': 'medium', '5': 'low' },
      batter: { '1': 'xhigh', '2': 'high', '3': 'medium', '4': 'low' },
      bench: { '1': 'high', '2': 'medium', '3': 'low' }
    };
    const models = {
      setter: 'gpt-5.6-sol',
      batter: 'gpt-5.6-terra',
      bench: 'gpt-5.6-luna'
    };
    return { model: models[family], effort: efforts[family][number], provider: 'openai' };
  }
  if (COACHES.has(agentType)) return { provider: 'anthropic' };
  return null;
}

export function formatNumber(value) {
  return new Intl.NumberFormat('ko-KR').format(Number(value || 0));
}

export function formatAverage(hits, atBats) {
  if (!atBats) return '-';
  return (hits / atBats).toFixed(3).replace(/^0/, '');
}
