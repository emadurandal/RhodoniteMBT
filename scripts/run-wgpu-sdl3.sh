#!/usr/bin/env bash
# Native wgpu + SDL3 三角デモ。SDL3 の開発用ヘッダが必要（例: brew install sdl3）。
# Kaida-Amethyst/sdl3 の env.sh と同様に、pkg-config または Homebrew の include を通す。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/moon"

# Moon の mooncake C スタブ（例: sdl3 の wrap.c）は CC_FLAGS を必ずしも参照しないため、
# ヘッダ探索用に CPATH / C_INCLUDE_PATH も設定する。
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

exec "$ROOT/moon/_build/native/debug/build/cmd/wgpu/main/main.exe" "$@"
