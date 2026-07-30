#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
transcript="${test_dir}/player.jsonl"
manager_transcript="${test_dir}/manager.jsonl"
delegated_transcript="${test_dir}/delegated.jsonl"
routine_transcript="${test_dir}/routine.jsonl"

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
