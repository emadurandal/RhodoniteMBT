#!/usr/bin/env bash
# Native wgpu + SDL3 triangle demo. Requires SDL3 development headers (e.g. brew install sdl3).
# First argument: sample name (default basic-triangle). Example: scripts/run-wgpu-sdl3.sh triangle-with-buffer
# Like Kaida-Amethyst/sdl3 env.sh: expose pkg-config or Homebrew include paths.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/moon/rhodonite_examples"

# Moon mooncake C stubs (e.g. sdl3 wrap.c) may not read CC_FLAGS; also set CPATH / C_INCLUDE_PATH for headers.
if command -v pkg-config >/dev/null 2>&1 && pkg-config --exists sdl3; then
  export CC_FLAGS="$(pkg-config --cflags sdl3) ${CC_FLAGS:-}"
  for i in $(pkg-config --cflags-only-I sdl3); do
    inc="${i#-I}"
    [ -n "$inc" ] || continue
    export CPATH="${inc}${CPATH:+:$CPATH}"
    export C_INCLUDE_PATH="${inc}${C_INCLUDE_PATH:+:$C_INCLUDE_PATH}"
  done
else
  for inc in /opt/homebrew/include /usr/local/include; do
    if [ -d "$inc/SDL3" ]; then
      export CC_FLAGS="-I$inc ${CC_FLAGS:-}"
      export CPATH="${inc}${CPATH:+:$CPATH}"
      export C_INCLUDE_PATH="${inc}${C_INCLUDE_PATH:+:$C_INCLUDE_PATH}"
      break
    fi
  done
fi

moon build --target native

if [ "$#" -ge 1 ]; then
  SAMPLE="$1"
  shift
else
  SAMPLE="basic-triangle"
fi

# Workspace builds emit native binaries under the repo-root `_build`, not `moon/rhodonite_examples/_build`.
exec "$ROOT/_build/native/debug/build/emadurandal/rhodonite_examples/${SAMPLE}/wgpu/main/main.exe" "$@"
