#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import {
  PLAYER_RE,
  COACHES,
  atomicWriteJson,
  dataRoot,
  kstDateKey,
  readJsonLines,
  safeId
} from './ballclub-lib.mjs';

async function readStdin() {
  let input = '';
  for await (const chunk of process.stdin) input += chunk;
  return input ? JSON.parse(input) : {};
}

function hookResponse() {
  process.stdout.write(`${JSON.stringify({ continue: true, suppressOutput: true })}\n`);
}

function turnRows(rows, turnId) {
  const start = rows.findIndex(
    (row) => row.type === 'turn_context' && row.payload?.turn_id === turnId
  );
  if (start < 0) return rows;
  const next = rows.findIndex(
    (row, index) => index > start && row.type === 'turn_context'
  );
  return rows.slice(start, next < 0 ? undefined : next);
}

function addUsage(total, usage) {
  if (!usage || typeof usage !== 'object') return total;
  for (const [key, value] of Object.entries(usage)) {
    if (typeof value === 'number') total[key] = Number(total[key] || 0) + value;
  }
  return total;
}

function managerAppearance(hook, rows) {
  const currentRows = turnRows(rows, hook.turn_id);
  const toolNames = currentRows.flatMap((row) => {
    if (row.type !== 'response_item') return [];
    if (!['function_call', 'custom_tool_call'].includes(row.payload?.type)) return [];
    return [String(row.payload?.name || '')];
  });
  const delegationTools = new Set([
    'Agent',
    'followup_task',
    'interrupt_agent',
    'list_agents',
    'send_message',
    'spawn_agent',
    'wait_agent'
  ]);
  const delegated = toolNames.some((name) => delegationTools.has(name)) || currentRows.some(
    (row) => row.type === 'event_msg' && row.payload?.type === 'sub_agent_activity'
  );
  const routedToManager = currentRows.some((row) => {
    if (row.type !== 'response_item') return false;
    if (!['message', 'agent_message'].includes(row.payload?.type)) return false;
    const text = JSON.stringify(row.payload?.content || row.payload?.message || '');
    return /(?:LINEUP:\s*MANAGER|라우팅:\s*MAIN)/i.test(text);
  });
  const substantive = toolNames.length > 0 || routedToManager;
  if (delegated || !substantive) return null;

  const usage = currentRows
    .filter((row) => row.type === 'event_msg' && row.payload?.type === 'token_count')
    .reduce(
      (total, row) => addUsage(total, row.payload?.info?.last_token_usage),
      {}
    );
  return { currentRows, usage: Object.keys(usage).length ? usage : null };
}

try {
  const hook = await readStdin();
  const isManager = hook.hook_event_name === 'Stop';
  const agentType = isManager ? 'manager' : String(hook.agent_type || '');
  const isPlayer = PLAYER_RE.test(agentType);
  const isCoach = COACHES.has(agentType);

  if (!isManager && !isPlayer && !isCoach) {
    hookResponse();
    process.exit(0);
  }

  const transcriptPath = isManager ? hook.transcript_path : hook.agent_transcript_path;
  const rows = readJsonLines(transcriptPath);
  const sessionMeta = rows.find((row) => row.type === 'session_meta')?.payload || {};
  const manager = isManager ? managerAppearance(hook, rows) : null;
  if (isManager && !manager) {
    hookResponse();
    process.exit(0);
  }
  const relevantRows = manager?.currentRows || rows;
  const turnContexts = relevantRows.filter((row) => row.type === 'turn_context');
  const turnContext = turnContexts.at(-1)?.payload || {};
  const tokenEvents = relevantRows.filter(
    (row) => row.type === 'event_msg' && row.payload?.type === 'token_count'
  );
  const usage = manager?.usage || tokenEvents.at(-1)?.payload?.info?.total_token_usage || null;
  const endedAt = relevantRows.at(-1)?.timestamp || new Date().toISOString();
  const dateKey = kstDateKey(endedAt);
  const eventId = isManager
    ? `manager-${safeId(hook.turn_id, String(Date.now()))}`
    : `${safeId(hook.agent_id)}-${safeId(hook.turn_id, String(Date.now()))}`;
  const eventPath = path.join(dataRoot(), 'events', dateKey, `${eventId}.json`);

  const event = {
    schemaVersion: 1,
    eventId,
    recordedAt: new Date().toISOString(),
    endedAt,
    dateKey,
    parentSessionId: hook.session_id || sessionMeta.session_id || null,
    childSessionId: isManager ? null : sessionMeta.id || null,
    turnId: hook.turn_id || null,
    agentId: isManager ? null : hook.agent_id || null,
    agentType,
    agentNickname: sessionMeta.agent_nickname || null,
    category: isManager ? 'manager' : isPlayer ? 'player' : 'coach',
    model: turnContext.model || null,
    effort: turnContext.effort || turnContext.reasoning_effort || null,
    provider: sessionMeta.model_provider || null,
    salaryEligible: !isCoach,
    usage: isCoach ? null : usage,
    completionState: hook.last_assistant_message ? 'returned' : 'empty',
    transcriptPath: transcriptPath || null,
    score: !isCoach
      ? { result: 'unscored', homeRun: false, rbi: 0, evidence: null, reviewedAt: null }
      : { result: 'excluded', homeRun: false, rbi: 0, evidence: null, reviewedAt: null }
  };

  atomicWriteJson(eventPath, event);
  hookResponse();
} catch (error) {
  try {
    const errorDir = path.join(dataRoot(), 'errors');
    fs.mkdirSync(errorDir, { recursive: true });
    const errorPath = path.join(errorDir, `${Date.now()}-${process.pid}.json`);
    atomicWriteJson(errorPath, {
      recordedAt: new Date().toISOString(),
      message: error instanceof Error ? error.message : String(error)
    });
  } catch {
    // Recording must never block the subagent from finishing.
  }
  hookResponse();
}
