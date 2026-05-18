#!/usr/bin/env bash
set -u
pkill -9 -f "ecs-mass-cubes/wgpu/main" 2>/dev/null || true
cd /home/emadurandal/program/RhodoniteMBT/moon/rhodonite_examples
export DISPLAY=:0 WAYLAND_DISPLAY=wayland-0
LOG=/home/emadurandal/program/RhodoniteMBT/_ecs_mass_run.log
META=/home/emadurandal/program/RhodoniteMBT/_ecs_mass_run.meta
: > "$LOG"
moon run --target native --release src/ecs-mass-cubes/wgpu/main >>"$LOG" 2>&1 &
PID=$!
echo "moon_pid=$PID" > "$META"
sleep 15
if kill -0 "$PID" 2>/dev/null; then
  echo "PROCESS_STILL_RUNNING_AFTER_15_SECONDS: yes" >> "$META"
  kill -9 "$PID" 2>/dev/null || true
  wait "$PID" 2>/dev/null || true
else
  echo "PROCESS_STILL_RUNNING_AFTER_15_SECONDS: no" >> "$META"
  wait "$PID" 2>/dev/null || true
  echo "wait_exit=$?" >> "$META"
fi
