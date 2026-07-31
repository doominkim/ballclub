#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
transcript="${test_dir}/player.jsonl"
manager_transcript="${test_dir}/manager.jsonl"
delegated_transcript="${test_dir}/delegated.jsonl"
routine_transcript="${test_dir}/routine.jsonl"
claude_transcript="${repo_root}/tests/scorebook/fixtures/claude-player.jsonl"
ambiguous_claude_transcript="${test_dir}/ambiguous-claude.jsonl"
claude_manager_transcript="${test_dir}/claude-manager.jsonl"

printf '%s\n' \
  '{"timestamp":"2026-07-30T01:00:00.000Z","type":"session_meta","payload":{"id":"child-1","model_provider":"openai","agent_nickname":"player"}}' \
  '{"timestamp":"2026-07-30T01:00:01.000Z","type":"turn_context","payload":{"model":"gpt-5.6-sol","effort":"medium"}}' \
  '{"timestamp":"2026-07-30T01:00:02.000Z","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"total_tokens":1200}}}}' \
  > "$transcript"

hook_input="$(node --input-type=module -e '
  const path = process.argv[1];
  process.stdout.write(JSON.stringify({
    agent_type: "4setter",
    agent_id: "agent-1",
    turn_id: "turn-1",
    session_id: "parent-1",
    agent_transcript_path: path,
    last_assistant_message: "completed"
  }));
' "$transcript")"

collector_output="$(printf '%s' "$hook_input" | BALLCLUB_DATA="$test_dir/data" node "$repo_root/scripts/collect-appearance.mjs")"
[[ "$collector_output" == *'"continue":true'* ]]

event_path="${test_dir}/data/events/2026-07-30/agent-1-turn-1.json"
[[ -f "$event_path" ]]

BALLCLUB_DATA="$test_dir/data" node "$repo_root/scripts/score-appearance.mjs" \
  --event "$event_path" --result hit --home-run false --rbi 1 \
  --evidence "focused verification passed" >/dev/null

report_path="$(BALLCLUB_DATA="$test_dir/data" node "$repo_root/scripts/generate-report.mjs" --period daily --date 2026-07-30)"
[[ -f "$report_path" ]]
rg -q '\| 1 \| 1 \| 1 \| 1.000 \| 0 \| 0 \| 1,200 token \| 0 \|' "$report_path"
rg -q '`4setter`' "$report_path"

claude_hook_input="$(node --input-type=module -e '
  const path = process.argv[1];
  process.stdout.write(JSON.stringify({
    agent_type: "3setter",
    agent_id: "claude-agent-1",
    session_id: "claude-parent-1",
    agent_transcript_path: path,
    last_assistant_message: "completed"
  }));
' "$claude_transcript")"

claude_output="$(printf '%s' "$claude_hook_input" | CLAUDE_PLUGIN_ROOT="$repo_root" BALLCLUB_DATA="$test_dir/claude-data" node "$repo_root/scripts/collect-appearance.mjs")"
[[ "$claude_output" == *'"continue":true'* ]]

claude_event_path="${test_dir}/claude-data/events/2026-07-30/claude-agent-1-claude-prompt-1.json"
[[ -f "$claude_event_path" ]]
node -e '
  const event = JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"));
  const expectedUsage = {
    input_tokens: 15,
    output_tokens: 27,
    cache_read_input_tokens: 14,
    cache_creation_input_tokens: 17,
    total_tokens: 73
  };
  if (event.harness !== "claude") throw new Error("Claude harness missing");
  if (event.model !== "claude-fable-5") throw new Error("Claude model was not normalized");
  if (event.effort !== "high") throw new Error("Claude roster effort fallback failed");
  if (event.provider !== "anthropic") throw new Error("Claude provider missing");
  if (event.turnId !== "claude-prompt-1") throw new Error("Claude promptId fallback failed");
  for (const [key, value] of Object.entries(expectedUsage)) {
    if (event.usage?.[key] !== value) throw new Error(`Claude ${key} was ${event.usage?.[key]}`);
  }
  if (event.collection?.usageProvenance !== "claude-message-usage:last-snapshot-per-message") {
    throw new Error("Claude usage provenance missing");
  }
  if (event.collection?.warnings?.length) throw new Error("unexpected Claude collection warning");
' "$claude_event_path"

node -e '
  const fs = require("node:fs");
  const path = require("node:path");
  const source = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  source.eventId = "claude-runtime-mismatch";
  source.agentId = "claude-agent-2";
  source.model = "claude-opus-4-1";
  source.effort = "low";
  fs.writeFileSync(path.join(path.dirname(process.argv[1]), "claude-runtime-mismatch.json"), `${JSON.stringify(source)}\n`);
' "$claude_event_path"

claude_report_path="$(BALLCLUB_DATA="$test_dir/claude-data" BALLCLUB_HARNESS=claude node "$repo_root/scripts/generate-report.mjs" --period daily --date 2026-07-30)"
rg -Fq '3setter: model claude-opus-4-1 (기대 fable), effort low (기대 high)' "$claude_report_path"
if rg -Fq 'model claude-fable-5 (기대 fable)' "$claude_report_path"; then
  printf '%s\n' 'compatible Claude model alias produced a warning' >&2
  exit 1
fi

printf '%s\n' \
  '{"timestamp":"2026-07-30T01:10:00.000Z","type":"user","sessionId":"claude-session-2","agentId":"claude-agent-2","promptId":"claude-prompt-2","message":{"role":"user","content":"task"}}' \
  '{"timestamp":"2026-07-30T01:10:01.000Z","type":"assistant","sessionId":"claude-session-2","agentId":"claude-agent-2","effort":"medium","message":{"model":"claude-sonnet-4","usage":{"input_tokens":1,"output_tokens":2}}}' \
  > "$ambiguous_claude_transcript"

ambiguous_hook_input="$(node --input-type=module -e '
  const path = process.argv[1];
  process.stdout.write(JSON.stringify({
    agent_type: "2bench",
    agent_id: "claude-agent-2",
    agent_transcript_path: path,
    last_assistant_message: "completed"
  }));
' "$ambiguous_claude_transcript")"
printf '%s' "$ambiguous_hook_input" | BALLCLUB_DATA="$test_dir/ambiguous-data" node "$repo_root/scripts/collect-appearance.mjs" >/dev/null
ambiguous_event_path="${test_dir}/ambiguous-data/events/2026-07-30/claude-agent-2-claude-prompt-2.json"
node -e '
  const event = JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"));
  if (event.usage !== null) throw new Error("ambiguous Claude usage must stay null");
  if (!event.collection?.warnings?.[0]?.includes("no message.id or requestId")) {
    throw new Error("ambiguous Claude usage warning missing");
  }
' "$ambiguous_event_path"
ambiguous_report="$(BALLCLUB_DATA="$test_dir/ambiguous-data" BALLCLUB_HARNESS=claude node "$repo_root/scripts/generate-report.mjs" --period daily --date 2026-07-30)"
rg -Fq 'no message.id or requestId' "$ambiguous_report"

mkdir -p "$test_dir/default-home"
printf '%s' "$claude_hook_input" | HOME="$test_dir/default-home" CLAUDE_PLUGIN_ROOT="$repo_root" node "$repo_root/scripts/collect-appearance.mjs" >/dev/null
[[ -f "$test_dir/default-home/.claude/ballclub/events/2026-07-30/claude-agent-1-claude-prompt-1.json" ]]
[[ ! -e "$test_dir/default-home/.codex/ballclub/events/2026-07-30/claude-agent-1-claude-prompt-1.json" ]]

printf '%s' "$hook_input" | HOME="$test_dir/default-home" PLUGIN_ROOT="$repo_root" node "$repo_root/scripts/collect-appearance.mjs" >/dev/null
[[ -f "$test_dir/default-home/.codex/ballclub/events/2026-07-30/agent-1-turn-1.json" ]]

printf '%s\n' \
  '{"timestamp":"2026-07-30T01:20:00.000Z","type":"user","sessionId":"claude-manager-session","promptId":"claude-manager-prompt","message":{"role":"user","content":"direct work"}}' \
  '{"timestamp":"2026-07-30T01:20:01.000Z","type":"assistant","sessionId":"claude-manager-session","requestId":"manager-request","effort":"xhigh","message":{"id":"manager-message","model":"claude-fable-5","usage":{"input_tokens":2,"output_tokens":3,"cache_read_input_tokens":4,"cache_creation_input_tokens":5},"content":[{"type":"tool_use","name":"Bash"}]}}' \
  > "$claude_manager_transcript"
claude_manager_hook="$(node --input-type=module -e '
  const path = process.argv[1];
  process.stdout.write(JSON.stringify({
    hook_event_name: "Stop",
    session_id: "claude-manager-session",
    transcript_path: path,
    last_assistant_message: "completed"
  }));
' "$claude_manager_transcript")"
printf '%s' "$claude_manager_hook" | BALLCLUB_DATA="$test_dir/claude-manager-data" node "$repo_root/scripts/collect-appearance.mjs" >/dev/null
claude_manager_event="${test_dir}/claude-manager-data/events/2026-07-30/manager-claude-manager-prompt.json"
node -e '
  const event = JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"));
  if (event.category !== "manager" || event.harness !== "claude") throw new Error("Claude manager identity missing");
  if (event.usage?.total_tokens !== 14) throw new Error("Claude manager token normalization failed");
' "$claude_manager_event"

sed 's/"name":"Bash"/"name":"Task"/' "$claude_manager_transcript" > "$test_dir/claude-delegated.jsonl"
claude_delegated_hook="$(node --input-type=module -e '
  const path = process.argv[1];
  process.stdout.write(JSON.stringify({
    hook_event_name: "Stop",
    session_id: "claude-manager-session",
    transcript_path: path,
    last_assistant_message: "completed"
  }));
' "$test_dir/claude-delegated.jsonl")"
printf '%s' "$claude_delegated_hook" | BALLCLUB_DATA="$test_dir/claude-delegated-data" node "$repo_root/scripts/collect-appearance.mjs" >/dev/null
[[ ! -d "$test_dir/claude-delegated-data/events" ]]

printf '%s\n' \
  '{"timestamp":"2026-07-30T01:30:00.000Z","type":"user","sessionId":"claude-race-session","agentId":"claude-race-agent","promptId":"claude-race-prompt","message":{"role":"user","content":"task"}}' \
  > "$test_dir/claude-race-child.jsonl"
race_child_hook="$(node --input-type=module -e '
  const path = process.argv[1];
  process.stdout.write(JSON.stringify({
    hook_event_name: "SubagentStop",
    agent_type: "5setter",
    agent_id: "claude-race-agent",
    agent_transcript_path: path,
    effort: { level: "low" },
    last_assistant_message: "done"
  }));
' "$test_dir/claude-race-child.jsonl")"
printf '%s' "$race_child_hook" | BALLCLUB_DATA="$test_dir/claude-race-data" node "$repo_root/scripts/collect-appearance.mjs" >/dev/null
race_event="$test_dir/claude-race-data/events/2026-07-30/claude-race-agent-claude-race-prompt.json"
node -e '
  const event = JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"));
  if (event.model !== null || event.usage !== null || event.effort !== "low") throw new Error("race event should await parent reconciliation");
  if (event.collection?.usageProvenance !== "claude-parent-reconciliation:pending") throw new Error("pending reconciliation marker missing");
' "$race_event"

printf '%s\n' \
  '{"timestamp":"2026-07-30T01:29:59.000Z","type":"user","sessionId":"claude-race-session","promptId":"claude-race-prompt","message":{"role":"user","content":"delegate"}}' \
  '{"timestamp":"2026-07-30T01:30:00.000Z","type":"assistant","sessionId":"claude-race-session","requestId":"race-parent-request","effort":"xhigh","message":{"id":"race-parent-message","model":"claude-opus-5","usage":{"input_tokens":1,"output_tokens":2},"content":[{"type":"tool_use","name":"Agent"}]}}' \
  '{"timestamp":"2026-07-30T01:30:01.000Z","type":"user","sessionId":"claude-race-session","promptId":"claude-race-prompt","message":{"role":"user","content":[{"type":"tool_result"}]},"toolUseResult":{"agentId":"claude-race-agent","agentType":"5setter","resolvedModel":"claude-fable-5","usage":{"input_tokens":2,"output_tokens":3,"cache_read_input_tokens":4,"cache_creation_input_tokens":5}}}' \
  > "$test_dir/claude-race-parent.jsonl"
race_parent_hook="$(node --input-type=module -e '
  const path = process.argv[1];
  process.stdout.write(JSON.stringify({
    hook_event_name: "Stop",
    session_id: "claude-race-session",
    transcript_path: path,
    last_assistant_message: "done"
  }));
' "$test_dir/claude-race-parent.jsonl")"
printf '%s' "$race_parent_hook" | BALLCLUB_DATA="$test_dir/claude-race-data" node "$repo_root/scripts/collect-appearance.mjs" >/dev/null
node -e '
  const event = JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"));
  if (event.model !== "claude-fable-5" || event.usage?.total_tokens !== 14) throw new Error("parent reconciliation failed");
  if (event.collection?.usageProvenance !== "claude-parent-agent-result") throw new Error("parent provenance missing");
  if (event.collection?.warnings?.length) throw new Error("unexpected reconciliation warning");
' "$race_event"

printf '%s\n' \
  '{"timestamp":"2026-07-30T02:00:00.000Z","type":"session_meta","payload":{"id":"parent-1","model_provider":"openai"}}' \
  '{"timestamp":"2026-07-30T02:00:01.000Z","type":"turn_context","payload":{"turn_id":"turn-2","model":"gpt-5.6-sol","effort":"medium"}}' \
  '{"timestamp":"2026-07-30T02:00:02.000Z","type":"response_item","payload":{"type":"custom_tool_call","name":"exec"}}' \
  '{"timestamp":"2026-07-30T02:00:03.000Z","type":"event_msg","payload":{"type":"token_count","info":{"last_token_usage":{"total_tokens":300}}}}' \
  '{"timestamp":"2026-07-30T02:00:04.000Z","type":"event_msg","payload":{"type":"token_count","info":{"last_token_usage":{"total_tokens":400}}}}' \
  > "$manager_transcript"

manager_hook_input="$(node --input-type=module -e '
  const path = process.argv[1];
  process.stdout.write(JSON.stringify({
    hook_event_name: "Stop",
    turn_id: "turn-2",
    session_id: "parent-1",
    transcript_path: path,
    last_assistant_message: "completed"
  }));
' "$manager_transcript")"

manager_output="$(printf '%s' "$manager_hook_input" | BALLCLUB_DATA="$test_dir/data" node "$repo_root/scripts/collect-appearance.mjs")"
[[ "$manager_output" == *'"continue":true'* ]]

manager_event_path="${test_dir}/data/events/2026-07-30/manager-turn-2.json"
[[ -f "$manager_event_path" ]]
node -e '
  const event = JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"));
  if (event.category !== "manager") throw new Error("manager category missing");
  if (event.usage?.total_tokens !== 700) throw new Error("manager turn token sum is wrong");
' "$manager_event_path"

BALLCLUB_DATA="$test_dir/data" node "$repo_root/scripts/score-appearance.mjs" \
  --event "$manager_event_path" --result hit --home-run false --rbi 0 \
  --evidence "manager verification passed" >/dev/null

printf '%s\n' \
  '{"timestamp":"2026-07-30T03:00:00.000Z","type":"session_meta","payload":{"id":"parent-1","model_provider":"openai"}}' \
  '{"timestamp":"2026-07-30T03:00:01.000Z","type":"turn_context","payload":{"turn_id":"turn-3","model":"gpt-5.6-sol","effort":"medium"}}' \
  '{"timestamp":"2026-07-30T03:00:02.000Z","type":"response_item","payload":{"type":"function_call","name":"spawn_agent"}}' \
  > "$delegated_transcript"

delegated_hook_input="$(node --input-type=module -e '
  const path = process.argv[1];
  process.stdout.write(JSON.stringify({
    hook_event_name: "Stop",
    turn_id: "turn-3",
    session_id: "parent-1",
    transcript_path: path,
    last_assistant_message: "integrated"
  }));
' "$delegated_transcript")"

printf '%s' "$delegated_hook_input" | BALLCLUB_DATA="$test_dir/data" node "$repo_root/scripts/collect-appearance.mjs" >/dev/null
[[ ! -e "${test_dir}/data/events/2026-07-30/manager-turn-3.json" ]]

printf '%s\n' \
  '{"timestamp":"2026-07-30T04:00:00.000Z","type":"session_meta","payload":{"id":"parent-1","model_provider":"openai"}}' \
  '{"timestamp":"2026-07-30T04:00:01.000Z","type":"turn_context","payload":{"turn_id":"turn-4","model":"gpt-5.6-sol","effort":"medium"}}' \
  '{"timestamp":"2026-07-30T04:00:02.000Z","type":"response_item","payload":{"type":"message","content":"short status"}}' \
  > "$routine_transcript"

routine_hook_input="$(node --input-type=module -e '
  const path = process.argv[1];
  process.stdout.write(JSON.stringify({
    hook_event_name: "Stop",
    turn_id: "turn-4",
    session_id: "parent-1",
    transcript_path: path,
    last_assistant_message: "short status"
  }));
' "$routine_transcript")"

printf '%s' "$routine_hook_input" | BALLCLUB_DATA="$test_dir/data" node "$repo_root/scripts/collect-appearance.mjs" >/dev/null
[[ ! -e "${test_dir}/data/events/2026-07-30/manager-turn-4.json" ]]

report_path="$(BALLCLUB_DATA="$test_dir/data" node "$repo_root/scripts/generate-report.mjs" --period daily --date 2026-07-30)"
rg -q '\| 2 \| 2 \| 2 \| 1.000 \| 0 \| 0 \| 1,900 token \| 0 \|' "$report_path"
rg -q '^## 감독 직접 수행$' "$report_path"
rg -Fq '| `manager` | 1 | 1 | 1 |' "$report_path"

printf '%s\n' "scorebook tests passed"
