#!/usr/bin/env bash
# Run MoonBit tests only for rhodonite_math packages that contain *_test.mbt.
# Called from repo root so moon.work does not plan unrelated workspace packages (e.g. webgpu).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

packages=()
while IFS= read -r d; do
  [[ -n "$d" ]] || continue
  packages+=("$d")
done < <(find moon/rhodonite_math/src -type f -name '*_test.mbt' -exec dirname {} \; | sort -u)

if ((${#packages[@]} == 0)); then
  echo "test-rhodonite-math-mbt: no *_test.mbt under moon/rhodonite_math/src" >&2
  exit 1
fi

exec moon test --target wasm-gc "${packages[@]}"
