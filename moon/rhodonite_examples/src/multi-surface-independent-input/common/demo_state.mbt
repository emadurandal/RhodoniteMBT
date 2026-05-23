/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Surface-local instance of the ECS scene graph demo.
pub(all) struct SurfaceDemoState {
  id : @app.SurfaceId
  demo : @scene_graph.DemoState
}

///|
/// Coordinates one shared platform demo across multiple presentation surfaces.
pub(all) struct MultiSurfaceDemoState {
  surfaces : Array[SurfaceDemoState]
}

///|
/// Creates multi-surface demo state from an engine's shared WebGPU context.
pub fn create_demo_state_for_engine(
  engine : @app.Engine,
) -> MultiSurfaceDemoState {
  ignore(engine)
  { surfaces: [] }
}

///|
/// Finds a registered surface demo index by surface id.
fn MultiSurfaceDemoState::find_surface_index(
  self : MultiSurfaceDemoState,
  id : @app.SurfaceId,
) -> Int? {
  for i = 0; i < self.surfaces.length(); i = i + 1 {
    if self.surfaces[i].id == id {
      return Some(i)
    }
  }
  None
}

///|
/// Returns an existing surface demo or creates one for the engine surface.
fn MultiSurfaceDemoState::ensure_surface(
  self : MultiSurfaceDemoState,
  engine : @app.Engine,
  id : @app.SurfaceId,
) -> SurfaceDemoState {
  match self.find_surface_index(id) {
    Some(index) => self.surfaces[index]
    None => {
      let scene = @app.Scene::new("multi-surface-independent-input")
      engine.set_surface_scene(id, scene)
      let demo = @scene_graph.create_demo_state_with_renderer(
        scene,
        engine.renderer(),
        engine.surface(id).render_target_resources(),
        owns_renderer=false,
        owns_target=false,
      )
      let surface_demo = { id, demo }
      self.surfaces.push(surface_demo)
      surface_demo
    }
  }
}

///|
/// Applies the frame's surface-local input to the matching surface camera.
fn MultiSurfaceDemoState::handle_input_frame(
  self : MultiSurfaceDemoState,
  engine : @app.Engine,
  frame : @app.FrameState,
) -> Unit {
  match (frame.surface_id(), frame.input()) {
    (Some(id), Some(input)) => {
      let surface_demo = self.ensure_surface(engine, id)
      surface_demo.demo.update_camera_from_input(input)
    }
    _ => ()
  }
}

///|
/// Updates animation for the surface targeted by the current engine frame.
fn MultiSurfaceDemoState::update_surface_frame(
  self : MultiSurfaceDemoState,
  engine : @app.Engine,
  frame : @app.FrameState,
) -> Unit {
  match frame.surface_id() {
    Some(id) => {
      let surface_demo = self.ensure_surface(engine, id)
      surface_demo.demo.update_scene(frame)
    }
    None => ()
  }
}

///|
/// Renders the target surface demo into its current drawable.
fn MultiSurfaceDemoState::render_surface_frame(
  self : MultiSurfaceDemoState,
  engine : @app.Engine,
  frame : @app.FrameState,
) -> Unit {
  match frame.surface_id() {
    Some(id) => {
      if !frame.surface_active() {
        return
      }
      let surface_demo = self.ensure_surface(engine, id)
      if !surface_demo.demo.scene.visible() {
        return
      }
      let surface = engine.surface(id).gpu_surface()
      let view = surface.acquire_view()
      @scene_graph.render_current_frame_to_view(surface_demo.demo, view)
      @wgpu.textureView_release(view)
      surface.present()
    }
    None => ()
  }
}

///|
/// Creates scene graph demo state for every engine surface before the first frame.
fn MultiSurfaceDemoState::prepare_all_surfaces(
  self : MultiSurfaceDemoState,
  engine : @app.Engine,
) -> Unit {
  for i = 0; i < engine.surface_count(); i = i + 1 {
    ignore(self.ensure_surface(engine, engine.surface_id_at(i)))
  }
}

///|
/// Registers the multi-surface demo's engine phase handlers.
pub fn register_engine_handlers(
  engine : @app.Engine,
  demo_state : MultiSurfaceDemoState,
) -> Unit {
  engine.add_phase_handler(@app.phase_startup(), fn(engine, _frame) {
    demo_state.prepare_all_surfaces(engine)
  })
  engine.add_phase_handler(@app.phase_input(), fn(engine, frame) {
    demo_state.handle_input_frame(engine, frame)
  })
  engine.add_phase_handler(@app.phase_update(), fn(engine, frame) {
    demo_state.update_surface_frame(engine, frame)
  })
  engine.add_phase_handler(
    @app.phase_render(),
    fn(engine, frame) { demo_state.render_surface_frame(engine, frame) },
    slot=@app.PhaseSlot::AfterSystems,
  )
}
