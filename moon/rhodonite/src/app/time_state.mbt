///|
/// Mutable fixed-step clock used by the engine runner.
pub struct TimeState {
  priv mut frame_index : Int
  priv mut elapsed_seconds : Double
  priv fixed_delta_seconds : Float
}

///|
/// Implements `TimeState::new`.
pub fn TimeState::new(fixed_delta_seconds : Float) -> TimeState {
  { frame_index: 0, elapsed_seconds: 0.0, fixed_delta_seconds }
}

///|
/// Advances the fixed-step clock and returns the next frame state.
pub fn TimeState::next_frame(self : TimeState) -> FrameState {
  self.frame_index = self.frame_index + 1
  self.elapsed_seconds = self.elapsed_seconds +
    self.fixed_delta_seconds.to_double()
  FrameState::new(
    self.fixed_delta_seconds,
    self.frame_index,
    self.elapsed_seconds,
  )
}
