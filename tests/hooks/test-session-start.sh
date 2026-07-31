#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
hook="${repo_root}/hooks/session-start"
update_hook="${repo_root}/hooks/session-update"
wrapper="${repo_root}/hooks/run-hook.cmd"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
printf '%s\n' '{"version":"0.8.2"}' > "${test_dir}/remote.json"
clean_home="${test_dir}/home"
mkdir -p "$clean_home"

assert_json() {
  local mode="$1"
  local output="$2"
  local sync_expected="${3:-synced}"
  node --input-type=module -e '
    const [mode, source, syncExpected] = process.argv.slice(1);
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
    if (!content.includes("For Ballclub routing, delegation, scoring, or appearance interpretation") ||
        !content.includes("installed Ballclub skill with even a 1% chance of applying")) {
      throw new Error(`missing scoped 1% skill invocation rule for ${mode}`);
    }
    if (!content.includes("does not automatically activate TDD, design, planning, worktrees, review")) {
      throw new Error(`missing methodology isolation rule for ${mode}`);
    }
    if (!content.includes("actually enters one, send an eligible player regardless of phase size")) {
      throw new Error(`missing mandatory existing-phase player call for ${mode}`);
    }
    if (!content.includes("Manager verification is limited to rerunning or confirming predeclared") ||
        !content.includes("diff judgment are review work and require an eligible player")) {
      throw new Error(`missing manager verification boundary for ${mode}`);
    }
    if (!content.includes("player assigned the review and Coach in parallel") ||
        !content.includes("Omit Coach only when it is")) {
      throw new Error(`missing default parallel Coach review for ${mode}`);
    }
    if (!content.includes("Only when the called player/profile composition actually") ||
        !content.includes("선수교체: <profile or lineup>") ||
        !content.includes("announce `라우팅: MAIN`, `LINEUP: MANAGER`")) {
      throw new Error(`missing player-change-only announcement policy for ${mode}`);
    }
    if (content.includes("ballclub:setup-required") || content.includes("roster interview")) {
      throw new Error(`legacy setup interview leaked for ${mode}`);
    }
    const marker = syncExpected === "none" ? null : `ballclub:roster-${syncExpected}`;
    if (marker && !content.includes(marker)) {
      throw new Error(`missing ${marker} for ${mode}`);
    }
    if (!marker && /ballclub:roster-(?:synced|conflicts|sync-degraded)/.test(content)) {
      throw new Error(`unexpected roster sync notice for ${mode}`);
    }
  ' "$mode" "$output" "$sync_expected"
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

generic="$(env -i PATH="${PATH:-}" HOME="$clean_home" PLUGIN_ROOT="$repo_root" bash "$hook")"
claude="$(env -i PATH="${PATH:-}" HOME="$clean_home" CLAUDE_PLUGIN_ROOT="$repo_root" bash "$hook")"
claude_with_plugin_root="$(env -i PATH="${PATH:-}" HOME="$clean_home" PLUGIN_ROOT="$repo_root" CLAUDE_PLUGIN_ROOT="$repo_root" bash "$hook")"

assert_json generic "$generic"
assert_json claude "$claude"
assert_json claude "$claude_with_plugin_root" none
[[ -f "$clean_home/.codex/ballclub/config/codex-agent-state.json" ]]
[[ -f "$clean_home/.claude/ballclub/config/claude-agent-state.json" ]]

wrapped_claude="$(env -i PATH="${PATH:-}" HOME="$clean_home" CLAUDE_PLUGIN_ROOT="$repo_root" bash "$wrapper" session-start)"
assert_json claude "$wrapped_claude" none

assert_degraded_policy() {
  local mode="$1"
  local output="$2"
  local expected_reason="$3"
  node --input-type=module -e '
    const [mode, source, expectedReason] = process.argv.slice(1);
    const parsed = JSON.parse(source);
    const content = parsed.hookSpecificOutput?.additionalContext || "";
    if (!content.includes("ballclub:roster-sync-degraded")) throw new Error(`missing degraded marker for ${mode}`);
    if (!content.includes(expectedReason)) throw new Error(`missing degraded reason for ${mode}`);
    if (!content.includes("Continue with any eligible roster profiles currently exposed by the harness")) {
      throw new Error(`degraded fallback discarded exposed roster for ${mode}`);
    }
    if (!content.includes("report the limitation instead of substituting manager execution")) {
      throw new Error(`degraded fallback permits manager phase substitution for ${mode}`);
    }
    if (content.includes("Continue with the manager only")) {
      throw new Error(`legacy manager-only fallback leaked for ${mode}`);
    }
  ' "$mode" "$output" "$expected_reason"
}

degraded_root="${test_dir}/degraded-plugin"
mkdir -p "$degraded_root/hooks" "$degraded_root/scripts" "$degraded_root/skills/using-ballclub"
cp "$hook" "$degraded_root/hooks/session-start"
cp "$repo_root/skills/using-ballclub/SKILL.md" "$degraded_root/skills/using-ballclub/SKILL.md"
printf '%s\n' 'process.exit(1);' > "$degraded_root/scripts/bootstrap-roster.mjs"
sync_failure_output="$(env -i PATH="${PATH:-}" HOME="$clean_home" PLUGIN_ROOT="$degraded_root" bash "$degraded_root/hooks/session-start")"
assert_degraded_policy sync-failure "$sync_failure_output" "could not run its managed roster bootstrap"

printf '%s\n' 'process.stdout.write(JSON.stringify({status:"degraded"}));' > "$degraded_root/scripts/bootstrap-roster.mjs"
degraded_status_output="$(env -i PATH="${PATH:-}" HOME="$clean_home" PLUGIN_ROOT="$degraded_root" bash "$degraded_root/hooks/session-start")"
assert_degraded_policy degraded-status "$degraded_status_output" "could not complete its managed roster bootstrap"

mkdir -p "$clean_home/.codex/agents" "$clean_home/.claude/agents"
for source_file in "$repo_root"/agents/codex/*.toml; do
  cp "$source_file" "$clean_home/.codex/agents/"
done
for source_file in "$repo_root"/rosters/claude/*.md; do
  cp "$source_file" "$clean_home/.claude/agents/"
done

configured_generic="$(env -i PATH="${PATH:-}" HOME="$clean_home" PLUGIN_ROOT="$repo_root" bash "$hook")"
configured_claude="$(env -i PATH="${PATH:-}" HOME="$clean_home" CLAUDE_PLUGIN_ROOT="$repo_root" bash "$hook")"
assert_json generic "$configured_generic" none
assert_json claude "$configured_claude" none

sed -i.bak '/^effort: max$/a\
disallowedTools: Bash' "$clean_home/.claude/agents/1setter.md"
security_drift_claude="$(env -i PATH="${PATH:-}" HOME="$clean_home" CLAUDE_PLUGIN_ROOT="$repo_root" bash "$hook")"
assert_json claude "$security_drift_claude" none
node --input-type=module -e '
  const parsed = JSON.parse(process.argv[1]);
  const content = parsed.hookSpecificOutput?.additionalContext || "";
  if (!content.includes("ballclub:roster-security-drift")) throw new Error("missing security drift marker");
  if (!content.includes("1setter.md (disallowedTools)")) throw new Error("missing security drift profile and fields");
  if (!content.includes("Do not overwrite automatically")) throw new Error("missing security drift preservation rule");
' "$security_drift_claude"
cp "$repo_root/rosters/claude/1setter.md" "$clean_home/.claude/agents/1setter.md"

sed -i.bak 's/model = "gpt-5.6-sol"/model = "gpt-5.6-terra"/' "$clean_home/.codex/agents/1setter.toml"
conflict_generic="$(env -i PATH="${PATH:-}" HOME="$clean_home" PLUGIN_ROOT="$repo_root" bash "$hook")"
assert_json generic "$conflict_generic" conflicts
[[ "$conflict_generic" == *"1setter.toml"* ]]
rg -q 'model = "gpt-5.6-terra"' "$clean_home/.codex/agents/1setter.toml"

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
  if (!content.includes("current_version=0.8.1") || !content.includes("latest_version=0.8.2")) {
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
