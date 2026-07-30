#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

export CLAUDE_CONFIG_DIR="$test_root/claude"
export BALLCLUB_DATA="$test_root/data"

check_json="$(node "$repo_root/scripts/setup-claude-agents.mjs" --check --json)"
node -e '
  const value = JSON.parse(process.argv[1]);
  if (value.counts.missing !== 15 || value.counts.current !== 0) process.exit(1);
' "$check_json"

install_json="$(node "$repo_root/scripts/setup-claude-agents.mjs" --install --json)"
node -e '
  const value = JSON.parse(process.argv[1]);
  if (value.counts.current !== 15 || value.installed.length !== 15) process.exit(1);
' "$install_json"

printf '%s\n' '# user customization' >> "$CLAUDE_CONFIG_DIR/agents/1setter.md"
compatible_json="$(node "$repo_root/scripts/setup-claude-agents.mjs" --check --json)"
node -e '
  const value = JSON.parse(process.argv[1]);
  if (value.counts.compatible !== 1 || value.profiles.find((item) => item.name === "1setter.md")?.status !== "compatible") process.exit(1);
' "$compatible_json"

sed -i.bak 's/model: fable/model: opus/' "$CLAUDE_CONFIG_DIR/agents/1setter.md"
set +e
conflict_json="$(node "$repo_root/scripts/setup-claude-agents.mjs" --install --json 2>/dev/null)"
conflict_status=$?
set -e
[[ "$conflict_status" -eq 2 ]]
node -e '
  const value = JSON.parse(process.argv[1]);
  if (value.counts.conflict !== 1 || value.profiles.find((item) => item.name === "1setter.md")?.status !== "conflict") process.exit(1);
' "$conflict_json"
rg -q '^model: opus$' "$CLAUDE_CONFIG_DIR/agents/1setter.md"

force_json="$(node "$repo_root/scripts/setup-claude-agents.mjs" --install --force --json)"
node -e '
  const value = JSON.parse(process.argv[1]);
  if (value.counts.current !== 15 || !value.backedUp.includes("1setter.md")) process.exit(1);
' "$force_json"
cmp "$repo_root/rosters/claude/1setter.md" "$CLAUDE_CONFIG_DIR/agents/1setter.md"
find "$BALLCLUB_DATA/backups/claude-agents" -name 1setter.md -type f | rg -q .

printf '%s\n' "setup Claude Code agents tests passed"
