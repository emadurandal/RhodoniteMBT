///|
/// Open phase group identifier used by external drivers to choose a clock domain.
pub(all) struct PhaseGroupKey {
  name : String
} derive(Eq)

///|
/// Builds a custom phase group key. Use namespaced strings such as `user/fixed` to avoid collisions.
pub fn phase_group(name : String) -> PhaseGroupKey {
  { name, }
}

///|
/// Implements `PhaseGroupKey::name`.
pub fn PhaseGroupKey::name(self : PhaseGroupKey) -> String {
  self.name
}

///|
/// Standard frame-begin group run once at the start of each engine tick.
pub fn phase_group_frame_begin() -> PhaseGroupKey {
  phase_group("rhodonite/frame_begin")
}

///|
/// Standard render-frame group driven by display frame callbacks.
pub fn phase_group_render_frame() -> PhaseGroupKey {
  phase_group("rhodonite/render_frame")
}

///|
/// Standard fixed-step group driven by caller-owned fixed cadence.
pub fn phase_group_fixed_step() -> PhaseGroupKey {
  phase_group("rhodonite/fixed_step")
}
