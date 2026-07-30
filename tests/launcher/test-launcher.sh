#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

fake_bin="${test_dir}/bin"
capture_file="${test_dir}/codex-args"
mkdir -p "$fake_bin"
printf '%s\n' '#!/usr/bin/env bash' 'printf '\''%s\n'\'' "$@" > "$CODEX_CAPTURE"' > "${fake_bin}/codex"
chmod +x "${fake_bin}/codex"

PATH="${fake_bin}:/usr/bin:/bin" CODEX_CAPTURE="$capture_file" \
  bash "${repo_root}/bin/ballclub" -C /tmp/example

node --input-type=module -e '
  import fs from "node:fs";
  const args = fs.readFileSync(process.argv[1], "utf8").trimEnd().split("\n");
  if (args[0] !== "-C" || args[1] !== "/tmp/example") throw new Error("Codex options were not forwarded");
  if (args.length !== 2) throw new Error("launcher injected an unexpected setup prompt");
' "$capture_file"

PATH="${fake_bin}:/usr/bin:/bin" CODEX_CAPTURE="$capture_file" \
  bash "${repo_root}/bin/ballclub" --version
[[ "$(cat "$capture_file")" == "--version" ]]

install_dir="${test_dir}/install-bin"
BALLCLUB_BIN_DIR="$install_dir" bash "${repo_root}/scripts/install-launcher"
cmp -s "${repo_root}/bin/ballclub" "${install_dir}/ballclub"
[[ -x "${install_dir}/ballclub" ]]

printf '%s\n' '# custom command' > "${install_dir}/ballclub"
if BALLCLUB_BIN_DIR="$install_dir" bash "${repo_root}/scripts/install-launcher" 2>/dev/null; then
  echo "installer overwrote an unmanaged command" >&2
  exit 1
fi
[[ "$(cat "${install_dir}/ballclub")" == "# custom command" ]]

printf '%s\n' "launcher tests passed"
