/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Number of pulsing cube entities arranged in a square grid.
let entity_count : Int = 25

///|
/// Number of entities along one side of the grid.
let grid_side : Int = 5

///|
/// Byte stride of the custom `PulseColor` component.
let pulse_color_stride : Int = 24

///|
/// Byte stride of the renderer v1 instance row.
let instance_stride : Int = 24

///|
/// Camera pitch used by the custom component color sample.
let camera_elevation_rad : Double = 0.52

///|
/// Defines the sample state driven by the custom `PulseColor` component.
pub(all) struct DemoState {
  context : @wgpu.GPUCanvasContext?
  renderer : @app.Renderer
  target : @app.RenderTargetResources
  scene : @app.Scene
  cube_mesh : @app.MeshHandle
  instance_buffer : @app.InstanceBufferHandle
  entities : Array[@ecs.EntityId]
  instance_bytes : FixedArray[Byte]
  pulse_color : @ecs.ComponentTypeId
}

///|
/// Registers the custom component used to drive per-instance colors.
fn register_pulse_color_component(world : @ecs.World) -> @ecs.ComponentTypeId {
  world.register_component("RhodoniteExamplePulseColor", pulse_color_stride)
}

///|
/// Returns one channel from the pulsing palette.
fn pulse_palette_channel(index : Int, channel : Int) -> Double {
  let band = (index * 7 + channel * 11) % 17
  0.18 + band.to_double() * 0.045
}

///|
/// Builds the custom `PulseColor` component bytes for one entity.
fn pulse_color_bytes(index : Int, slot : Int) -> FixedArray[Byte] {
  let bytes = FixedArray::make(pulse_color_stride, (0 : Byte))
  @writes.put_f32_le(bytes, 0, pulse_palette_channel(index, 0))
  @writes.put_f32_le(bytes, 4, pulse_palette_channel(index, 1))
  @writes.put_f32_le(bytes, 8, pulse_palette_channel(index, 2))
  @writes.put_f32_le(bytes, 12, index.to_double() * 0.37)
  @writes.put_f32_le(bytes, 16, 0.75 + (index % 5).to_double() * 0.18)
  @writes.put_u32_le(bytes, 20, slot.reinterpret_as_uint())
  bytes
}

///|
/// Reads an f32 value from a component row view.
fn view_get_f32(bytes : ArrayView[Byte], offset : Int) -> Double {
  Float::reinterpret_from_uint(@writes.get_u32_le_byte_view(bytes, offset)).to_double()
}

///|
/// Reads an f32 value from a mutable component row view.
fn mut_view_get_f32(bytes : MutArrayView[Byte], offset : Int) -> Double {
  Float::reinterpret_from_uint(@writes.get_u32_le_mut_view(bytes, offset)).to_double()
}

///|
/// Advances all pulse phases through the custom component.
fn update_pulse_colors(
  world : @ecs.World,
  component : @ecs.ComponentTypeId,
  delta_seconds : Float,
) -> Unit {
  let query = @ecs.Query::new([component])
  let dt = delta_seconds.to_double()
  query.for_each(world, row => {
    row.write(component, bytes => {
      let phase = mut_view_get_f32(bytes, 12)
      let speed = mut_view_get_f32(bytes, 16)
      @writes.put_f32_le_mut_view(bytes, 12, phase + dt * speed)
    })
  })
}

///|
/// Writes one RGB color into the renderer instance bytes.
fn write_instance_color(
  bytes : FixedArray[Byte],
  slot : Int,
  r : Double,
  g : Double,
  b : Double,
) -> Unit {
  if slot < 0 || slot >= entity_count {
    return
  }
  let base = slot * instance_stride
  @writes.put_f32_le(bytes, base + 8, r)
  @writes.put_f32_le(bytes, base + 12, g)
  @writes.put_f32_le(bytes, base + 16, b)
}

///|
/// Synchronizes custom component values into the renderer-owned instance buffer.
fn sync_instance_colors_from_components(demo_state : DemoState) -> Unit {
  let query = @ecs.Query::new([demo_state.pulse_color])
  query.for_each(demo_state.scene.world(), row => {
    row.read(demo_state.pulse_color, bytes => {
      let base_r = view_get_f32(bytes, 0)
      let base_g = view_get_f32(bytes, 4)
      let base_b = view_get_f32(bytes, 8)
      let phase = view_get_f32(bytes, 12)
      let slot = @writes.get_u32_le_byte_view(bytes, 20).reinterpret_as_int()
      let intensity = 0.68 + 0.32 * @math.sin(phase)
      write_instance_color(
        demo_state.instance_bytes,
        slot,
        base_r * intensity,
        base_g * intensity,
        base_b * intensity,
      )
    })
  })
  ignore(
    demo_state.renderer.update_static_instance_buffer(
      demo_state.instance_buffer,
      demo_state.instance_bytes,
    ),
  )
}

///|
/// Registers ECS systems that mutate and extract the custom component.
fn add_pulse_color_systems(demo_state : DemoState) -> Unit {
  demo_state.scene.add_system(
    @app.phase_update(),
    "ecs-custom-component-color/update-pulse",
    [],
    [demo_state.pulse_color],
    fn(world, ctx, _commands) {
      update_pulse_colors(world, demo_state.pulse_color, ctx.delta_seconds)
    },
  )
  demo_state.scene.add_system(
    @app.phase_render_extract(),
    "ecs-custom-component-color/sync-instance-colors",
    [demo_state.pulse_color],
    [],
    fn(_world, _ctx, _commands) {
      sync_instance_colors_from_components(demo_state)
    },
  )
}

///|
/// Copies compact GlobalTransform refs into renderer instance rows.
fn write_instance_transform_refs(
  instance_bytes : FixedArray[Byte],
  refs : FixedArray[Byte],
) -> Unit {
  for i = 0; i < entity_count; i = i + 1 {
    let dst = i * instance_stride
    let src = i * 8
    for j = 0; j < 8; j = j + 1 {
      instance_bytes[dst + j] = refs[src + j]
    }
  }
}

///|
/// Places one entity in the sample grid and attaches the custom component.
fn setup_grid_entity(
  world : @ecs.World,
  entity : @ecs.EntityId,
  pulse_color : @ecs.ComponentTypeId,
  index : Int,
) -> Unit {
  let col = index % grid_side
  let row = index / grid_side
  let half = (grid_side - 1).to_double() * 0.5
  let x = (col.to_double() - half) * 1.05
  let z = (row.to_double() - half) * 1.05
  ignore(
    world.set_transform_trs(
      entity,
      Float::from_double(x),
      (0.0 : Float),
      Float::from_double(z),
      0.0,
      0.0,
      0.0,
      1.0,
      (0.36 : Float),
      (0.36 : Float),
      (0.36 : Float),
    ),
  )
  ignore(world.set_global_transform(entity, @m44.Matrix44F::identity()))
  ignore(
    world.add_component_bytes(
      entity,
      pulse_color,
      pulse_color_bytes(index, index),
    ),
  )
}

///|
/// Creates the demo state backed by the caller-owned engine resources.
pub fn create_demo_state(
  scene : @app.Scene,
  renderer : @app.Renderer,
  target : @app.RenderTargetResources,
  context? : @wgpu.GPUCanvasContext? = None,
) -> DemoState {
  let world = scene.world()
  let pulse_color = register_pulse_color_component(world)
  let camera = world.create_entity()
  ignore(
    @ecs.setup_orbit_orthographic_camera(
      world,
      camera,
      @ecs.OrbitOrthographicCameraDesc::new_yz_pitched(
        camera_elevation_rad,
        (2.0 : Float),
        (7.0 : Float),
        (0.1 : Float),
        (80.0 : Float),
        (1.0 : Float),
        (4.2 : Float),
      ),
    ),
  )
  scene.set_main_camera(Some(camera))
  let entities : Array[@ecs.EntityId] = []
  for i = 0; i < entity_count; i = i + 1 {
    let entity = world.create_entity()
    setup_grid_entity(world, entity, pulse_color, i)
    entities.push(entity)
  }
  world.update_global_transforms_from_transforms()
  let instance_bytes = FixedArray::make(
    entity_count * instance_stride,
    (0 : Byte),
  )
  write_instance_transform_refs(
    instance_bytes,
    world.extract_global_transform_refs(entities),
  )
  let cube_mesh = renderer.register_cube_mesh(
    desc=@app.CubeMeshDesc::new(half_extent=0.42),
  )
  let instance_buffer = renderer.register_static_instance_buffer(instance_bytes)
  let demo_state = {
    context,
    renderer,
    target,
    scene,
    cube_mesh,
    instance_buffer,
    entities,
    instance_bytes,
    pulse_color,
  }
  sync_instance_colors_from_components(demo_state)
  add_pulse_color_systems(demo_state)
  demo_state
}

///|
/// Renders the current sample frame without advancing app time.
pub fn render_current_frame(demo_state : DemoState) -> Unit {
  let canvas_context = match demo_state.context {
    Some(c) => c
    None => abort("render_current_frame requires a canvas context")
  }
  let texture = canvas_context.get_current_texture()
  let color_view = texture.create_view()
  demo_state.render_scene(demo_state.scene, color_view)
  @wgpu.textureView_release(color_view)
  canvas_context.present()
}

///|
/// Renders the component-driven instance buffer into a supplied view.
pub fn DemoState::render_scene(
  self : DemoState,
  scene : @app.Scene,
  color_view : @wgpu.GPUTextureView,
) -> Unit {
  self.renderer.render_instanced_mesh(
    scene,
    self.cube_mesh,
    self.instance_buffer,
    self.entities.length(),
    self.target,
    color_view,
  )
}

///|
/// Registers engine handlers that drive this DemoState.
pub fn register_engine_handlers(
  engine : @app.Engine,
  demo_state : DemoState,
) -> Unit {
  engine.on_scene_render(demo_state.scene, fn(_frame) {
    render_current_frame(demo_state)
  })
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
