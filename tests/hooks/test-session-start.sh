#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
hook="${repo_root}/hooks/session-start"
update_hook="${repo_root}/hooks/session-update"
wrapper="${repo_root}/hooks/run-hook.cmd"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
printf '%s\n' '{"version":"0.5.0"}' > "${test_dir}/remote.json"
clean_home="${test_dir}/home"
mkdir -p "$clean_home"

assert_json() {
  local mode="$1"
  local output="$2"
  local setup_expected="${3:-true}"
  node --input-type=module -e '
    const [mode, source, setupExpected] = process.argv.slice(1);
    const parsed = JSON.parse(source);
    const hasOwn = (key) => Object.prototype.hasOwnProperty.call(parsed, key);
    const content = parsed.hookSpecificOutput?.additionalContext;
    if (parsed.hookSpecificOutput?.hookEventName !== "SessionStart") {
      throw new Error(`missing SessionStart event name for ${mode}`);
    }
    if (hasOwn("additionalContext") || hasOwn("additional_context")) {
      throw new Error(`${mode} output included a second context field`);
    }
    if (!content?.includes("ballclub:bootstrap")) throw new Error(`missing marker for ${mode}`);
    if (!content.includes("If there is even a 1% chance another installed skill applies")) {
      throw new Error(`missing 1% skill invocation rule for ${mode}`);
    }
    if (!content.includes("does not automatically activate TDD, design, planning, worktrees, review")) {
      throw new Error(`missing methodology isolation rule for ${mode}`);
    }
    const hasSetup = content.includes("ballclub:setup-required");
    if (hasSetup !== (setupExpected === "true")) {
      throw new Error(`unexpected setup marker for ${mode}: ${hasSetup}`);
    }
  ' "$mode" "$output" "$setup_expected"
}

node --input-type=module -e '
  import fs from "node:fs";
  const parsed = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const entries = parsed.hooks?.SessionStart;
  if (!Array.isArray(entries) || entries.length !== 2) throw new Error("expected two SessionStart jobs");
  const bootstrap = entries.find((entry) => entry.hooks?.[0]?.command?.endsWith("session-start"));
  const update = entries.find((entry) => entry.hooks?.[0]?.command?.endsWith("session-update"));
  if (bootstrap?.matcher !== "startup|clear|compact") throw new Error("bootstrap matcher must skip resume");
  if (update?.matcher !== "startup") throw new Error("update matcher must run only on fresh startup");
  for (const entry of entries) {
    const command = entry.hooks?.[0];
    if (command?.shell !== "bash" || command?.async !== false) {
      throw new Error("SessionStart jobs must use synchronous bash dispatch");
    }
  }
' "${repo_root}/hooks/hooks.json"

generic="$(env -i PATH="${PATH:-}" HOME="$clean_home" PLUGIN_ROOT="$repo_root" CLAUDE_PLUGIN_ROOT="$repo_root" bash "$hook")"
claude="$(env -i PATH="${PATH:-}" HOME="$clean_home" CLAUDE_PLUGIN_ROOT="$repo_root" bash "$hook")"

assert_json generic "$generic"
assert_json claude "$claude"

wrapped_claude="$(env -i PATH="${PATH:-}" HOME="$clean_home" CLAUDE_PLUGIN_ROOT="$repo_root" bash "$wrapper" session-start)"
assert_json claude "$wrapped_claude"

mkdir -p "$clean_home/.codex/agents" "$clean_home/.claude/agents"
for source_file in "$repo_root"/agents/codex/*.toml; do
  cp "$source_file" "$clean_home/.codex/agents/"
done
for source_file in "$repo_root"/rosters/claude/*.md; do
  cp "$source_file" "$clean_home/.claude/agents/"
done

configured_generic="$(env -i PATH="${PATH:-}" HOME="$clean_home" PLUGIN_ROOT="$repo_root" CLAUDE_PLUGIN_ROOT="$repo_root" bash "$hook")"
configured_claude="$(env -i PATH="${PATH:-}" HOME="$clean_home" CLAUDE_PLUGIN_ROOT="$repo_root" bash "$hook")"
assert_json generic "$configured_generic" false
assert_json claude "$configured_claude" false

broken_root="${test_dir}/broken-plugin"
mkdir -p "${broken_root}/hooks"
cp "$hook" "${broken_root}/hooks/session-start"
broken_output="$(env -i PATH="${PATH:-}" HOME="$clean_home" bash "${broken_root}/hooks/session-start")"
node --input-type=module -e '
  const parsed = JSON.parse(process.argv[1]);
  if (!parsed.hookSpecificOutput?.additionalContext?.includes("ballclub:bootstrap-unavailable")) {
    throw new Error("missing graceful bootstrap fallback");
  }
' "$broken_output"

update_output="$(
  env -i PATH="${PATH:-}" HOME="$clean_home" \
  BALLCLUB_FORCE_UPDATE_CHECK=true \
  BALLCLUB_UPDATE_DATA_DIR="${test_dir}/cache-generic" \
  BALLCLUB_REMOTE_PACKAGE_FILE="${test_dir}/remote.json" \
    bash "$update_hook"
)"
node --input-type=module -e '
  const parsed = JSON.parse(process.argv[1]);
  if (parsed.hookSpecificOutput || parsed.additional_context) throw new Error("generic update output mixed context shapes");
  const content = parsed.additionalContext;
  if (!content?.includes("ballclub:update-available")) throw new Error("missing update marker");
  if (!content.includes("current_version=0.4.4") || !content.includes("latest_version=0.5.0")) {
    throw new Error("missing update versions");
  }
  if (!content.includes("natural English") || !content.includes("current conversational context and tone")) {
    throw new Error("missing English contextual wording rule");
  }
  if (!content.includes("do not use a fixed template")) throw new Error("fixed-template wording was not prohibited");
  if (!content.includes("update_command=")) throw new Error("missing runtime update command");
  if (content.includes("updating-ballclub")) throw new Error("update manager leaked into skill routing");
  if (!content.includes("Do not run update_command until the user explicitly approves")) throw new Error("missing approval boundary");
' "$update_output"

claude_update_output="$(
  env -i PATH="${PATH:-}" HOME="$clean_home" CLAUDE_PLUGIN_ROOT="$repo_root" \
  BALLCLUB_FORCE_UPDATE_CHECK=true \
  BALLCLUB_UPDATE_DATA_DIR="${test_dir}/cache-claude" \
  BALLCLUB_REMOTE_PACKAGE_FILE="${test_dir}/remote.json" \
    bash "$update_hook"
)"
node --input-type=module -e '
  const parsed = JSON.parse(process.argv[1]);
  if (parsed.additionalContext || parsed.additional_context) throw new Error("Claude update output mixed context shapes");
  if (parsed.hookSpecificOutput?.hookEventName !== "SessionStart") throw new Error("missing Claude update event name");
  if (!parsed.hookSpecificOutput?.additionalContext?.includes("ballclub:update-available")) {
    throw new Error("missing Claude update marker");
  }
' "$claude_update_output"

disabled_output="$(BALLCLUB_DISABLE_UPDATE_CHECK=true bash "$update_hook")"
[[ -z "$disabled_output" ]]

printf '%s\n' "session-start hook tests passed"
