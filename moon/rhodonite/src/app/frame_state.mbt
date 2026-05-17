///|
/// Per-frame state passed through the engine lifecycle.
pub(all) struct FrameState {
  delta_seconds : Float
  frame_index : Int
  elapsed_seconds : Double
}

///|
/// Implements `FrameState::new`.
pub fn FrameState::new(
  delta_seconds : Float,
  frame_index : Int,
  elapsed_seconds : Double,
) -> FrameState {
  { delta_seconds, frame_index, elapsed_seconds }
}

///|
/// Implements `FrameState::delta_seconds`.
pub fn FrameState::delta_seconds(self : FrameState) -> Float {
  self.delta_seconds
}

///|
/// Implements `FrameState::frame_index`.
pub fn FrameState::frame_index(self : FrameState) -> Int {
  self.frame_index
}

///|
/// Implements `FrameState::elapsed_seconds`.
pub fn FrameState::elapsed_seconds(self : FrameState) -> Double {
  self.elapsed_seconds
}

///|
/// Converts the engine frame state to an ECS system context.
pub fn FrameState::system_context(self : FrameState) -> @ecs.SystemContext {
  @ecs.SystemContext::new(self.delta_seconds, self.frame_index)
}

///|
/// Builds a frame state for one-shot phases that do not advance time.
fn zero_frame_state() -> FrameState {
  FrameState::new((0.0 : Float), 0, 0.0)
}
