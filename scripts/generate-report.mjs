#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import {
  PLAYER_RE,
  COACHES,
  collectJsonFiles,
  dataRoot,
  expectedRuntime,
  formatAverage,
  formatNumber,
  kstDateKey
} from './ballclub-lib.mjs';

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

function parseDateKey(value) {
  const match = /^(\d{4})-(\d{2})(?:-(\d{2}))?$/.exec(value || '');
  if (!match) throw new Error('--date must use YYYY-MM-DD or YYYY-MM.');
  return `${match[1]}-${match[2]}-${match[3] || '01'}`;
}

function addDays(dateKey, days) {
  const [year, month, day] = dateKey.split('-').map(Number);
  const date = new Date(Date.UTC(year, month - 1, day + days));
  return date.toISOString().slice(0, 10);
}

function isoWeek(dateKey) {
  const [year, month, day] = dateKey.split('-').map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  const weekday = date.getUTCDay() || 7;
  const monday = addDays(dateKey, 1 - weekday);
  const thursday = new Date(Date.UTC(year, month - 1, day + 4 - weekday));
  const isoYear = thursday.getUTCFullYear();
  const yearStart = new Date(Date.UTC(isoYear, 0, 1));
  const week = Math.ceil((((thursday - yearStart) / 86400000) + 1) / 7);
  return { monday, sunday: addDays(monday, 6), label: `${isoYear}-W${String(week).padStart(2, '0')}` };
}

function periodRange(period, anchor) {
  if (period === 'daily') return { start: anchor, end: anchor, label: anchor, korean: '일봉' };
  if (period === 'weekly') {
    const week = isoWeek(anchor);
    return { start: week.monday, end: week.sunday, label: week.label, korean: '주봉' };
  }
  const prefix = anchor.slice(0, 7);
  const [year, month] = prefix.split('-').map(Number);
  const lastDay = new Date(Date.UTC(year, month, 0)).getUTCDate();
  return {
    start: `${prefix}-01`,
    end: `${prefix}-${String(lastDay).padStart(2, '0')}`,
    label: prefix,
    korean: '월봉'
  };
}

function emptyPlayer(agentType) {
  return {
    agentType,
    pa: 0,
    ab: 0,
    hits: 0,
    homeRuns: 0,
    rbi: 0,
    walks: 0,
    strikeouts: 0,
    errors: 0,
    unscored: 0,
    tokens: 0,
    unscoredEvents: []
  };
}

function runtimeWarning(event) {
  const expected = expectedRuntime(event.agentType);
  if (!expected) return null;
  const mismatches = [];
  if (expected.model && event.model && event.model !== expected.model) {
    mismatches.push(`model ${event.model} (기대 ${expected.model})`);
  }
  if (expected.effort && event.effort && event.effort !== expected.effort) {
    mismatches.push(`effort ${event.effort} (기대 ${expected.effort})`);
  }
  if (expected.provider && event.provider && event.provider !== expected.provider) {
    mismatches.push(`provider ${event.provider} (기대 ${expected.provider})`);
  }
  return mismatches.length ? `${event.agentType}: ${mismatches.join(', ')}` : null;
}

function makeMarkdown(report) {
  const { range, players, coaches, warnings, totals } = report;
  const lines = [
    `# 구단 성적 ${range.korean} · ${range.label}`,
    '',
    `기간: ${range.start} ~ ${range.end} (Asia/Seoul)`,
    '',
    '| 선수 호출 | 타수 | 안타 | 팀 타율 | 홈런 | 실책 | 선수단 연봉 | 검수대기 |',
    '|---:|---:|---:|---:|---:|---:|---:|---:|',
    `| ${formatNumber(totals.pa)} | ${formatNumber(totals.ab)} | ${formatNumber(totals.hits)} | ${formatAverage(totals.hits, totals.ab)} | ${formatNumber(totals.homeRuns)} | ${formatNumber(totals.errors)} | ${formatNumber(totals.tokens)} token | ${formatNumber(totals.unscored)} |`,
    '',
    '## 선수 순위',
    ''
  ];

  if (!players.length) {
    lines.push('선수 기록 없음.');
  } else {
    lines.push('| 순위 | 선수 | PA | AB | H | HR | RBI | BB | SO | E | AVG | 연봉 | 안타당 token | 검수대기 |');
    lines.push('|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|');
    players.forEach((player, index) => {
      const tokenPerHit = player.hits ? Math.round(player.tokens / player.hits) : null;
      lines.push(`| ${index + 1} | \`${player.agentType}\` | ${player.pa} | ${player.ab} | ${player.hits} | ${player.homeRuns} | ${player.rbi} | ${player.walks} | ${player.strikeouts} | ${player.errors} | ${formatAverage(player.hits, player.ab)} | ${formatNumber(player.tokens)} | ${tokenPerHit === null ? '-' : formatNumber(tokenPerHit)} | ${player.unscored} |`);
    });
  }

  lines.push('', '## Coach 자문', '');
  if (!coaches.length) {
    lines.push('Coach 호출 없음.');
  } else {
    lines.push('| Coach | 자문 호출 |');
    lines.push('|---|---:|');
    for (const coach of coaches) lines.push(`| \`${coach.agentType}\` | ${coach.calls} |`);
    lines.push('', '> Coach token은 선수 연봉과 팀 총연봉에서 제외함.');
  }

  if (warnings.length) {
    lines.push('', '## 운영 경고', '');
    for (const warning of warnings) lines.push(`- ${warning}`);
  }

  lines.push('');
  return `${lines.join('\n')}\n`;
}

const args = parseArgs(process.argv.slice(2));
const periodAliases = {
  day: 'daily',
  daily: 'daily',
  week: 'weekly',
  weekly: 'weekly',
  month: 'monthly',
  monthly: 'monthly'
};
const period = periodAliases[args.period || 'daily'];
if (!period) throw new Error('--period must be daily, weekly, or monthly.');
const anchor = args.date ? parseDateKey(args.date) : kstDateKey();
const range = periodRange(period, anchor);
const eventsDir = path.join(dataRoot(), 'events');
const eventFiles = collectJsonFiles(eventsDir);
const events = eventFiles.flatMap((filePath) => {
  try {
    const event = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    return event.dateKey >= range.start && event.dateKey <= range.end
      ? [{ ...event, eventPath: filePath }]
      : [];
  } catch {
    return [];
  }
});

const playerMap = new Map();
const coachMap = new Map();
const warningSet = new Set();

for (const event of events) {
  const warning = runtimeWarning(event);
  if (warning) warningSet.add(warning);

  if (PLAYER_RE.test(event.agentType)) {
    const player = playerMap.get(event.agentType) || emptyPlayer(event.agentType);
    player.pa += 1;
    player.tokens += Number(event.usage?.total_tokens || 0);
    const result = event.score?.result || 'unscored';
    if (result === 'hit') {
      player.ab += 1;
      player.hits += 1;
      player.homeRuns += event.score?.homeRun ? 1 : 0;
      player.rbi += Number(event.score?.rbi || 0);
    } else if (result === 'walk') {
      player.walks += 1;
    } else if (result === 'out') {
      player.ab += 1;
      player.strikeouts += 1;
    } else if (result === 'error') {
      player.ab += 1;
      player.errors += 1;
    } else {
      player.unscored += 1;
      player.unscoredEvents.push(event.eventPath);
    }
    playerMap.set(event.agentType, player);
  } else if (COACHES.has(event.agentType)) {
    const coach = coachMap.get(event.agentType) || { agentType: event.agentType, calls: 0 };
    coach.calls += 1;
    coachMap.set(event.agentType, coach);
  }
}

const players = [...playerMap.values()].sort(
  (a, b) => b.hits - a.hits ||
    (b.ab ? b.hits / b.ab : 0) - (a.ab ? a.hits / a.ab : 0) ||
    b.pa - a.pa ||
    a.agentType.localeCompare(b.agentType)
);
const coaches = [...coachMap.values()].sort(
  (a, b) => b.calls - a.calls || a.agentType.localeCompare(b.agentType)
);
const totals = players.reduce((sum, player) => {
  for (const key of ['pa', 'ab', 'hits', 'homeRuns', 'errors', 'tokens', 'unscored']) {
    sum[key] += player[key];
  }
  return sum;
}, { pa: 0, ab: 0, hits: 0, homeRuns: 0, errors: 0, tokens: 0, unscored: 0 });

const reportDir = path.join(dataRoot(), 'reports', period);
const reportPath = path.join(reportDir, `${range.label}.md`);
const report = {
  period,
  range,
  totals,
  players,
  coaches,
  warnings: [...warningSet].sort(),
  reportPath
};
const markdown = makeMarkdown(report);
fs.mkdirSync(reportDir, { recursive: true });
fs.writeFileSync(reportPath, markdown, 'utf8');

if (args.format === 'json') process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
else process.stdout.write(`${reportPath}\n`);
