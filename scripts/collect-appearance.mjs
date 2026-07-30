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

try {
  const hook = await readStdin();
  const agentType = String(hook.agent_type || '');
  const isPlayer = PLAYER_RE.test(agentType);
  const isCoach = COACHES.has(agentType);

  if (!isPlayer && !isCoach) {
    hookResponse();
    process.exit(0);
  }

  const rows = readJsonLines(hook.agent_transcript_path);
  const sessionMeta = rows.find((row) => row.type === 'session_meta')?.payload || {};
  const turnContexts = rows.filter((row) => row.type === 'turn_context');
  const turnContext = turnContexts.at(-1)?.payload || {};
  const tokenEvents = rows.filter(
    (row) => row.type === 'event_msg' && row.payload?.type === 'token_count'
  );
  const usage = tokenEvents.at(-1)?.payload?.info?.total_token_usage || null;
  const endedAt = rows.at(-1)?.timestamp || new Date().toISOString();
  const dateKey = kstDateKey(endedAt);
  const eventId = `${safeId(hook.agent_id)}-${safeId(hook.turn_id, String(Date.now()))}`;
  const eventPath = path.join(dataRoot(), 'events', dateKey, `${eventId}.json`);

  const event = {
    schemaVersion: 1,
    eventId,
    recordedAt: new Date().toISOString(),
    endedAt,
    dateKey,
    parentSessionId: hook.session_id || sessionMeta.session_id || null,
    childSessionId: sessionMeta.id || null,
    turnId: hook.turn_id || null,
    agentId: hook.agent_id || null,
    agentType,
    agentNickname: sessionMeta.agent_nickname || null,
    category: isPlayer ? 'player' : 'coach',
    model: turnContext.model || null,
    effort: turnContext.effort || turnContext.reasoning_effort || null,
    provider: sessionMeta.model_provider || null,
    salaryEligible: isPlayer,
    usage: isPlayer ? usage : null,
    completionState: hook.last_assistant_message ? 'returned' : 'empty',
    transcriptPath: hook.agent_transcript_path || null,
    score: isPlayer
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
