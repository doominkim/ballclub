#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
checker="${repo_root}/scripts/check-update"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

printf '%s\n' '{"version":"0.2.0"}' > "${test_dir}/newer.json"
printf '%s\n' '{"version":"0.1.0"}' > "${test_dir}/same.json"
printf '%s\n' '{"version":"0.0.9"}' > "${test_dir}/older.json"

run_check() {
  SUPERPOWERS_LITE_FORCE_UPDATE_CHECK=true \
  SUPERPOWERS_LITE_UPDATE_DATA_DIR="${test_dir}/cache-$1" \
  SUPERPOWERS_LITE_REMOTE_PACKAGE_FILE="${test_dir}/$1.json" \
    bash "$checker"
}

[[ "$(run_check newer)" == "update_available|0.1.0|0.2.0" ]]
[[ "$(run_check same)" == "up_to_date|0.1.0|0.1.0" ]]
[[ "$(run_check older)" == "up_to_date|0.1.0|0.0.9" ]]
[[ "$(SUPERPOWERS_LITE_DISABLE_UPDATE_CHECK=true bash "$checker")" == "disabled|0.1.0|0.1.0" ]]

printf '%s\n' "update checker tests passed"
