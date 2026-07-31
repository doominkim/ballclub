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
  scripts/bootstrap-roster.mjs
  scripts/install-launcher
  skills/clubhouse-rules/SKILL.md
  skills/clubhouse-rules/agents/openai.yaml
  skills/design-scouting/SKILL.md
  skills/design-scouting/agents/openai.yaml
  skills/debugging-replay/SKILL.md
  skills/debugging-replay/agents/openai.yaml
  skills/final-out-verification/SKILL.md
  skills/final-out-verification/agents/openai.yaml
  skills/parallel-lineup/SKILL.md
  skills/parallel-lineup/agents/openai.yaml
  skills/set-lineup/SKILL.md
  skills/set-lineup/agents/openai.yaml
  skills/implementation-at-bat/SKILL.md
  skills/implementation-at-bat/agents/openai.yaml
  skills/branch-closer/SKILL.md
  skills/branch-closer/agents/openai.yaml
  skills/playbook-writing/SKILL.md
  skills/playbook-writing/agents/openai.yaml
  skills/scorebook/SKILL.md
  skills/scorebook/agents/openai.yaml
  skills/manage-roster/SKILL.md
  skills/manage-roster/agents/openai.yaml
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
  skills/clubhouse-rules/references/gemini-tools.md
  skills/clubhouse-rules/references/pi-tools.md
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

node --input-type=module <<'NODE'
  import fs from "node:fs";
  import path from "node:path";

  const expected = [
    "branch-closer",
    "clubhouse-rules",
    "debugging-replay",
    "design-scouting",
    "final-out-verification",
    "implementation-at-bat",
    "manage-roster",
    "parallel-lineup",
    "playbook-writing",
    "scorebook",
    "set-lineup",
  ];
  const oldNames = [
    "using-ballclub",
    "capacity-routing",
    "dispatching-parallel-agents",
    "subagent-driven-development",
    "score",
    "setup-ballclub",
    "brainstorming",
    "systematic-debugging",
    "verification-before-completion",
    "finishing-a-development-branch",
    "writing-skills",
  ];
  const replacementNames = [
    "clubhouse-rules",
    "set-lineup",
    "parallel-lineup",
    "implementation-at-bat",
    "scorebook",
    "manage-roster",
    "design-scouting",
    "debugging-replay",
    "final-out-verification",
    "branch-closer",
    "playbook-writing",
  ];
  const actual = fs.readdirSync("skills", { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`canonical skill catalog mismatch: ${actual.join(", ")}`);
  }
  for (const name of oldNames) {
    if (fs.existsSync(path.join("skills", name))) throw new Error(`legacy skill alias remains: ${name}`);
  }
  for (const name of expected) {
    const skill = fs.readFileSync(path.join("skills", name, "SKILL.md"), "utf8");
    const declared = skill.match(/^name: ([a-z0-9-]+)$/m)?.[1];
    if (declared !== name) throw new Error(`${name}: frontmatter name is ${declared}`);
    const metadata = fs.readFileSync(path.join("skills", name, "agents/openai.yaml"), "utf8");
    if (!metadata.includes(`$ballclub:${name}`)) {
      throw new Error(`${name}: default prompt lacks namespace-qualified invocation`);
    }
    const bare = new RegExp(`(^|[^:])\\$${name}(?:\\s|$)`, "m");
    if (bare.test(metadata)) throw new Error(`${name}: bare invocation remains in metadata`);
  }

  const descriptions = Object.fromEntries(expected.map((name) => {
    const skill = fs.readFileSync(path.join("skills", name, "SKILL.md"), "utf8");
    return [name, skill.match(/^description: (.+)$/m)?.[1] || ""];
  }));
  const triggerContracts = {
    "clubhouse-rules": ["session start", "forming a Ballclub lineup"],
    "set-lineup": ["model or effort selection", "Do not use for short questions"],
    "parallel-lineup": ["explicitly requests parallel agent work", "Do not use for tightly coupled work"],
    "implementation-at-bat": ["implementation phase", "approved or already-clear boundaries"],
    "scorebook": ["verified Ballclub player or manager appearance", "report-specific requests", "even when Ballclub is implicit", "player salary or 선수 연봉", "only with Ballclub, agent, team-report, or period-report context", "Do not use for real-world baseball"],
    "manage-roster": ["SessionStart synchronization reports conflicts", "Do not use for a healthy automatic startup"],
    "design-scouting": ["meaningfully ambiguous", "Do not use when requirements"],
    "debugging-replay": ["test or build failure", "before proposing a fix"],
    "final-out-verification": ["before claiming that work is complete", "before a commit, push"],
    "branch-closer": ["explicitly asks to finish", "development branch"],
    "playbook-writing": ["creating a new skill", "validating skill behavior"],
  };
  for (const [name, fragments] of Object.entries(triggerContracts)) {
    for (const fragment of fragments) {
      if (!descriptions[name].includes(fragment)) {
        throw new Error(`${name}: trigger contract missing ${fragment}`);
      }
    }
  }

  const matchesScorebookTrigger = (prompt) => {
    const realWorldBaseball = /KBO|MLB|프로야구|오타니|LG 트윈스/i.test(prompt);
    const reportSpecific = /scorecard|team report|token salar|token 연봉|구단 성적|일봉|주봉|월봉/i.test(prompt);
    const ballclubContext = /ballclub|agent|에이전트|선수 호출|선수 성적|manager appearance|player performance|team report/i.test(prompt);
    const periodReport = /오늘|이번 주|이번 달|today|this week|this month|일봉|주봉|월봉/i.test(prompt);
    const playerSalary = /player salar|선수 연봉/i.test(prompt);
    const scoreMetric = /검수대기|안타|타율|홈런|실책|안타당 token|hit|batting average|home run|error/i.test(prompt);
    return !realWorldBaseball && (
      reportSpecific ||
      (playerSalary && (ballclubContext || periodReport)) ||
      (ballclubContext && scoreMetric)
    );
  };
  const scorebookCases = [
    ["Show today's scorecard", true],
    ["Show this week's team report", true],
    ["오늘 일봉 보여줘", true],
    ["이번 달 선수 연봉 보여줘", true],
    ["Show today's Ballclub scorecard", true],
    ["이번 주 구단 성적 보여줘", true],
    ["에이전트 타율과 token 연봉 보여줘", true],
    ["Score this verified Ballclub agent appearance as a hit", true],
    ["오늘 KBO 타율 순위 알려줘", false],
    ["오늘 KBO 구단 성적 알려줘", false],
    ["오타니 홈런 몇 개야?", false],
    ["김도영 선수 연봉 알려줘", false],
    ["류현진 선수 연봉 알려줘", false],
    ["Aaron Judge player salary", false],
    ["player salary", false],
    ["야구에서 실책은 어떻게 기록해?", false],
    ["안타 잘 치는 법 알려줘", false],
    ["이번 주 보고서 보여줘", false],
  ];
  for (const [prompt, expectedResult] of scorebookCases) {
    const actualResult = matchesScorebookTrigger(prompt);
    if (actualResult !== expectedResult) {
      throw new Error(`scorebook trigger fixture mismatch: ${prompt}`);
    }
  }
  for (const [readme, advertisedRequests] of Object.entries({
    "README.md": ["Show today's scorecard", "Show this week's team report"],
    "README_KR.md": ["오늘 일봉 보여줘", "이번 달 선수 연봉 보여줘"],
  })) {
    const content = fs.readFileSync(readme, "utf8");
    for (const request of advertisedRequests) {
      if (!content.includes(request)) throw new Error(`${readme}: missing advertised scorebook request ${request}`);
    }
  }

  const manifest = JSON.parse(fs.readFileSync(".codex-plugin/plugin.json", "utf8"));
  const defaultPrompts = manifest.interface?.defaultPrompt;
  if (!Array.isArray(defaultPrompts) || defaultPrompts.length !== 3) {
    throw new Error("Codex defaultPrompt must contain exactly three core prompts");
  }
  for (const coreInvocation of [
    "$ballclub:manage-roster",
    "$ballclub:set-lineup",
    "$ballclub:scorebook d",
  ]) {
    if (!defaultPrompts.some((prompt) => prompt.includes(coreInvocation))) {
      throw new Error(`Codex defaultPrompt lost core invocation ${coreInvocation}`);
    }
  }

  for (const [file, requiredForms] of Object.entries({
    "README.md": ["$ballclub:scorebook d", "/ballclub:scorebook d", "$ballclub:scorebook m", "/ballclub:scorebook m"],
    "README_KR.md": ["$ballclub:scorebook d", "/ballclub:scorebook d", "$ballclub:scorebook m", "/ballclub:scorebook m"],
    "skills/scorebook/SKILL.md": ["$ballclub:scorebook d|w|m", "/ballclub:scorebook d|w|m"],
  })) {
    const content = fs.readFileSync(file, "utf8");
    for (const requiredForm of requiredForms) {
      if (!content.includes(requiredForm)) throw new Error(`${file}: missing ${requiredForm}`);
    }
  }

  const migrationMap = Object.fromEntries(oldNames.map((oldName, index) => [oldName, replacementNames[index]]));
  for (const readme of ["README.md", "README_KR.md"]) {
    const content = fs.readFileSync(readme, "utf8");
    for (const [oldName, newName] of Object.entries(migrationMap)) {
      const row = `| \`${oldName}\` | \`${newName}\` |`;
      if (content.split(row).length !== 2) {
        throw new Error(`${readme}: incomplete 0.9.0 migration for ${oldName}`);
      }
    }
    if (!/alias/i.test(content) || !/update|reinstall/i.test(content) || !/fresh session|새 세션/i.test(content)) {
      throw new Error(`${readme}: incomplete breaking migration guidance`);
    }
  }

  const escapeRegex = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const renamedLegacyPattern = oldNames.filter((name) => name !== "score").map(escapeRegex).join("|");
  const scoreLegacyPattern = [
    escapeRegex("$") + "score(?:\\s|$)",
    escapeRegex("/") + "ballclub:" + "score(?:\\s|$)",
    "skills" + escapeRegex("/") + "score(?:/|$)",
    "^name: " + "score$",
    "`" + "score" + "`",
  ].join("|");
  const legacyPattern = new RegExp(`(?:${renamedLegacyPattern})|(?:${scoreLegacyPattern})`, "m");
  const removeAllowedLegacy = (relativePath, content) => {
    let sanitized = content;
    if (relativePath === "README.md" || relativePath === "README_KR.md") {
      for (const [oldName, newName] of Object.entries(migrationMap)) {
        sanitized = sanitized.replace(`| \`${oldName}\` | \`${newName}\` |`, "");
      }
    }
    if (relativePath === "tests/structure/test-structure.sh") {
      for (const oldName of oldNames) {
        sanitized = sanitized.replace(`    "${oldName}",`, "");
      }
    }
    return sanitized;
  };
  const sampleMigrationRow = `| \`${oldNames[0]}\` | \`${replacementNames[0]}\` |`;
  if (legacyPattern.test(removeAllowedLegacy("README.md", sampleMigrationRow))) {
    throw new Error("exact migration row was not allowed");
  }
  const staleReadmeFixture = sampleMigrationRow + "\nUse " + oldNames[0] + " here";
  if (!legacyPattern.test(removeAllowedLegacy("README.md", staleReadmeFixture))) {
    throw new Error("stale README legacy ID escaped the migration-row guard");
  }
  const staleScoreFixture = sampleMigrationRow + "\n" + "$" + "score d";
  if (!legacyPattern.test(removeAllowedLegacy("README.md", staleScoreFixture))) {
    throw new Error("stale README score invocation escaped the migration-row guard");
  }
  const visit = (directory) => {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      if (entry.name === ".git" || entry.name === "node_modules") continue;
      const fullPath = path.join(directory, entry.name);
      if (entry.isDirectory()) {
        visit(fullPath);
      } else if (entry.isFile()) {
        const relativePath = path.relative(".", fullPath);
        const content = removeAllowedLegacy(relativePath, fs.readFileSync(fullPath, "utf8"));
        if (legacyPattern.test(content)) {
          throw new Error(`legacy skill ID outside migration rows or oldNames fixture: ${relativePath}`);
        }
      }
    }
  };
  visit(".");
NODE

! rg -n '(^|[^:])[$/](scorebook|manage-roster|set-lineup|clubhouse-rules|parallel-lineup|implementation-at-bat|design-scouting|debugging-replay|final-out-verification|branch-closer|playbook-writing)([[:space:]]|$)' \
  README.md README_KR.md .codex-plugin/plugin.json skills/*/agents/openai.yaml skills/scorebook/SKILL.md

rg -q 'every installed Ballclub skill with even a 1% chance' skills/clubhouse-rules/SKILL.md
rg -q "For unrelated work, use the host's normal skill discovery" skills/clubhouse-rules/SKILL.md
rg -q 'response or transcript alone is not a hit' skills/clubhouse-rules/SKILL.md
rg -q 'least-sufficient' skills/clubhouse-rules/SKILL.md
rg -q 'actually enters one, send an eligible player regardless of phase size' skills/clubhouse-rules/SKILL.md
rg -q 'does not replace a required player' skills/clubhouse-rules/SKILL.md
rg -q 'Do not manufacture a design, implementation, or review phase' skills/clubhouse-rules/SKILL.md
rg -q 'Manager verification is limited to rerunning or confirming predeclared' skills/clubhouse-rules/SKILL.md
rg -q 'Correctness, regression, security, design tradeoff, code' skills/clubhouse-rules/SKILL.md
rg -q 'player assigned the review and Coach in parallel' skills/clubhouse-rules/SKILL.md
rg -q 'Omit Coach only when it is' skills/clubhouse-rules/SKILL.md
rg -q 'Only when the called player/profile composition actually' skills/clubhouse-rules/SKILL.md
rg -q '선수교체: <profile or lineup>' skills/clubhouse-rules/SKILL.md
rg -q 'announce `라우팅: MAIN`, `LINEUP: MANAGER`' skills/clubhouse-rules/SKILL.md

if rg -n 'writing-plans|test-driven-development|requesting-code-review|receiving-code-review|using-git-worktrees' skills; then
  echo "automatic dependency on an undecided skill found" >&2
  exit 1
fi

rg -q 'worktrees are phases or' skills/clubhouse-rules/SKILL.md
! rg -q 'reviewer agent|reviewer role|worktree role' skills/{set-lineup,implementation-at-bat,parallel-lineup}/SKILL.md
rg -q 'Context isolation' skills/parallel-lineup/SKILL.md
rg -q 'Isolation can justify one subagent' skills/parallel-lineup/SKILL.md
rg -q 'conclusions, evidence, risks, and relevant paths' skills/parallel-lineup/SKILL.md
rg -q 'Keep final synthesis and decisions in the parent agent' skills/parallel-lineup/SKILL.md
rg -q 'least sufficient' skills/set-lineup/SKILL.md
rg -q 'Do not implement routing as a global hook' skills/set-lineup/SKILL.md
rg -q 'Define one appearance' skills/set-lineup/SKILL.md
rg -q 'comparable verified scorebook history' skills/set-lineup/SKILL.md
rg -q 'Use Setter when unresolved design' skills/set-lineup/SKILL.md
rg -q 'Every design, implementation,' skills/set-lineup/SKILL.md
rg -q 'or review phase requires a player appearance regardless of size' skills/set-lineup/SKILL.md
rg -q 'Phase-call requirements do not make parallel execution mandatory' skills/set-lineup/SKILL.md
rg -q 'Track lineup decisions internally' skills/set-lineup/SKILL.md
rg -q 'Manager-owned integration, verification, scoring, commit, or push is' skills/set-lineup/SKILL.md
rg -q 'single bounded' skills/implementation-at-bat/SKILL.md
rg -q 'implementation task still requires one player appearance' skills/implementation-at-bat/SKILL.md
rg -q 'Do not create a' skills/implementation-at-bat/SKILL.md
rg -q 'review phase automatically' skills/implementation-at-bat/SKILL.md
rg -q 'requested or separately determined' skills/implementation-at-bat/SKILL.md
rg -q 'Omit Coach only when unavailable' skills/parallel-lineup/SKILL.md
rg -q 'does not replace the' skills/parallel-lineup/SKILL.md
rg -q 'Size or coupling never waives a required design' skills/parallel-lineup/SKILL.md
rg -q 'dispatch the required player sequentially' skills/parallel-lineup/SKILL.md
rg -Fq '선수교체: 1bench + coach' skills/parallel-lineup/SKILL.md
rg -q 'Score verified work promptly' skills/scorebook/SKILL.md
rg -Fq '$ballclub:scorebook d|w|m' skills/scorebook/SKILL.md
rg -Fq '/ballclub:scorebook d|w|m' skills/scorebook/SKILL.md
rg -q 'setup-codex-agents.mjs' skills/manage-roster/SKILL.md
rg -q 'setup-claude-agents.mjs' skills/manage-roster/SKILL.md
rg -q 'SessionStart' skills/manage-roster/SKILL.md
rg -q 'not forced replacement' skills/manage-roster/SKILL.md
! rg -q 'Run the roster interview|begin this interview|ask whether to install' skills/manage-roster/SKILL.md

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
rg -q 'Sonnet read-only wrapper invoking external GPT-5.6 Sol' rosters/claude/coach.md
! rg -q '^permissionMode:' rosters/claude
rg -q '^disallowedTools: Write, Edit, NotebookEdit$' rosters/claude/1bench.md

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
  const managerStops = manifest.hooks?.Stop;
  if (!Array.isArray(stops) || stops.length !== 1) throw new Error("missing SubagentStop collector");
  if (!Array.isArray(managerStops) || managerStops.length !== 1) throw new Error("missing manager Stop collector");
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
