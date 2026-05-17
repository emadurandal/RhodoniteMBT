///|
/// Drawable surface state owned by the engine and supplied by platform runtimes.
pub(all) struct SurfaceState {
  width : Int
  height : Int
  format : String
  active : Bool
  generation : Int
} derive(Eq)

///|
/// Builds an active drawable surface state.
pub fn SurfaceState::new_active(
  width : Int,
  height : Int,
  format : String,
  generation : Int,
) -> SurfaceState {
  { width, height, format, active: true, generation }
}

///|
/// Builds a suspended drawable surface state for minimized or zero-sized surfaces.
pub fn SurfaceState::suspended(generation : Int) -> SurfaceState {
  { width: 0, height: 0, format: "", active: false, generation }
}

///|
/// Builds the default surface state used when a platform has not reported size yet.
fn default_surface_state() -> SurfaceState {
  SurfaceState::new_active(800, 600, "", 0)
}

///|
/// Returns the drawable width in pixels.
pub fn SurfaceState::width(self : SurfaceState) -> Int {
  self.width
}

///|
/// Returns the drawable height in pixels.
pub fn SurfaceState::height(self : SurfaceState) -> Int {
  self.height
}

///|
/// Returns the drawable texture format.
pub fn SurfaceState::format(self : SurfaceState) -> String {
  self.format
}

///|
/// Reports whether the drawable surface can currently be rendered to.
pub fn SurfaceState::active(self : SurfaceState) -> Bool {
  self.active
}

///|
/// Returns the monotonically increasing surface generation.
pub fn SurfaceState::generation(self : SurfaceState) -> Int {
  self.generation
}

///|
/// Per-frame state passed through the engine lifecycle.
pub(all) struct FrameState {
  delta_seconds : Float
  frame_index : Int
  elapsed_seconds : Double
  surface : SurfaceState
  surface_changed : Bool
}

///|
/// Implements `FrameState::new`.
pub fn FrameState::new(
  delta_seconds : Float,
  frame_index : Int,
  elapsed_seconds : Double,
  surface? : SurfaceState = default_surface_state(),
  surface_changed? : Bool = false,
) -> FrameState {
  { delta_seconds, frame_index, elapsed_seconds, surface, surface_changed }
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
/// Returns the surface snapshot for this frame.
pub fn FrameState::surface(self : FrameState) -> SurfaceState {
  self.surface
}

///|
/// Reports whether the surface state changed before this frame began.
pub fn FrameState::surface_changed(self : FrameState) -> Bool {
  self.surface_changed
}

///|
/// Reports whether rendering to the current surface is allowed.
pub fn FrameState::surface_active(self : FrameState) -> Bool {
  self.surface.active()
}

///|
/// Returns the current surface width in pixels.
pub fn FrameState::surface_width(self : FrameState) -> Int {
  self.surface.width()
}

///|
/// Returns the current surface height in pixels.
pub fn FrameState::surface_height(self : FrameState) -> Int {
  self.surface.height()
}

///|
/// Returns the current surface format.
pub fn FrameState::surface_format(self : FrameState) -> String {
  self.surface.format()
}

///|
/// Returns the current surface generation.
pub fn FrameState::surface_generation(self : FrameState) -> Int {
  self.surface.generation()
}

///|
/// Returns a copy of this frame with a platform surface snapshot attached.
fn FrameState::with_surface(
  self : FrameState,
  surface : SurfaceState,
  changed : Bool,
) -> FrameState {
  FrameState::new(
    self.delta_seconds,
    self.frame_index,
    self.elapsed_seconds,
    surface~,
    surface_changed=changed,
  )
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
