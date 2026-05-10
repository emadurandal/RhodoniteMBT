#!/usr/bin/env bash
# Publish emadurandal/rhodonite_core, rhodonite_webgpu, and rhodonite (facade) to mooncakes.
# Does NOT publish rhodonite_examples (samples remain repo-only).
#
# Prerequisites: run `moon login` once; network access for the registry.
# Run from repository root (directory containing moon.work).
#
# Environment:
#   PUBLISH_MOON_FACADE_ONLY=1  Skip publishing rhodonite_core and rhodonite_webgpu;
#                                only refresh registry, patch facade deps, publish facade.
#                                Use when deps are already on the registry but facade failed (e.g. index lag).
#   MOON_PUBLISH_INDEX_WAIT_SECONDS  Seconds to sleep after moon update so the registry index
#                                    can catch up (default: 8). Set to 0 to disable.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FACADE_MOD="moon/rhodonite/moon.mod.json"
BACKUP=""

restore_facade() {
  if [[ -n "${BACKUP}" && -f "${BACKUP}" ]]; then
    cp "${BACKUP}" "${FACADE_MOD}"
    rm -f "${BACKUP}"
    BACKUP=""
    echo "Restored ${FACADE_MOD} (path deps for local workspace)."
  fi
}

on_exit() {
  local code=$?
  restore_facade
  exit "${code}"
}

trap on_exit EXIT

echo "==> moon fmt"
moon fmt

echo "==> moon info"
moon info

echo "==> moon check --target all"
moon check --target all

if [[ "${PUBLISH_MOON_FACADE_ONLY:-}" == "1" ]]; then
  echo "==> PUBLISH_MOON_FACADE_ONLY=1: skip rhodonite_core / rhodonite_webgpu publish (already on registry)"
else
  echo "==> Publish emadurandal/rhodonite_core"
  moon -C moon/rhodonite_core publish

  echo "==> Publish emadurandal/rhodonite_webgpu"
  moon -C moon/rhodonite_webgpu publish
fi

echo "==> moon update (refresh local registry index for newly published deps)"
moon update

WAIT="${MOON_PUBLISH_INDEX_WAIT_SECONDS:-8}"
if [[ "${WAIT}" != "0" ]]; then
  echo "==> Waiting ${WAIT}s for registry index (override with MOON_PUBLISH_INDEX_WAIT_SECONDS=0)"
  sleep "${WAIT}"
fi

echo "==> Stage facade deps (path -> registry versions from sibling moon.mod.json)"
BACKUP="$(mktemp)"
cp "${FACADE_MOD}" "${BACKUP}"

python3 <<'PY'
import json
import sys
from pathlib import Path

root = Path.cwd()
facade_path = root / "moon" / "rhodonite" / "moon.mod.json"
core_path = root / "moon" / "rhodonite_core" / "moon.mod.json"
webgpu_path = root / "moon" / "rhodonite_webgpu" / "moon.mod.json"

facade = json.loads(facade_path.read_text(encoding="utf-8"))
core_ver = json.loads(core_path.read_text(encoding="utf-8"))["version"]
webgpu_ver = json.loads(webgpu_path.read_text(encoding="utf-8"))["version"]

deps = facade.get("deps") or {}
if "emadurandal/rhodonite_core" not in deps or "emadurandal/rhodonite_webgpu" not in deps:
    print("error: facade moon.mod.json missing expected deps", file=sys.stderr)
    sys.exit(1)

deps["emadurandal/rhodonite_core"] = core_ver
deps["emadurandal/rhodonite_webgpu"] = webgpu_ver
facade["deps"] = deps

facade_path.write_text(json.dumps(facade, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"Patched facade deps to rhodonite_core={core_ver}, rhodonite_webgpu={webgpu_ver}")
PY

echo "==> moon update (resolve facade semver deps before publish)"
moon update

echo "==> Publish emadurandal/rhodonite (facade)"
moon -C moon/rhodonite publish

echo "Done. All three library modules published (examples excluded)."
