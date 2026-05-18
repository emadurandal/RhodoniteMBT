///|
/// Mutable render-frame and fixed-step clocks used by the engine runner.
pub struct TimeState {
  priv mut render_frame_index : Int
  priv mut render_elapsed_seconds : Double
  priv mut fixed_frame_index : Int
  priv mut fixed_elapsed_seconds : Double
  priv mut fixed_accumulator_seconds : Double
  priv fixed_delta_seconds : Float
  priv max_fixed_steps_per_frame : Int
}

///|
/// Returns the default fixed-step duration used by app runtimes.
fn default_fixed_delta_seconds() -> Float {
  (1.0 : Float) / (60.0 : Float)
}

///|
/// Returns the default cap for fixed-step frames run during one engine tick.
fn default_max_fixed_steps_per_frame() -> Int {
  5
}

///|
/// Implements `TimeState::new`.
pub fn TimeState::new(fixed_delta_seconds : Float) -> TimeState {
  TimeState::new_with_fixed_step_limit(
    fixed_delta_seconds,
    default_max_fixed_steps_per_frame(),
  )
}

///|
/// Builds a time state with an explicit per-tick fixed-step cap.
fn TimeState::new_with_fixed_step_limit(
  fixed_delta_seconds : Float,
  max_fixed_steps_per_frame : Int,
) -> TimeState {
  if fixed_delta_seconds <= (0.0 : Float) {
    abort("TimeState::new_with_fixed_step_limit: fixed delta must be positive")
  }
  if max_fixed_steps_per_frame <= 0 {
    abort(
      "TimeState::new_with_fixed_step_limit: max fixed steps must be positive",
    )
  }
  {
    render_frame_index: 0,
    render_elapsed_seconds: 0.0,
    fixed_frame_index: 0,
    fixed_elapsed_seconds: 0.0,
    fixed_accumulator_seconds: 0.0,
    fixed_delta_seconds,
    max_fixed_steps_per_frame,
  }
}

///|
/// Advances the render-frame clock using caller-supplied elapsed time.
pub fn TimeState::next_render_frame(
  self : TimeState,
  delta_seconds : Float,
) -> FrameState {
  self.render_frame_index = self.render_frame_index + 1
  self.render_elapsed_seconds = self.render_elapsed_seconds +
    delta_seconds.to_double()
  FrameState::new(
    delta_seconds,
    self.render_frame_index,
    self.render_elapsed_seconds,
  )
}

///|
/// Adds real elapsed time to the fixed-step accumulator.
pub fn TimeState::push_fixed_elapsed(
  self : TimeState,
  elapsed_seconds : Float,
) -> Unit {
  self.fixed_accumulator_seconds = self.fixed_accumulator_seconds +
    elapsed_seconds.to_double()
}

///|
/// Reports whether the fixed-step accumulator can produce another frame.
pub fn TimeState::can_step_fixed(self : TimeState) -> Bool {
  self.fixed_accumulator_seconds >= self.fixed_delta_seconds.to_double()
}

///|
/// Returns the maximum fixed-step frames this time state should run per tick.
fn TimeState::max_fixed_steps_per_frame(self : TimeState) -> Int {
  self.max_fixed_steps_per_frame
}

///|
/// Advances the fixed-step clock by one fixed delta and returns its frame state.
pub fn TimeState::next_fixed_frame(self : TimeState) -> FrameState {
  self.fixed_accumulator_seconds = self.fixed_accumulator_seconds -
    self.fixed_delta_seconds.to_double()
  self.fixed_frame_index = self.fixed_frame_index + 1
  self.fixed_elapsed_seconds = self.fixed_elapsed_seconds +
    self.fixed_delta_seconds.to_double()
  FrameState::new(
    self.fixed_delta_seconds,
    self.fixed_frame_index,
    self.fixed_elapsed_seconds,
  )
}

///|
/// Drops pending fixed-step backlog after a tick reaches its iteration cap.
fn TimeState::discard_fixed_accumulator(self : TimeState) -> Unit {
  self.fixed_accumulator_seconds = 0.0
}

///|
/// Runs ready fixed-step frames up to the per-tick cap and drops excess backlog.
pub fn TimeState::drain_ready_fixed_frames(
  self : TimeState,
  run : (FrameState) -> Unit,
) -> Int {
  let mut count = 0
  let max_steps = self.max_fixed_steps_per_frame()
  while count < max_steps && self.can_step_fixed() {
    run(self.next_fixed_frame())
    count = count + 1
  }
  if self.can_step_fixed() {
    self.discard_fixed_accumulator()
  }
  count
}
