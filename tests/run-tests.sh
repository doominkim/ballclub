#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

bash tests/structure/test-structure.sh
bash tests/hooks/test-session-start.sh
bash tests/update/test-check-update.sh
bash tests/update/test-updater.sh
bash tests/scorebook/test-scorebook.sh
bash tests/setup/test-setup-codex-agents.sh
bash tests/setup/test-setup-claude-agents.sh
bash scripts/check-versions.sh

printf '%s\n' "all tests passed"
