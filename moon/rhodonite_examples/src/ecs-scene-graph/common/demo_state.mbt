/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Canvas resolution (matches demo HTML).
let canvas_width : UInt = 800U

///|
let canvas_height : UInt = 600U

///|
let camera_elevation_rad : Double = 0.38

///|
/// Defines `DemoState`.
pub(all) struct DemoState {
  context : @wgpu.GPUCanvasContext?
  renderer : @app.Renderer
  scene : @app.Scene
  bodies : Array[@ecs.EntityId]
  gt : @ecs.ComponentTypeId
  frame : @ref.Ref[Int]
}

///|
/// Recreates surface-sized render resources for callers that render into an external surface.
pub fn DemoState::resize_surface_resources(
  self : DemoState,
  width : Int,
  height : Int,
) -> Unit {
  self.renderer.resize_surface_resources(width, height)
}

///|
/// Applies surface changes to sample-owned render resources.
fn DemoState::handle_surface_frame(
  self : DemoState,
  frame : @app.FrameState,
) -> Unit {
  if frame.surface_changed() && frame.surface_active() {
    self.renderer.resize_surface_resources(
      frame.surface_width(),
      frame.surface_height(),
    )
  }
}

///|
/// Applies surface-local input to the scene camera orbit controller.
pub fn DemoState::update_camera_from_input(
  self : DemoState,
  input : @input.InputState,
) -> Unit {
  let camera = match self.scene.main_camera() {
    Some(camera) => camera
    None => abort("DemoState::update_camera_from_input requires a main camera")
  }
  ignore(
    @ecs.update_orbit_camera_controller_from_mouse_frame(
      self.scene.world(),
      camera,
      input.mouse_down(Left),
      input.mouse_pressed(Left),
      input.mouse_down(Middle),
      input.mouse_pressed(Middle),
      input.pointer_delta_x(),
      input.pointer_delta_y(),
      input.wheel_delta_y(),
    ),
  )
}

///|
/// Implements `create_demo_state_for_engine`.
pub fn create_demo_state_for_engine(engine : @app.Engine) -> DemoState? {
  let (device, canvas_context, format, queue) = engine.gpu_context().get()
  Some(
    create_demo_state_for_scene(
      engine.main_scene(),
      device,
      queue,
      format,
      context=Some(canvas_context),
    ),
  )
}

///|
/// Implements `create_demo_state_for_scene`.
pub fn create_demo_state_for_scene(
  scene : @app.Scene,
  device : @wgpu.GPUDevice,
  queue : @wgpu.GPUQueue,
  format : String,
  context? : @wgpu.GPUCanvasContext? = None,
) -> DemoState {
  let renderer = @app.Renderer::new(
    device,
    queue,
    format,
    canvas_width.reinterpret_as_int(),
    canvas_height.reinterpret_as_int(),
    @app.cube_position3_vertex_layout(),
  )
  let world = scene.world()
  let camera = world.create_entity()
  let sun = world.create_entity()
  let earth = world.create_entity()
  let moon = world.create_entity()
  let bodies : Array[@ecs.EntityId] = [sun, earth, moon]
  let gt = world.global_transform_component()
  let id_m = @m44.Matrix44F::identity()
  ignore(world.set_global_transform(sun, id_m))
  ignore(world.set_global_transform(earth, id_m))
  ignore(world.set_global_transform(moon, id_m))
  ignore(world.set_child_of(earth, sun))
  ignore(world.set_child_of(moon, earth))
  scene.set_main_camera(Some(camera))
  ignore(
    @ecs.setup_orbit_orthographic_camera(
      world,
      camera,
      @ecs.OrbitOrthographicCameraDesc::new_yz_pitched(
        camera_elevation_rad,
        (2.0 : Float),
        (5.6 : Float),
        (0.1 : Float),
        (50.0 : Float),
        (1.0 : Float),
        (3.8 : Float),
      ),
    ),
  )
  let cube_mesh = renderer.register_cube_mesh(
    desc=@app.CubeMeshDesc::new(half_extent=0.42),
  )
  let sun_material = renderer.register_unlit_material(
    @app.UnlitMaterialDesc::new(1.0, 0.65, 0.15),
  )
  let earth_material = renderer.register_unlit_material(
    @app.UnlitMaterialDesc::new(0.2, 0.55, 1.0),
  )
  let moon_material = renderer.register_unlit_material(
    @app.UnlitMaterialDesc::new(1.0, 0.0, 1.0),
  )
  ignore(
    @app.add_renderable(
      scene,
      sun,
      @app.RenderableDesc::new(cube_mesh, sun_material),
    ),
  )
  ignore(
    @app.add_renderable(
      scene,
      earth,
      @app.RenderableDesc::new(cube_mesh, earth_material),
    ),
  )
  ignore(
    @app.add_renderable(
      scene,
      moon,
      @app.RenderableDesc::new(cube_mesh, moon_material),
    ),
  )
  push_local_transforms(world, bodies, 0.0)
  { context, renderer, scene, bodies, gt, frame: @ref.new(0) }
}

///|
/// Implements `quat_y`.
fn quat_y(angle : Double) -> (Double, Double, Double, Double) {
  let half = angle * 0.5
  let s = @math.sin(half)
  let c = @math.cos(half)
  (0.0, s, 0.0, c)
}

///|
/// Implements `push_local_transforms`.
fn push_local_transforms(
  world : @ecs.World,
  bodies : Array[@ecs.EntityId],
  t : Double,
) -> Unit {
  let sun_angle = t * 0.35
  let earth_orbit = t * 0.9
  let earth_spin = t * 2.2
  let moon_orbit = t * 2.8
  let (sqx, sqy, sqz, sqw) = quat_y(sun_angle)
  ignore(
    world.set_transform_trs(
      bodies[0],
      (0.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
      sqx,
      sqy,
      sqz,
      sqw,
      (0.55 : Float),
      (0.55 : Float),
      (0.55 : Float),
    ),
  )
  let ex = @math.cos(earth_orbit) * 2.35
  let ez = @math.sin(earth_orbit) * 2.35
  let (eqx, eqy, eqz, eqw) = quat_y(earth_spin)
  ignore(
    world.set_transform_trs(
      bodies[1],
      Float::from_double(ex),
      (0.0 : Float),
      Float::from_double(ez),
      eqx,
      eqy,
      eqz,
      eqw,
      (0.22 : Float),
      (0.22 : Float),
      (0.22 : Float),
    ),
  )
  let moon_orbit_radius = 1.05
  let mx = @math.cos(moon_orbit) * moon_orbit_radius
  let mz = @math.sin(moon_orbit) * moon_orbit_radius
  ignore(
    world.set_transform_trs(
      bodies[2],
      Float::from_double(mx),
      (0.0 : Float),
      Float::from_double(mz),
      0.0,
      0.0,
      0.0,
      1.0,
      (0.5 : Float),
      (0.5 : Float),
      (0.5 : Float),
    ),
  )
}

///|
/// Renders the current scene state without advancing app time or running systems.
pub fn render_current_frame(demo_state : DemoState) -> Unit {
  let canvas_context = match demo_state.context {
    Some(c) => c
    None => abort("render_current_frame requires a canvas context")
  }
  @native_gpu_queue.wait_native_gpu_queue(demo_state.renderer.device())
  let texture = canvas_context.get_current_texture()
  let color_view = texture.create_view()
  render_current_frame_to_view(demo_state, color_view)
  @wgpu.textureView_release(color_view)
  @native_gpu_queue.wait_native_gpu_queue(demo_state.renderer.device())
  canvas_context.present()
}

///|
/// Updates sample animation inputs before the owning engine runs the scene system_runner.
pub fn DemoState::update_scene(
  self : DemoState,
  frame : @app.FrameState,
) -> Unit {
  push_local_transforms(
    self.scene.world(),
    self.bodies,
    frame.elapsed_seconds(),
  )
}

///|
/// Advances the demo clock, runs one frame of ECS phases, then draws into `color_view`.
///
/// Kept `pub` for callers that render into an offscreen view without a swapchain.
/// The visual regression harness uses platform single-frame rendering.
pub fn render_frame_to_view(
  demo_state : DemoState,
  color_view : @wgpu.GPUTextureView,
) -> Unit {
  demo_state.frame.val = demo_state.frame.val + 1
  let frame = @app.FrameState::new(
    (0.022 : Float),
    demo_state.frame.val,
    demo_state.frame.val.to_double() * 0.022,
  )
  demo_state.update_scene(frame)
  ignore(demo_state.scene.prepare_render_state(frame~))
  render_current_frame_to_view(demo_state, color_view)
}

///|
/// Renders the current scene state to a target view without advancing the scene.
pub fn render_current_frame_to_view(
  demo_state : DemoState,
  color_view : @wgpu.GPUTextureView,
) -> Unit {
  demo_state.render_scene(demo_state.scene, color_view)
}

///|
/// Renders a scene by uploading scene-owned ECS data and issuing draw commands.
pub fn DemoState::render_scene(
  self : DemoState,
  scene : @app.Scene,
  color_view : @wgpu.GPUTextureView,
) -> Unit {
  self.renderer.render_scene_renderables(scene, color_view)
  @native_gpu_queue.wait_native_gpu_queue(self.renderer.device())
}

///|
/// Creates DemoState and registers the sample engine handlers.
pub fn setup_engine(engine : @app.Engine) -> Bool {
  match create_demo_state_for_engine(engine) {
    Some(demo_state) => {
      register_engine_handlers(engine, demo_state)
      true
    }
    None => false
  }
}

///|
/// Registers engine phase handlers that drive this DemoState.
pub fn register_engine_handlers(
  engine : @app.Engine,
  demo_state : DemoState,
) -> Unit {
  engine.add_phase_handler(@app.phase_surface(), fn(_engine, frame) {
    demo_state.handle_surface_frame(frame)
  })
  engine.add_phase_handler(@app.phase_update(), fn(_engine, frame) {
    demo_state.update_scene(frame)
  })
  engine.add_phase_handler(
    @app.phase_render(),
    fn(_engine, _frame) {
      if demo_state.scene.visible() {
        render_current_frame(demo_state)
      }
    },
    slot=@app.PhaseSlot::AfterSystems,
  )
  engine.add_phase_handler(@app.phase_shutdown(), fn(_engine, _frame) {
    demo_state.release()
  })
}

///|
/// Implements `DemoState::release`.
pub fn DemoState::release(self : DemoState) -> Unit {
  self.renderer.release()
}
