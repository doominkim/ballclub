#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

export CODEX_HOME="$test_root/codex"
export BALLCLUB_DATA="$test_root/data"

check_json="$(node "$repo_root/scripts/setup-codex-agents.mjs" --check --json)"
node -e '
  const value = JSON.parse(process.argv[1]);
  if (value.counts.missing !== 15 || value.counts.current !== 0) process.exit(1);
' "$check_json"

install_json="$(node "$repo_root/scripts/setup-codex-agents.mjs" --install --json)"
node -e '
  const value = JSON.parse(process.argv[1]);
  if (value.counts.current !== 15 || value.installed.length !== 15) process.exit(1);
' "$install_json"

printf '%s\n' '# user customization' >> "$CODEX_HOME/agents/1setter.toml"
compatible_json="$(node "$repo_root/scripts/setup-codex-agents.mjs" --check --json)"
node -e '
  const value = JSON.parse(process.argv[1]);
  if (value.counts.compatible !== 1 || value.profiles.find((item) => item.name === "1setter.toml")?.status !== "compatible") process.exit(1);
' "$compatible_json"

sed -i.bak 's/model = "gpt-5.6-sol"/model = "gpt-5.6-terra"/' "$CODEX_HOME/agents/1setter.toml"
set +e
conflict_json="$(node "$repo_root/scripts/setup-codex-agents.mjs" --install --json 2>/dev/null)"
conflict_status=$?
set -e
[[ "$conflict_status" -eq 2 ]]
node -e '
  const value = JSON.parse(process.argv[1]);
  if (value.counts.conflict !== 1 || value.profiles.find((item) => item.name === "1setter.toml")?.status !== "conflict") process.exit(1);
' "$conflict_json"
rg -q 'model = "gpt-5.6-terra"' "$CODEX_HOME/agents/1setter.toml"

force_json="$(node "$repo_root/scripts/setup-codex-agents.mjs" --install --force --json)"
node -e '
  const value = JSON.parse(process.argv[1]);
  if (value.counts.current !== 15 || !value.backedUp.includes("1setter.toml")) process.exit(1);
' "$force_json"
cmp "$repo_root/agents/codex/1setter.toml" "$CODEX_HOME/agents/1setter.toml"
find "$BALLCLUB_DATA/backups/codex-agents" -name 1setter.toml -type f | rg -q .

default_home="$test_root/default-home"
env -u BALLCLUB_DATA HOME="$default_home" CODEX_HOME="$default_home/.codex" \
  node "$repo_root/scripts/setup-codex-agents.mjs" --install --json >/dev/null
[[ -f "$default_home/.codex/ballclub/config/codex-agent-state.json" ]]
[[ ! -e "$default_home/.claude/ballclub/config/codex-agent-state.json" ]]

printf '%s\n' "setup Codex agents tests passed"
