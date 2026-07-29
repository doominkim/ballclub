#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

node --input-type=module -e '
  import fs from "node:fs";

  const config = JSON.parse(fs.readFileSync(".version-bump.json", "utf8"));
  const readPath = (value, field) => field.split(".").reduce((current, key) => current?.[key], value);
  const versions = config.files.map(({ path, field }) => {
    const value = JSON.parse(fs.readFileSync(path, "utf8"));
    return { path, field, version: readPath(value, field) };
  });
  const unique = new Set(versions.map(({ version }) => version));
  for (const item of versions) console.log(`${item.path} (${item.field}): ${item.version}`);
  if (unique.size !== 1) {
    console.error("Version drift detected");
    process.exit(1);
  }
  console.log(`All versions match: ${versions[0].version}`);
'
