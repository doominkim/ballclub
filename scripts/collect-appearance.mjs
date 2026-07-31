#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import {
  PLAYER_RE,
  COACHES,
  atomicWriteJson,
  dataRoot,
  detectHarness,
  expectedRuntime,
  kstDateKey,
  readJsonLines,
  safeId
} from './ballclub-lib.mjs';

const CLAUDE_USAGE_FIELDS = [
  'input_tokens',
  'output_tokens',
  'cache_read_input_tokens',
  'cache_creation_input_tokens'
];

let activeHarness = detectHarness();

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

function hasOwn(value, key) {
  return Object.prototype.hasOwnProperty.call(value || {}, key);
}

function transcriptHarness(rows, fallback) {
  if (rows.some((row) => hasOwn(row, 'payload'))) return 'codex';
  if (rows.some((row) => ['assistant', 'user', 'attachment'].includes(row.type))) return 'claude';
  return fallback;
}

function latestValue(rows, key) {
  return rows.findLast((row) => row?.[key] !== null && row?.[key] !== undefined)?.[key] || null;
}

function claudeUsage(assistantRows) {
  const snapshots = new Map();
  for (const row of assistantRows) {
    const rawUsage = row.message?.usage;
    if (rawUsage === null || rawUsage === undefined) continue;
    if (typeof rawUsage !== 'object' || Array.isArray(rawUsage)) {
      return {
        usage: null,
        provenance: 'claude-message-usage:ambiguous',
        warnings: ['Claude usage omitted because a message usage record was structurally ambiguous.']
      };
    }

    const messageId = row.message?.id;
    const requestId = row.requestId;
    if (!messageId && !requestId) {
      return {
        usage: null,
        provenance: 'claude-message-usage:ambiguous',
        warnings: ['Claude usage omitted because a message snapshot had no message.id or requestId.']
      };
    }

    const normalized = {};
    let recognized = false;
    for (const field of CLAUDE_USAGE_FIELDS) {
      if (!hasOwn(rawUsage, field)) {
        normalized[field] = 0;
        continue;
      }
      if (typeof rawUsage[field] !== 'number' || !Number.isFinite(rawUsage[field])) {
        return {
          usage: null,
          provenance: 'claude-message-usage:ambiguous',
          warnings: [`Claude usage omitted because ${field} was not numeric.`]
        };
      }
      recognized = true;
      normalized[field] = rawUsage[field];
    }
    if (!recognized) {
      return {
        usage: null,
        provenance: 'claude-message-usage:ambiguous',
        warnings: ['Claude usage omitted because a message usage record had no recognized token fields.']
      };
    }

    const key = messageId ? `message:${messageId}` : `request:${requestId}`;
    snapshots.set(key, normalized);
  }

  if (!snapshots.size) {
    return {
      usage: null,
      provenance: 'claude-message-usage:unavailable',
      warnings: []
    };
  }

  const usage = Object.fromEntries(CLAUDE_USAGE_FIELDS.map((field) => [field, 0]));
  for (const snapshot of snapshots.values()) addUsage(usage, snapshot);
  usage.total_tokens = CLAUDE_USAGE_FIELDS.reduce((sum, field) => sum + usage[field], 0);
  return {
    usage,
    provenance: 'claude-message-usage:last-snapshot-per-message',
    warnings: []
  };
}

function claudePromptRows(rows, promptId) {
  if (!promptId) return rows;
  const start = rows.findIndex((row) => row.type === 'user' && row.promptId === promptId);
  if (start < 0) return rows;
  const next = rows.findIndex(
    (row, index) => index > start && row.type === 'user' && row.promptId && row.promptId !== promptId
  );
  return rows.slice(start, next < 0 ? undefined : next);
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

function claudeManagerAppearance(hook, rows) {
  const promptId = hook.promptId || hook.prompt_id || latestValue(rows, 'promptId');
  const currentRows = claudePromptRows(rows, promptId);
  const toolNames = currentRows.flatMap((row) => {
    if (row.type !== 'assistant' || !Array.isArray(row.message?.content)) return [];
    return row.message.content
      .filter((item) => item?.type === 'tool_use')
      .map((item) => String(item.name || ''));
  });
  const delegated = toolNames.some((name) => name === 'Agent' || name === 'Task');
  const routedToManager = currentRows.some((row) => {
    if (row.type !== 'assistant' || !Array.isArray(row.message?.content)) return false;
    const text = row.message.content
      .filter((item) => item?.type === 'text')
      .map((item) => item.text || '')
      .join('\n');
    return /(?:LINEUP:\s*MANAGER|라우팅:\s*MAIN)/i.test(text);
  });
  const substantive = toolNames.length > 0 || routedToManager;
  if (delegated || !substantive) return null;
  return { currentRows, promptId };
}

function parseCodex(rows, hook, isManager) {
  const sessionMeta = rows.find((row) => row.type === 'session_meta')?.payload || {};
  const manager = isManager ? managerAppearance(hook, rows) : null;
  if (isManager && !manager) return null;
  const relevantRows = manager?.currentRows || rows;
  const turnContext = relevantRows.filter((row) => row.type === 'turn_context').at(-1)?.payload || {};
  const tokenEvents = relevantRows.filter(
    (row) => row.type === 'event_msg' && row.payload?.type === 'token_count'
  );
  return {
    sessionMeta,
    relevantRows,
    turnId: hook.turn_id || turnContext.turn_id || null,
    agentId: hook.agent_id || null,
    model: turnContext.model || null,
    effort: turnContext.effort || turnContext.reasoning_effort || null,
    usage: manager?.usage || tokenEvents.at(-1)?.payload?.info?.total_token_usage || null,
    usageProvenance: manager
      ? 'codex-token-count:turn-sum'
      : 'codex-token-count:latest-total',
    warnings: []
  };
}

function parseClaude(rows, hook, isManager) {
  const manager = isManager ? claudeManagerAppearance(hook, rows) : null;
  if (isManager && !manager) return null;
  const relevantRows = manager?.currentRows || rows;
  const assistantRows = relevantRows.filter(
    (row) => row.type === 'assistant' && row.message && typeof row.message === 'object'
  );
  const lastAssistant = assistantRows.at(-1);
  const usage = claudeUsage(assistantRows);
  const sessionId = latestValue(relevantRows, 'sessionId');
  const agentId = hook.agent_id || latestValue(relevantRows, 'agentId');
  const promptId = hook.turn_id || hook.promptId || hook.prompt_id || manager?.promptId || latestValue(relevantRows, 'promptId');
  return {
    sessionMeta: { session_id: sessionId },
    relevantRows,
    turnId: promptId,
    agentId,
    model: lastAssistant?.message?.model || null,
    effort: hook.effort?.level || latestValue(assistantRows, 'effort'),
    usage: usage.usage,
    usageProvenance: !isManager && usage.provenance.endsWith(':unavailable')
      ? 'claude-parent-reconciliation:pending'
      : usage.provenance,
    warnings: !isManager && usage.provenance.endsWith(':unavailable')
      ? ['Claude runtime usage awaits reconciliation from the parent Agent result.']
      : usage.warnings
  };
}

function reconcileClaudePlayerEvents(rows) {
  for (const row of rows) {
    const result = row.toolUseResult;
    if (!result?.agentId || !result?.agentType || !row.promptId) continue;
    if (!PLAYER_RE.test(result.agentType) && !COACHES.has(result.agentType)) continue;

    const eventPath = path.join(
      dataRoot('claude'),
      'events',
      kstDateKey(row.timestamp || new Date()),
      `${safeId(result.agentId)}-${safeId(row.promptId)}.json`
    );
    if (!fs.existsSync(eventPath)) continue;

    let event;
    try {
      event = JSON.parse(fs.readFileSync(eventPath, 'utf8'));
    } catch {
      continue;
    }
    if (event.agentId !== result.agentId || event.turnId !== row.promptId) continue;

    const isCoach = COACHES.has(result.agentType);
    const reconciledUsage = result.usage
      ? claudeUsage([{ requestId: `parent:${result.agentId}`, message: { usage: result.usage } }])
      : { usage: null, warnings: ['Claude parent Agent result did not include usage.'] };
    event.model = result.resolvedModel || event.model || null;
    event.usage = isCoach ? null : reconciledUsage.usage;
    event.collection = {
      transcriptSchema: 'claude',
      usageProvenance: isCoach
        ? 'excluded:coach'
        : reconciledUsage.usage
          ? 'claude-parent-agent-result'
          : 'claude-parent-agent-result:unavailable',
      warnings: isCoach ? [] : reconciledUsage.warnings
    };
    atomicWriteJson(eventPath, event);
  }
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
  activeHarness = transcriptHarness(rows, activeHarness);
  if (isManager && activeHarness === 'claude') reconcileClaudePlayerEvents(rows);
  const runtime = activeHarness === 'claude'
    ? parseClaude(rows, hook, isManager)
    : parseCodex(rows, hook, isManager);
  if (!runtime) {
    hookResponse();
    process.exit(0);
  }
  const declaredRuntime = expectedRuntime(agentType, activeHarness);
  const turnId = runtime.turnId || null;
  const agentId = isManager ? null : runtime.agentId || hook.agent_id || null;
  const endedAt = runtime.relevantRows.at(-1)?.timestamp || new Date().toISOString();
  const dateKey = kstDateKey(endedAt);
  const eventId = isManager
    ? `manager-${safeId(turnId, String(Date.now()))}`
    : `${safeId(agentId)}-${safeId(turnId, String(Date.now()))}`;
  const eventPath = path.join(dataRoot(activeHarness), 'events', dateKey, `${eventId}.json`);

  const event = {
    schemaVersion: 1,
    eventId,
    harness: activeHarness,
    recordedAt: new Date().toISOString(),
    endedAt,
    dateKey,
    parentSessionId: hook.session_id || runtime.sessionMeta.session_id || null,
    childSessionId: isManager || activeHarness === 'claude' ? null : runtime.sessionMeta.id || null,
    turnId,
    agentId,
    agentType,
    agentNickname: runtime.sessionMeta.agent_nickname || null,
    category: isManager ? 'manager' : isPlayer ? 'player' : 'coach',
    model: runtime.model || null,
    effort: runtime.effort || declaredRuntime?.effort || null,
    provider: activeHarness === 'claude' ? 'anthropic' : 'openai',
    salaryEligible: !isCoach,
    usage: isCoach ? null : runtime.usage,
    collection: {
      transcriptSchema: activeHarness,
      usageProvenance: isCoach ? 'excluded:coach' : runtime.usageProvenance,
      warnings: isCoach ? [] : runtime.warnings
    },
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
    const errorDir = path.join(dataRoot(activeHarness), 'errors');
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
