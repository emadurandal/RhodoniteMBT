/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Canvas resolution (matches demo HTML).
let canvas_width : UInt = 800U

///|
let canvas_height : UInt = 600U

///|
let vertex_stride_local : Int = 12

///|
let verts_per_cube : Int = 8

///|
let index_u16_count : Int = 36

///|
let camera_elevation_rad : Double = 0.38

///|
/// Implements `cube_local_corners`.
fn cube_local_corners() -> Array[(Double, Double, Double)] {
  [
    (-1.0, -1.0, -1.0),
    (1.0, -1.0, -1.0),
    (1.0, 1.0, -1.0),
    (-1.0, 1.0, -1.0),
    (-1.0, -1.0, 1.0),
    (1.0, -1.0, 1.0),
    (1.0, 1.0, 1.0),
    (-1.0, 1.0, 1.0),
  ]
}

///|
/// Implements `index_cube_u16_bytes`.
fn index_cube_u16_bytes() -> FixedArray[Byte] {
  let buf = FixedArray::make(72, (0 : Byte))
  let idx : Array[UInt] = [
    0U, 1U, 2U, 2U, 3U, 0U, 4U, 5U, 6U, 6U, 7U, 4U, 0U, 4U, 7U, 7U, 3U, 0U, 1U, 5U,
    6U, 6U, 2U, 1U, 0U, 1U, 5U, 5U, 4U, 0U, 3U, 2U, 6U, 6U, 7U, 3U,
  ]
  for i = 0; i < index_u16_count; i = i + 1 {
    @writes.put_u16_le(buf, i * 2, idx[i])
  }
  buf
}

///|
/// Implements `write_vertex_positions_only`.
fn write_vertex_positions_only(buf : FixedArray[Byte], scale : Double) -> Unit {
  let corners = cube_local_corners()
  for vi = 0; vi < verts_per_cube; vi = vi + 1 {
    let (lx, ly, lz) = corners[vi]
    let base = vi * vertex_stride_local
    @writes.put_f32_le(buf, base + 0, lx * scale)
    @writes.put_f32_le(buf, base + 4, ly * scale)
    @writes.put_f32_le(buf, base + 8, lz * scale)
  }
}

///|
/// Defines `DemoState`.
pub(all) struct DemoState {
  context : @wgpu.GPUCanvasContext?
  renderer : @app.Renderer
  scene : @app.Scene
  bodies : Array[@ecs.EntityId]
  gt : @ecs.ComponentTypeId
  renderable : @app.RenderableComponent
  orbit_controller : @ecs.ComponentTypeId
  camera_home : @ecs.ComponentTypeId
  camera_lens : @ecs.ComponentTypeId
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
      self.orbit_controller,
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
/// Implements `create_demo_state`.
pub fn create_demo_state(context : @wgpu.GPUContext) -> DemoState? {
  let engine = @app.Engine::new(context)
  create_demo_state_for_engine(engine)
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
/// Implements `create_demo_state_for_device`.
pub fn create_demo_state_for_device(
  device : @wgpu.GPUDevice,
  queue : @wgpu.GPUQueue,
  format : String,
  context? : @wgpu.GPUCanvasContext? = None,
) -> DemoState {
  create_demo_state_for_scene(
    @app.Scene::new("ecs-scene-graph"),
    device,
    queue,
    format,
    context~,
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
  let vertex_layout_vertices : @wgpu.GPUVertexBufferLayout = {
    array_stride: vertex_stride_local.to_uint64(),
    step_mode: @wgpu.GPUVertexStepMode::Vertex,
    attributes: [
      {
        format: @wgpu.GPUVertexFormat::Float32x3,
        offset: 0UL,
        shader_location: 0U,
      },
    ],
  }
  let renderer = @app.Renderer::new(
    device,
    queue,
    format,
    canvas_width.reinterpret_as_int(),
    canvas_height.reinterpret_as_int(),
    vertex_layout_vertices,
  )
  let world = scene.world()
  let orbit_controller = @ecs.register_orbit_camera_controller_component(world)
  let camera_home = @ecs.register_camera_home_transform_component(world)
  let camera_lens = @ecs.register_camera_lens_component(world)
  let renderable = @app.register_renderable_component(world)
  let camera = world.create_entity()
  let sun = world.create_entity()
  let earth = world.create_entity()
  let moon = world.create_entity()
  scene.add_common_systems(
    transform_propagation=true,
    orbit_component=Some(orbit_controller),
    home_component=Some(camera_home),
    lens_component=Some(camera_lens),
  )
  let bodies : Array[@ecs.EntityId] = [sun, earth, moon]
  let gt = world.global_transform_component()
  let id_m = @m44.Matrix44F::identity()
  ignore(world.set_global_transform(sun, id_m))
  ignore(world.set_global_transform(earth, id_m))
  ignore(world.set_global_transform(moon, id_m))
  ignore(world.set_child_of(earth, sun))
  ignore(world.set_child_of(moon, earth))
  scene.set_main_camera(Some(camera))
  let camera_pan_y = Float::from_double(-2.0 / @math.cos(camera_elevation_rad))
  let camera_distance = Float::from_double(
    5.6 - camera_pan_y.to_double() * @math.sin(camera_elevation_rad),
  )
  let camera_qx = -@math.sin(camera_elevation_rad * 0.5)
  let camera_qw = @math.cos(camera_elevation_rad * 0.5)
  ignore(
    world.set_transform_trs(
      camera,
      (0.0 : Float),
      (2.0 : Float),
      (5.6 : Float),
      camera_qx,
      0.0,
      0.0,
      camera_qw,
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    ),
  )
  ignore(world.set_global_transform(camera, id_m))
  ignore(
    @ecs.add_orbit_camera_controller_with_pose(
      world,
      camera,
      orbit_controller,
      0.0,
      camera_elevation_rad,
      (0.0 : Float),
      camera_pan_y,
      (1.0 : Float),
      camera_distance,
    ),
  )
  ignore(
    @ecs.set_camera_home_from_current_transform(world, camera, camera_home),
  )
  ignore(
    @ecs.add_camera_lens_orthographic(
      world,
      camera,
      camera_lens,
      (0.1 : Float),
      (50.0 : Float),
      (1.0 : Float),
      (3.8 : Float),
      (0.0 : Float),
    ),
  )
  ignore(
    world.set_camera_matrices(
      camera,
      id_m,
      id_m,
      (0.1 : Float),
      (50.0 : Float),
      (1.0 : Float),
      @ecs.camera_projection_orthographic(),
      (0.0 : Float),
    ),
  )
  let vertex_bytes = FixedArray::make(
    verts_per_cube * vertex_stride_local,
    (0 : Byte),
  )
  write_vertex_positions_only(vertex_bytes, 0.42)
  let index_bytes = index_cube_u16_bytes()
  let cube_mesh = renderer.register_static_indexed_mesh(
    vertex_bytes, index_bytes, index_u16_count,
  )
  let sun_material = renderer.register_unlit_material(1.0, 0.65, 0.15)
  let earth_material = renderer.register_unlit_material(0.2, 0.55, 1.0)
  let moon_material = renderer.register_unlit_material(1.0, 0.0, 1.0)
  ignore(@app.add_renderable(world, sun, renderable, cube_mesh, sun_material))
  ignore(
    @app.add_renderable(world, earth, renderable, cube_mesh, earth_material),
  )
  ignore(@app.add_renderable(world, moon, renderable, cube_mesh, moon_material))
  push_local_transforms(world, bodies, 0.0)
  ignore(
    scene.run_systems_for_phase(
      @app.phase_update(),
      @app.FrameState::new((0.0 : Float), 0, 0.0),
    ),
  )
  ignore(
    scene.run_systems_for_phase(
      @app.phase_post_update(),
      @app.FrameState::new((0.0 : Float), 0, 0.0),
    ),
  )
  ignore(
    scene.run_systems_for_phase(
      @app.phase_render_extract(),
      @app.FrameState::new((0.0 : Float), 0, 0.0),
    ),
  )
  {
    context,
    renderer,
    scene,
    bodies,
    gt,
    renderable,
    orbit_controller,
    camera_home,
    camera_lens,
    frame: @ref.new(0),
  }
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
/// Kept `pub` for browser and native visual regression (`visual_regression_browser`,
/// `emadurandal/rhodonite_examples/visual_regression`), which render into an offscreen
/// view without a swapchain. The interactive sample uses `render_current_frame` in
/// `register_engine_handlers` instead.
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
  ignore(demo_state.scene.run_systems_for_phase(@app.phase_update(), frame))
  ignore(
    demo_state.scene.run_systems_for_phase(@app.phase_post_update(), frame),
  )
  ignore(
    demo_state.scene.run_systems_for_phase(@app.phase_render_extract(), frame),
  )
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
  self.renderer.render_scene(scene, self.renderable, color_view)
  @native_gpu_queue.wait_native_gpu_queue(self.renderer.device())
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
  engine.add_common_handlers(demo_state.scene)
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

///|
/// Implements `demo_state_release`.
pub fn demo_state_release(demo_state : DemoState) -> Unit {
  demo_state.release()
}
