///|
/// Mutable render-frame and fixed-step clocks used by the engine runner.
pub struct TimeState {
  priv mut render_frame_index : Int
  priv mut render_elapsed_seconds : Double
  priv mut fixed_frame_index : Int
  priv mut fixed_elapsed_seconds : Double
  priv mut fixed_accumulator_seconds : Double
  priv fixed_delta_seconds : Float
}

///|
/// Returns the default fixed-step duration used by app runtimes.
fn default_fixed_delta_seconds() -> Float {
  (1.0 : Float) / (60.0 : Float)
}

///|
/// Implements `TimeState::new`.
pub fn TimeState::new(fixed_delta_seconds : Float) -> TimeState {
  {
    render_frame_index: 0,
    render_elapsed_seconds: 0.0,
    fixed_frame_index: 0,
    fixed_elapsed_seconds: 0.0,
    fixed_accumulator_seconds: 0.0,
    fixed_delta_seconds,
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
