#!/usr/bin/env bash
# Publish emadurandal/rhodonite_core, rhodonite_webgpu, rhodonite (facade),
# and rhodonite_app_sdl3 to mooncakes.
# Does NOT publish rhodonite_examples (samples remain repo-only).
#
# Prerequisites: run `moon login` once; network access for the registry.
# Run from repository root (directory containing moon.work).
#
# Environment:
#   PUBLISH_MOON_DOWNSTREAM_ONLY=1  Skip publishing rhodonite_core and rhodonite_webgpu;
#                                    publish rhodonite and rhodonite_app_sdl3.
#                                    Use when deps are already on the registry.
#   PUBLISH_MOON_APP_SDL3_ONLY=1    Skip core/webgpu/facade; publish only
#                                    rhodonite_app_sdl3. Use for app module retry.
#   MOON_PUBLISH_INDEX_WAIT_SECONDS  Seconds to sleep after moon update so the registry index
#                                    can catch up (default: 8). Set to 0 to disable.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FACADE_MOD="moon/rhodonite/moon.mod.json"
WEBGPU_MOD="moon/rhodonite_webgpu/moon.mod.json"
APP_SDL3_MOD="moon/rhodonite_app_sdl3/moon.mod.json"
FACADE_BACKUP=""
WEBGPU_BACKUP=""
APP_SDL3_BACKUP=""

restore_mods() {
  if [[ -n "${APP_SDL3_BACKUP}" && -f "${APP_SDL3_BACKUP}" ]]; then
    cp "${APP_SDL3_BACKUP}" "${APP_SDL3_MOD}"
    rm -f "${APP_SDL3_BACKUP}"
    APP_SDL3_BACKUP=""
    echo "Restored ${APP_SDL3_MOD} (path deps for local workspace)."
  fi
  if [[ -n "${WEBGPU_BACKUP}" && -f "${WEBGPU_BACKUP}" ]]; then
    cp "${WEBGPU_BACKUP}" "${WEBGPU_MOD}"
    rm -f "${WEBGPU_BACKUP}"
    WEBGPU_BACKUP=""
    echo "Restored ${WEBGPU_MOD} (path deps for local workspace)."
  fi
  if [[ -n "${FACADE_BACKUP}" && -f "${FACADE_BACKUP}" ]]; then
    cp "${FACADE_BACKUP}" "${FACADE_MOD}"
    rm -f "${FACADE_BACKUP}"
    FACADE_BACKUP=""
    echo "Restored ${FACADE_MOD} (path deps for local workspace)."
  fi
}

on_exit() {
  local code=$?
  restore_mods
  exit "${code}"
}

trap on_exit EXIT

echo "==> moon fmt"
moon fmt

echo "==> moon info"
moon info

echo "==> moon check --target all"
moon check --target all

if [[ "${PUBLISH_MOON_APP_SDL3_ONLY:-}" == "1" ]]; then
  echo "==> PUBLISH_MOON_APP_SDL3_ONLY=1: skip rhodonite_core / rhodonite_webgpu / rhodonite publish"
elif [[ "${PUBLISH_MOON_DOWNSTREAM_ONLY:-}" == "1" ]]; then
  echo "==> PUBLISH_MOON_DOWNSTREAM_ONLY=1: skip rhodonite_core / rhodonite_webgpu publish (already on registry)"
else
  echo "==> Publish emadurandal/rhodonite_core"
  moon -C moon/rhodonite_core publish

  echo "==> moon update (refresh local registry index for freshly published core)"
  moon update

  WAIT="${MOON_PUBLISH_INDEX_WAIT_SECONDS:-8}"
  if [[ "${WAIT}" != "0" ]]; then
    echo "==> Waiting ${WAIT}s for registry index (override with MOON_PUBLISH_INDEX_WAIT_SECONDS=0)"
    sleep "${WAIT}"
  fi

  echo "==> Stage webgpu deps (path -> registry versions from sibling moon.mod.json)"
  WEBGPU_BACKUP="$(mktemp)"
  cp "${WEBGPU_MOD}" "${WEBGPU_BACKUP}"

  python3 <<'PY'
import json
import sys
from pathlib import Path

root = Path.cwd()
webgpu_path = root / "moon" / "rhodonite_webgpu" / "moon.mod.json"
core_path = root / "moon" / "rhodonite_core" / "moon.mod.json"

webgpu = json.loads(webgpu_path.read_text(encoding="utf-8"))
core_ver = json.loads(core_path.read_text(encoding="utf-8"))["version"]

deps = webgpu.get("deps") or {}
if "emadurandal/rhodonite_core" not in deps:
    print("error: webgpu moon.mod.json missing rhodonite_core dep", file=sys.stderr)
    sys.exit(1)

deps["emadurandal/rhodonite_core"] = core_ver
webgpu["deps"] = deps

webgpu_path.write_text(json.dumps(webgpu, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"Patched webgpu dep to rhodonite_core={core_ver}")
PY

  echo "==> moon update (resolve webgpu semver deps before publish)"
  moon update

  echo "==> Publish emadurandal/rhodonite_webgpu"
  moon -C moon/rhodonite_webgpu publish
fi

if [[ "${PUBLISH_MOON_APP_SDL3_ONLY:-}" != "1" ]]; then
  echo "==> moon update (refresh local registry index for newly published deps)"
  moon update

  WAIT="${MOON_PUBLISH_INDEX_WAIT_SECONDS:-8}"
  if [[ "${WAIT}" != "0" ]]; then
    echo "==> Waiting ${WAIT}s for registry index (override with MOON_PUBLISH_INDEX_WAIT_SECONDS=0)"
    sleep "${WAIT}"
  fi

  echo "==> Stage facade deps (path -> registry versions from sibling moon.mod.json)"
  FACADE_BACKUP="$(mktemp)"
  cp "${FACADE_MOD}" "${FACADE_BACKUP}"

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
fi

echo "==> moon update (refresh local registry index for rhodonite_app_sdl3 deps)"
moon update

WAIT="${MOON_PUBLISH_INDEX_WAIT_SECONDS:-8}"
if [[ "${WAIT}" != "0" ]]; then
  echo "==> Waiting ${WAIT}s for registry index (override with MOON_PUBLISH_INDEX_WAIT_SECONDS=0)"
  sleep "${WAIT}"
fi

echo "==> Stage rhodonite_app_sdl3 deps (path -> registry versions from sibling moon.mod.json)"
APP_SDL3_BACKUP="$(mktemp)"
cp "${APP_SDL3_MOD}" "${APP_SDL3_BACKUP}"

python3 <<'PY'
import json
import sys
from pathlib import Path

root = Path.cwd()
app_path = root / "moon" / "rhodonite_app_sdl3" / "moon.mod.json"
facade_path = root / "moon" / "rhodonite" / "moon.mod.json"
core_path = root / "moon" / "rhodonite_core" / "moon.mod.json"
webgpu_path = root / "moon" / "rhodonite_webgpu" / "moon.mod.json"

app = json.loads(app_path.read_text(encoding="utf-8"))
facade_ver = json.loads(facade_path.read_text(encoding="utf-8"))["version"]
core_ver = json.loads(core_path.read_text(encoding="utf-8"))["version"]
webgpu_ver = json.loads(webgpu_path.read_text(encoding="utf-8"))["version"]

deps = app.get("deps") or {}
required = [
    "emadurandal/rhodonite",
    "emadurandal/rhodonite_core",
    "emadurandal/rhodonite_webgpu",
]
missing = [name for name in required if name not in deps]
if missing:
    print(
        "error: rhodonite_app_sdl3 moon.mod.json missing expected deps: "
        + ", ".join(missing),
        file=sys.stderr,
    )
    sys.exit(1)

deps["emadurandal/rhodonite"] = facade_ver
deps["emadurandal/rhodonite_core"] = core_ver
deps["emadurandal/rhodonite_webgpu"] = webgpu_ver
app["deps"] = deps

app_path.write_text(json.dumps(app, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(
    "Patched rhodonite_app_sdl3 deps to "
    f"rhodonite={facade_ver}, rhodonite_core={core_ver}, rhodonite_webgpu={webgpu_ver}"
)
PY

echo "==> moon update (resolve rhodonite_app_sdl3 semver deps before publish)"
moon update

echo "==> Publish emadurandal/rhodonite_app_sdl3"
moon -C moon/rhodonite_app_sdl3 publish

echo "Done. All four library modules published (examples excluded)."
