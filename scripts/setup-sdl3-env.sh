#!/usr/bin/env bash
# Source this file when native SDL3 headers are not discovered by the MoonBit
# native build:
#
#   source scripts/setup-sdl3-env.sh
#
# It exports CC_FLAGS, CPATH, and C_INCLUDE_PATH for the current shell.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "This script must be sourced so it can update the current shell:" >&2
  echo "  source scripts/setup-sdl3-env.sh" >&2
  exit 2
fi

_rhodonite_sdl3_add_include() {
  local inc="$1"
  [[ -n "$inc" ]] || return 0

  case " ${CC_FLAGS:-} " in
    *" -I${inc} "*) ;;
    *) export CC_FLAGS="-I${inc}${CC_FLAGS:+ ${CC_FLAGS}}" ;;
  esac

  case ":${CPATH:-}:" in
    *":${inc}:"*) ;;
    *) export CPATH="${inc}${CPATH:+:${CPATH}}" ;;
  esac

  case ":${C_INCLUDE_PATH:-}:" in
    *":${inc}:"*) ;;
    *) export C_INCLUDE_PATH="${inc}${C_INCLUDE_PATH:+:${C_INCLUDE_PATH}}" ;;
  esac
}

_rhodonite_sdl3_found=0
if command -v pkg-config >/dev/null 2>&1 && pkg-config --exists sdl3; then
  for _rhodonite_sdl3_flag in $(pkg-config --cflags-only-I sdl3); do
    _rhodonite_sdl3_add_include "${_rhodonite_sdl3_flag#-I}"
    _rhodonite_sdl3_found=1
  done
else
  for _rhodonite_sdl3_inc in /opt/homebrew/include /usr/local/include; do
    if [[ -d "${_rhodonite_sdl3_inc}/SDL3" ]]; then
      _rhodonite_sdl3_add_include "$_rhodonite_sdl3_inc"
      _rhodonite_sdl3_found=1
      break
    fi
  done
fi

if [[ "$_rhodonite_sdl3_found" -eq 0 ]]; then
  echo "SDL3 headers were not found via pkg-config, /opt/homebrew/include, or /usr/local/include." >&2
  echo "Install SDL3 development headers, then source this script again." >&2
fi

unset -f _rhodonite_sdl3_add_include
unset _rhodonite_sdl3_found
unset _rhodonite_sdl3_flag
unset _rhodonite_sdl3_inc
