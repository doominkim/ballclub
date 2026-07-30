#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
transcript="${test_dir}/player.jsonl"

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

printf '%s\n' "scorebook tests passed"
