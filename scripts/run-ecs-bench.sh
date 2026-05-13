#!/usr/bin/env bash
# Run the ECS microbench package (moon/rhodonite_core/src/ecs_bench) for a MoonBit target.
# Usage (from repo root):
#   bash scripts/run-ecs-bench.sh           # default: js
#   bash scripts/run-ecs-bench.sh native
#   bash scripts/run-ecs-bench.sh wasm-gc # builds only (no run)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TARGET="${1:-js}"
BENCH_PKG="moon/rhodonite_core/src/ecs_bench"

case "${TARGET}" in
  js | native)
    exec moon run --target "${TARGET}" "${BENCH_PKG}"
    ;;
  wasm-gc)
    exec moon build --target wasm-gc "${BENCH_PKG}"
    ;;
  *)
    echo "run-ecs-bench: unknown target '${TARGET}'" >&2
    echo "usage: bash scripts/run-ecs-bench.sh [js|native|wasm-gc]" >&2
    exit 1
    ;;
esac
