/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Runs render-frame phases, skipping surface-dependent phases while suspended.
fn Engine::run_render_frame_group_for_surface(
  self : Engine,
  frame : FrameState,
) -> Unit {
  let group_index = self.find_phase_group(
    "Engine::run_render_frame_group_for_surface",
    phase_group_render_frame(),
  )
  let phases = self.phase_groups[group_index].phases
  for i = 0; i < phases.length(); i = i + 1 {
    let phase = phases[i]
    if frame.surface_active() || !phase_is_render_path(phase) {
      self.run_phase(phase, frame)
    }
  }
}

///|
/// Runs render-frame phases once per registered surface using surface-local frame state.
fn Engine::run_render_frame_group_for_multi_surface(
  self : Engine,
  base_frame : FrameState,
) -> Unit {
  let group_index = self.find_phase_group(
    "Engine::run_render_frame_group_for_multi_surface",
    phase_group_render_frame(),
  )
  let phases = self.phase_groups[group_index].phases
  let surface_views : Array[RenderFrameSurfaceView] = []
  for i = 0; i < self.surfaces.length(); i = i + 1 {
    let surface = self.surfaces[i]
    surface_views.push({
      id: surface.id(),
      state: surface.state(),
      changed: surface.changed,
      input_state: surface.input(),
    })
  }
  for i = 0; i < phases.length(); i = i + 1 {
    let phase = phases[i]
    for view_index = 0
        view_index < surface_views.length()
        view_index = view_index + 1 {
      let view = surface_views[view_index]
      if view.state.active() || !phase_is_render_path(phase) {
        let frame = base_frame.with_surface_view(
          view.id,
          view.state,
          view.changed,
          view.input_state,
        )
        self.run_phase(phase, frame)
      }
    }
  }
}

///|
/// Runs each ready fixed-step frame after real elapsed time has accumulated.
fn Engine::run_ready_fixed_steps(
  self : Engine,
  elapsed_seconds : Float,
  surface : SurfaceState,
  surface_changed : Bool,
) -> Int {
  self.time_state.push_fixed_elapsed(elapsed_seconds)
  self.time_state.drain_ready_fixed_frames(fn(fixed_frame) {
    let frame = fixed_frame.with_surface(surface, surface_changed)
    self.run_phase_group(phase_group_fixed_step(), frame)
  })
}

///|
/// Advances one standard engine tick and runs frame-begin, fixed, and render phases.
pub fn Engine::run_frame(self : Engine, elapsed_seconds : Float) -> Int {
  self.ensure_initialized("Engine::run_frame")
  ignore(self.consume_render_requested())
  self.input_state.begin_frame()
  let surface = self.surface_state
  let surface_changed = self.surface_changed
  let frame = self.time_state
    .next_render_frame(elapsed_seconds)
    .with_surface(surface, surface_changed)
  self.run_phase_group(phase_group_frame_begin(), frame)
  let fixed_steps = self.run_ready_fixed_steps(
    elapsed_seconds, surface, surface_changed,
  )
  self.run_render_frame_group_for_surface(frame)
  self.surface_changed = false
  fixed_steps
}

///|
/// Advances one engine tick and renders every registered platform surface.
pub fn Engine::run_multi_surface_frame(
  self : Engine,
  elapsed_seconds : Float,
) -> Int {
  self.ensure_initialized("Engine::run_multi_surface_frame")
  if self.surfaces.length() == 0 {
    return self.run_frame(elapsed_seconds)
  }
  ignore(self.consume_render_requested())
  self.input_state.begin_frame()
  let base_frame = self.time_state.next_render_frame(elapsed_seconds)
  for i = 0; i < self.surfaces.length(); i = i + 1 {
    let surface = self.surfaces[i]
    surface.sync_from_gpu_surface()
    surface.input().begin_frame()
    let changed = surface.changed
    let frame = base_frame.with_surface_view(
      surface.id(),
      surface.state(),
      changed,
      surface.input(),
    )
    self.run_phase_group(phase_group_frame_begin(), frame)
  }
  let fixed_steps = self.run_ready_fixed_steps(
    elapsed_seconds,
    self.surface_state,
    self.surface_changed,
  )
  self.run_render_frame_group_for_multi_surface(base_frame)
  for i = 0; i < self.surfaces.length(); i = i + 1 {
    ignore(self.surfaces[i].consume_changed())
  }
  self.surface_changed = false
  fixed_steps
}
