#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo_root"

required_files=(
  .agents/plugins/marketplace.json
  .claude-plugin/plugin.json
  .codex-plugin/plugin.json
  hooks/hooks.json
  hooks/session-start
  hooks/session-update
  bin/ballclub
  docs/game-model.md
  docs/runtime-flow.md
  scripts/check-update
  scripts/update-ballclub
  scripts/ballclub-lib.mjs
  scripts/collect-appearance.mjs
  scripts/generate-report.mjs
  scripts/score-appearance.mjs
  scripts/setup-codex-agents.mjs
  scripts/setup-claude-agents.mjs
  scripts/setup-agent-files.mjs
  scripts/install-launcher
  skills/using-ballclub/SKILL.md
  skills/using-ballclub/agents/openai.yaml
  skills/brainstorming/SKILL.md
  skills/brainstorming/agents/openai.yaml
  skills/systematic-debugging/SKILL.md
  skills/systematic-debugging/agents/openai.yaml
  skills/verification-before-completion/SKILL.md
  skills/verification-before-completion/agents/openai.yaml
  skills/dispatching-parallel-agents/SKILL.md
  skills/dispatching-parallel-agents/agents/openai.yaml
  skills/capacity-routing/SKILL.md
  skills/capacity-routing/agents/openai.yaml
  skills/subagent-driven-development/SKILL.md
  skills/subagent-driven-development/agents/openai.yaml
  skills/finishing-a-development-branch/SKILL.md
  skills/finishing-a-development-branch/agents/openai.yaml
  skills/writing-skills/SKILL.md
  skills/writing-skills/agents/openai.yaml
  skills/score/SKILL.md
  skills/score/agents/openai.yaml
  skills/setup-ballclub/SKILL.md
  skills/setup-ballclub/agents/openai.yaml
  package.json
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { echo "missing required file: $file" >&2; exit 1; }
done

[[ -x bin/ballclub ]] || { echo "launcher must be executable" >&2; exit 1; }
[[ -x scripts/install-launcher ]] || { echo "launcher installer must be executable" >&2; exit 1; }

if [[ -e skills/updating-ballclub ]]; then
  echo "plugin lifecycle manager must not be exposed as a skill" >&2
  exit 1
fi

unsupported_paths=(
  .cursor-plugin
  .kimi-plugin
  .opencode
  .pi
  GEMINI.md
  gemini-extension.json
  hooks/hooks-cursor.json
  skills/using-ballclub/references/gemini-tools.md
  skills/using-ballclub/references/pi-tools.md
)

for path in "${unsupported_paths[@]}"; do
  [[ ! -e "$path" ]] || { echo "unsupported harness artifact remains: $path" >&2; exit 1; }
done

json_files=(
  .agents/plugins/marketplace.json
  .claude-plugin/plugin.json
  .claude-plugin/marketplace.json
  .codex-plugin/plugin.json
  package.json
  .version-bump.json
  hooks/hooks.json
)

for file in "${json_files[@]}"; do
  node -e 'JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"))' "$file"
done

if rg -n '\[TODO:' skills; then
  echo "placeholder found in skills" >&2
  exit 1
fi

rg -q 'even a 1%' skills/using-ballclub/SKILL.md
rg -q 'returned response is not automatically a hit' skills/using-ballclub/SKILL.md
rg -q 'least-sufficient' skills/using-ballclub/SKILL.md

if rg -n 'writing-plans|test-driven-development|requesting-code-review|receiving-code-review|using-git-worktrees' skills; then
  echo "automatic dependency on an undecided skill found" >&2
  exit 1
fi

rg -q 'Do not create reviewer' skills/subagent-driven-development/SKILL.md
rg -q 'Context isolation' skills/dispatching-parallel-agents/SKILL.md
rg -q 'Isolation can justify one subagent' skills/dispatching-parallel-agents/SKILL.md
rg -q 'conclusions, evidence, risks, and relevant paths' skills/dispatching-parallel-agents/SKILL.md
rg -q 'Keep final synthesis and decisions in the parent agent' skills/dispatching-parallel-agents/SKILL.md
rg -q 'least sufficient' skills/capacity-routing/SKILL.md
rg -q 'Do not implement routing as a global hook' skills/capacity-routing/SKILL.md
rg -q 'plate appearance' skills/capacity-routing/SKILL.md
rg -q 'Score unresolved appearances' skills/score/SKILL.md
rg -q '\$score d' skills/score/SKILL.md
rg -q '\$score w' skills/score/SKILL.md
rg -q '\$score m' skills/score/SKILL.md
rg -q 'setup-codex-agents.mjs' skills/setup-ballclub/SKILL.md
rg -q 'setup-claude-agents.mjs' skills/setup-ballclub/SKILL.md
rg -q 'not forced replacement' skills/setup-ballclub/SKILL.md

agent_profile_count="$(find agents/codex -maxdepth 1 -name '*.toml' -type f | wc -l | tr -d ' ')"
[[ "$agent_profile_count" == "15" ]] || {
  echo "expected 15 bundled Codex agent profiles, found $agent_profile_count" >&2
  exit 1
}

for agent_file in agents/codex/*.toml; do
  rg -q '^name = "' "$agent_file"
  rg -q '^description = "' "$agent_file"
  rg -q '^model = "' "$agent_file"
  rg -q '^model_reasoning_effort = "' "$agent_file"
  rg -q '^developer_instructions = """' "$agent_file"
done

claude_agent_profile_count="$(find rosters/claude -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')"
[[ "$claude_agent_profile_count" == "15" ]] || {
  echo "expected 15 bundled Claude Code agent profiles, found $claude_agent_profile_count" >&2
  exit 1
}

for agent_file in rosters/claude/*.md; do
  rg -q '^name: ' "$agent_file"
  rg -q '^description: ' "$agent_file"
  rg -q '^model: ' "$agent_file"
  rg -q '^effort: ' "$agent_file"
done

rg -q '^model: fable$' rosters/claude/1setter.md
rg -q '^model: opus$' rosters/claude/1batter.md
rg -q '^model: sonnet$' rosters/claude/1bench.md
rg -q 'gpt-5.6-sol' rosters/claude/coach.md

python3 - <<'PY'
from pathlib import Path
import tomllib

for agent_file in Path("agents/codex").glob("*.toml"):
    with agent_file.open("rb") as handle:
        value = tomllib.load(handle)
    required = {"name", "description", "model", "model_reasoning_effort", "developer_instructions"}
    missing = required.difference(value)
    if missing:
        raise SystemExit(f"{agent_file}: missing {sorted(missing)}")
PY

rg -q '^model = "gpt-5.6-sol"' agents/codex/1setter.toml
rg -q '^model = "gpt-5.6-terra"' agents/codex/1batter.toml
rg -q '^model = "gpt-5.6-luna"' agents/codex/1bench.toml
rg -q '^sandbox_mode = "read-only"' agents/codex/coach.toml

node --input-type=module -e '
  import fs from "node:fs";
  const manifest = JSON.parse(fs.readFileSync("hooks/hooks.json", "utf8"));
  const stops = manifest.hooks?.SubagentStop;
  if (!Array.isArray(stops) || stops.length !== 1) throw new Error("missing SubagentStop collector");
  if (!stops[0].matcher.includes("setter") || !stops[0].matcher.includes("coach")) {
    throw new Error("collector matcher does not cover players and coaches");
  }
'

for skill_file in skills/*/SKILL.md; do
  word_count="$(wc -w < "$skill_file")"
  if (( word_count > 500 )); then
    echo "skill exceeds the 500-word lite budget: $skill_file ($word_count words)" >&2
    exit 1
  fi
done

printf '%s\n' "structure tests passed"
