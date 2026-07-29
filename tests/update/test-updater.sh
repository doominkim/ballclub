#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
updater="${repo_root}/scripts/update-superpowers-lite"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
fake_bin="${test_dir}/bin"
command_log="${test_dir}/commands.log"
mkdir -p "$fake_bin"

printf '%s\n' '#!/usr/bin/env bash' 'printf "%s|%s\n" "$(basename "$0")" "$*" >> "$SUPERPOWERS_LITE_COMMAND_LOG"' > "${fake_bin}/fake-command"
chmod +x "${fake_bin}/fake-command"
for command in codex claude; do
  ln -s fake-command "${fake_bin}/${command}"
done

if bash "$updater" --harness codex >/dev/null 2>&1; then
  echo "updater ran without explicit approval" >&2
  exit 1
fi

for harness in codex claude; do
  : > "$command_log"
  output="$(PATH="${fake_bin}:$PATH" SUPERPOWERS_LITE_COMMAND_LOG="$command_log" bash "$updater" --yes --harness "$harness")"
  [[ "$output" == *"Updated superpowers-lite completed. End this session and start a new one."* ]]
  [[ -s "$command_log" ]]
done

if bash "$updater" --yes --harness gemini >"${test_dir}/unsupported.out" 2>&1; then
  echo "unsupported harness unexpectedly reported success" >&2
  exit 1
fi
rg -q 'Unsupported harness: gemini' "${test_dir}/unsupported.out"

printf '%s\n' "updater tests passed"
