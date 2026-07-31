#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
checker="${repo_root}/scripts/check-update"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

printf '%s\n' '{"version":"0.9.1"}' > "${test_dir}/newer.json"
printf '%s\n' '{"version":"0.9.0"}' > "${test_dir}/same.json"
printf '%s\n' '{"version":"0.8.9"}' > "${test_dir}/older.json"

run_check() {
  BALLCLUB_FORCE_UPDATE_CHECK=true \
  BALLCLUB_UPDATE_DATA_DIR="${test_dir}/cache-$1" \
  BALLCLUB_REMOTE_PACKAGE_FILE="${test_dir}/$1.json" \
    bash "$checker"
}

[[ "$(run_check newer)" == "update_available|0.9.0|0.9.1" ]]
[[ "$(run_check same)" == "up_to_date|0.9.0|0.9.0" ]]
[[ "$(run_check older)" == "up_to_date|0.9.0|0.8.9" ]]
[[ "$(BALLCLUB_DISABLE_UPDATE_CHECK=true bash "$checker")" == "disabled|0.9.0|0.9.0" ]]

printf '%s\n' "update checker tests passed"
