///|
/// Surface-local instance of the ECS scene graph demo.
pub(all) struct SurfaceDemoState {
  id : @app.SurfaceId
  demo : @scene_graph.DemoState
}

///|
/// Coordinates one shared platform demo across multiple presentation surfaces.
pub(all) struct MultiSurfaceDemoState {
  device : @wgpu.GPUDevice
  queue : @wgpu.GPUQueue
  format : String
  surfaces : Array[SurfaceDemoState]
}

///|
/// Creates multi-surface demo state from an engine's shared WebGPU context.
pub fn create_demo_state_for_engine(
  engine : @app.Engine,
) -> MultiSurfaceDemoState {
  let (device, _canvas_context, format, queue) = engine.gpu_context().get()
  { device, queue, format, surfaces: [] }
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
      let demo = @scene_graph.create_demo_state_for_scene(
        scene,
        self.device,
        self.queue,
        self.format,
      )
      let surface_demo = { id, demo }
      self.surfaces.push(surface_demo)
      engine.set_surface_scene(id, scene)
      surface_demo
    }
  }
}

///|
/// Handles surface resize/suspend state for the target surface demo.
fn MultiSurfaceDemoState::handle_surface_frame(
  self : MultiSurfaceDemoState,
  engine : @app.Engine,
  frame : @app.FrameState,
) -> Unit {
  match frame.surface_id() {
    Some(id) => {
      let surface_demo = self.ensure_surface(engine, id)
      if frame.surface_changed() && frame.surface_active() {
        surface_demo.demo.resize_surface_resources(
          frame.surface_width(),
          frame.surface_height(),
        )
      }
    }
    None => ()
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
/// Releases all surface-local scene graph demo resources.
fn MultiSurfaceDemoState::release(self : MultiSurfaceDemoState) -> Unit {
  for i = 0; i < self.surfaces.length(); i = i + 1 {
    self.surfaces[i].demo.release()
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
  engine.add_phase_handler(@app.phase_surface(), fn(engine, frame) {
    demo_state.handle_surface_frame(engine, frame)
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
  engine.add_phase_handler(@app.phase_shutdown(), fn(_engine, _frame) {
    demo_state.release()
  })
}
