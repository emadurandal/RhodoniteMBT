#!/usr/bin/env bash
# Run the ECS microbench package (moon/rhodonite_core/src/ecs_bench) for a MoonBit target in release mode.
# Usage (from repo root):
#   bash scripts/run-ecs-bench.sh           # default: js
#   bash scripts/run-ecs-bench.sh all --json-out /tmp/ecs-bench.jsonl
#   bash scripts/run-ecs-bench.sh js --compare-baseline benchmarks/ecs/baseline.jsonl
#   bash scripts/run-ecs-bench.sh native
#   bash scripts/run-ecs-bench.sh wasm-gc # builds only (no run)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TARGET="${1:-js}"
if [[ $# -gt 0 ]]; then
  shift
fi
BENCH_PKG="moon/rhodonite_core/src/ecs_bench"
JSON_OUT=""
COMPARE_BASELINE=""
FAIL_ON_REGRESSION=0
TMP_JSON_OUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --)
      shift
      ;;
    --json-out)
      if [[ $# -lt 2 ]]; then
        echo "run-ecs-bench: --json-out requires a path" >&2
        exit 1
      fi
      JSON_OUT="$2"
      shift 2
      ;;
    --compare-baseline)
      if [[ $# -lt 2 ]]; then
        echo "run-ecs-bench: --compare-baseline requires a path" >&2
        exit 1
      fi
      COMPARE_BASELINE="$2"
      shift 2
      ;;
    --fail-on-regression)
      FAIL_ON_REGRESSION=1
      shift
      ;;
    *)
      echo "run-ecs-bench: unknown option '$1'" >&2
      echo "usage: bash scripts/run-ecs-bench.sh [js|native|all|wasm-gc] [--json-out path] [--compare-baseline path] [--fail-on-regression]" >&2
      exit 1
      ;;
  esac
done

if [[ -n "$COMPARE_BASELINE" && -z "$JSON_OUT" ]]; then
  TMP_JSON_OUT="$(mktemp)"
  JSON_OUT="$TMP_JSON_OUT"
fi

cleanup() {
  if [[ -n "$TMP_JSON_OUT" ]]; then
    rm -f "$TMP_JSON_OUT"
  fi
}
trap cleanup EXIT

run_target() {
  local target="$1"
  moon run --release --target "${target}" "${BENCH_PKG}"
}

write_json_results() {
  local target="$1"
  local input="$2"
  local output="$3"
  node - "$target" "$input" "$output" <<'NODE'
const [target, input, output] = process.argv.slice(2);
const fs = require("node:fs");
const lines = fs.readFileSync(input, "utf8").split(/\r?\n/);
const out = [];
for (const line of lines) {
  if (!line.startsWith("ecs_bench_result ")) continue;
  const result = JSON.parse(line.slice("ecs_bench_result ".length));
  out.push(JSON.stringify({ target, build_mode: "release", ...result }));
}
fs.appendFileSync(output, out.length > 0 ? out.join("\n") + "\n" : "");
NODE
}

run_and_capture() {
  local target="$1"
  if [[ -z "$JSON_OUT" ]]; then
    run_target "$target"
    return
  fi
  local tmp
  tmp="$(mktemp)"
  run_target "$target" | tee "$tmp"
  write_json_results "$target" "$tmp" "$JSON_OUT"
  rm -f "$tmp"
}

case "${TARGET}" in
  js | native)
    run_and_capture "${TARGET}"
    ;;
  all)
    if [[ -n "$JSON_OUT" ]]; then
      : > "$JSON_OUT"
    fi
    run_and_capture native
    run_and_capture js
    ;;
  wasm-gc)
    if [[ -n "$JSON_OUT" ]]; then
      echo "run-ecs-bench: --json-out/--compare-baseline is only supported for runnable targets" >&2
      exit 1
    fi
    exec moon build --release --target wasm-gc "${BENCH_PKG}"
    ;;
  *)
    echo "run-ecs-bench: unknown target '${TARGET}'" >&2
    echo "usage: bash scripts/run-ecs-bench.sh [js|native|all|wasm-gc] [--json-out path] [--compare-baseline path] [--fail-on-regression]" >&2
    exit 1
    ;;
esac

if [[ -n "$COMPARE_BASELINE" ]]; then
  compare_args=(scripts/compare-ecs-bench.mjs --baseline "$COMPARE_BASELINE" --current "$JSON_OUT")
  if [[ "$FAIL_ON_REGRESSION" == "1" ]]; then
    compare_args+=(--fail-on-regression)
  fi
  node "${compare_args[@]}"
fi
