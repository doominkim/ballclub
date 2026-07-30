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
  docs/concept-review.html
  docs/runtime-flow.html
  scripts/check-update
  scripts/update-superpowers-lite
  skills/using-superpowers-lite/SKILL.md
  skills/using-superpowers-lite/agents/openai.yaml
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
  package.json
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { echo "missing required file: $file" >&2; exit 1; }
done

if [[ -e skills/updating-superpowers-lite ]]; then
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
  skills/using-superpowers-lite/references/gemini-tools.md
  skills/using-superpowers-lite/references/pi-tools.md
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

rg -q '1% chance a skill applies' skills/using-superpowers-lite/SKILL.md
rg -q 'not enabling a methodology bundle' skills/using-superpowers-lite/SKILL.md

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

for skill_file in skills/*/SKILL.md; do
  word_count="$(wc -w < "$skill_file")"
  if (( word_count > 500 )); then
    echo "skill exceeds the 500-word lite budget: $skill_file ($word_count words)" >&2
    exit 1
  fi
done

printf '%s\n' "structure tests passed"
