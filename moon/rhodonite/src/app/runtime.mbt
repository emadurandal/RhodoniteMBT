///|
/// Open lifecycle phase identifier shared by engine tasks, engine handlers, and scene systems.
pub type PhaseKey = @ecs.PhaseKey

///|
/// Execution slot inside an engine phase.
pub(all) enum PhaseSlot {
  BeforeSystems
  AfterSystems
} derive(Eq)

///|
/// Builds a custom phase key. Use namespaced strings such as `user/my_phase` to avoid collisions.
pub fn phase(name : String) -> PhaseKey {
  @ecs.PhaseKey::new(name)
}

///|
/// Standard startup phase.
pub fn phase_startup() -> PhaseKey {
  phase("rhodonite/startup")
}

///|
/// Standard surface phase. Platform runtimes finalize resize/suspend state before input.
pub fn phase_surface() -> PhaseKey {
  phase("rhodonite/surface")
}

///|
/// Standard input phase. Platform adapters finalize queued input before this phase.
pub fn phase_input() -> PhaseKey {
  phase("rhodonite/input")
}

///|
/// Standard gameplay update phase.
pub fn phase_update() -> PhaseKey {
  phase("rhodonite/update")
}

///|
/// Standard fixed-step gameplay update phase.
pub fn phase_fixed_update() -> PhaseKey {
  phase("rhodonite/fixed_update")
}

///|
/// Standard fixed-step post-update phase.
pub fn phase_fixed_post_update() -> PhaseKey {
  phase("rhodonite/fixed_post_update")
}

///|
/// Standard post-update phase.
pub fn phase_post_update() -> PhaseKey {
  phase("rhodonite/post_update")
}

///|
/// Standard renderer extraction phase.
pub fn phase_render_extract() -> PhaseKey {
  phase("rhodonite/render_extract")
}

///|
/// Standard renderer preparation phase.
pub fn phase_render_prepare() -> PhaseKey {
  phase("rhodonite/render_prepare")
}

///|
/// Standard draw phase.
pub fn phase_render() -> PhaseKey {
  phase("rhodonite/render")
}

///|
/// Standard present/finalization phase.
pub fn phase_present() -> PhaseKey {
  phase("rhodonite/present")
}

///|
/// Standard shutdown phase.
pub fn phase_shutdown() -> PhaseKey {
  phase("rhodonite/shutdown")
}

///|
/// Returns the default frame-begin phases in engine execution order.
pub fn default_frame_begin_phases() -> Array[PhaseKey] {
  [phase_surface(), phase_input()]
}

///|
/// Returns the default fixed-step phases in engine execution order.
pub fn default_fixed_step_phases() -> Array[PhaseKey] {
  [phase_fixed_update(), phase_fixed_post_update()]
}

///|
/// Returns the default render-frame phases in engine execution order.
pub fn default_render_frame_phases() -> Array[PhaseKey] {
  [
    phase_update(),
    phase_post_update(),
    phase_render_extract(),
    phase_render_prepare(),
    phase_render(),
    phase_present(),
  ]
}

///|
/// Reports whether a phase is part of the standard rendering path.
fn phase_is_render_path(phase_key : PhaseKey) -> Bool {
  phase_key == phase_render_extract() ||
  phase_key == phase_render_prepare() ||
  phase_key == phase_render() ||
  phase_key == phase_present()
}

///|
/// Copies a phase key array.
fn copy_phase_array(src : Array[PhaseKey]) -> Array[PhaseKey] {
  let out : Array[PhaseKey] = []
  for i = 0; i < src.length(); i = i + 1 {
    out.push(src[i])
  }
  out
}

///|
/// Finds a phase key index or returns -1.
fn phase_array_index(phases : Array[PhaseKey], phase_key : PhaseKey) -> Int {
  for i = 0; i < phases.length(); i = i + 1 {
    if phases[i] == phase_key {
      return i
    }
  }
  -1
}

///|
/// Inserts a phase at an index, preserving existing order.
fn phase_array_insert(
  phases : Array[PhaseKey],
  index : Int,
  phase_key : PhaseKey,
) -> Unit {
  if index < 0 || index > phases.length() {
    abort("phase_array_insert: index out of bounds")
  }
  phases.push(phase_key)
  let mut i = phases.length() - 1
  while i > index {
    phases[i] = phases[i - 1]
    i = i - 1
  }
  phases[index] = phase_key
}

///|
/// Reports whether a phase is an engine one-shot phase.
fn phase_is_one_shot(phase_key : PhaseKey) -> Bool {
  phase_key == phase_startup() || phase_key == phase_shutdown()
}
