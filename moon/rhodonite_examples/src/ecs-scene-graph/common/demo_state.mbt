/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
let camera_elevation_rad : Double = 0.38

///|
/// Defines `DemoState`.
pub(all) struct DemoState {
  context : @wgpu.GPUCanvasContext?
  renderer : @app.Renderer
  target : @app.RenderTargetResources
  scene : @app.Scene
  bodies : Array[@ecs.EntityId]
  gt : @ecs.ComponentTypeId
  frame : @ref.Ref[Int]
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
/// Updates sample animation inputs before the owning engine runs the scene system_runner.
pub fn DemoState::update_scene(
  self : DemoState,
  frame : @app.FrameState,
) -> Unit {
  let world = self.scene.world()
  let bodies = self.bodies
  let t = frame.elapsed_seconds()
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
/// Renders a scene by uploading scene-owned ECS data and issuing draw commands.
pub fn DemoState::render_scene(
  self : DemoState,
  scene : @app.Scene,
  color_view : @wgpu.GPUTextureView,
) -> Unit {
  self.renderer.render_scene_renderables(scene, self.target, color_view)
  @native_gpu_queue.wait_native_gpu_queue(self.renderer.device())
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
  demo_state.render_scene(demo_state.scene, color_view)
  @wgpu.textureView_release(color_view)
  @native_gpu_queue.wait_native_gpu_queue(demo_state.renderer.device())
  canvas_context.present()
}

///|
/// Registers engine phase handlers that drive this DemoState.
pub fn register_engine_handlers(
  engine : @app.Engine,
  demo_state : DemoState,
) -> Unit {
  engine.on_scene_update(demo_state.scene, fn(frame) {
    demo_state.update_scene(frame)
  })
  engine.on_scene_render(demo_state.scene, fn(_frame) {
    render_current_frame(demo_state)
  })
}

///|
/// Creates demo state backed by caller-owned renderer and target resources.
pub fn create_demo_state(
  scene : @app.Scene,
  renderer : @app.Renderer,
  target : @app.RenderTargetResources,
  context? : @wgpu.GPUCanvasContext? = None,
) -> DemoState {
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
  let demo_state = {
    context,
    renderer,
    target,
    scene,
    bodies,
    gt,
    frame: @ref.new(0),
  }
  demo_state.update_scene(@app.FrameState::new((0.0 : Float), 0, 0.0))
  demo_state
}

///|
/// Creates DemoState and registers the sample engine handlers.
pub fn setup_engine(engine : @app.Engine) -> Bool {
  let (_device, canvas_context, _format, _queue) = engine.gpu_context().get()
  let demo_state = create_demo_state(
    engine.main_scene(),
    engine.renderer(),
    engine.render_target_resources(),
    context=Some(canvas_context),
  )
  register_engine_handlers(engine, demo_state)
  true
}
