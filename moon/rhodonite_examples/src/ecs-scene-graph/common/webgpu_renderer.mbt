///|
/// Canvas resolution (matches demo HTML).
let canvas_width : UInt = 800U

///|
let canvas_height : UInt = 600U

///|
let vertex_stride_local : Int = 12

///|
let instance_stride : Int = 24

///|
let verts_per_cube : Int = 8

///|
let index_u16_count : Int = 36

///|
let index_buffer_byte_length : UInt64 = (index_u16_count * 2).to_uint64()

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
/// Implements `empty_offsets`.
fn empty_offsets() -> Array[UInt] {
  []
}

///|
/// Defines `WebGPURenderer`.
pub(all) struct WebGPURenderer {
  context : @wgpu.GPUCanvasContext?
  device : @wgpu.GPUDevice
  queue : @wgpu.GPUQueue
  pipeline : @wgpu.GPURenderPipeline
  depth_texture : @wgpu.GPUTexture
  depth_view : @wgpu.GPUTextureView
  vertex_buffer : @wgpu.GPUBuffer
  instance_buffer : @wgpu.GPUBuffer
  index_buffer : @wgpu.GPUBuffer
  transform_storage : @wgpu.GPUBuffer
  camera_storage : @wgpu.GPUBuffer
  bind_transforms : @wgpu.GPUBindGroup
  bind_camera : @wgpu.GPUBindGroup
  layout_transforms : @wgpu.GPUBindGroupLayout
  layout_camera : @wgpu.GPUBindGroupLayout
  world : @ecs.World
  schedule : @ecs.Schedule
  camera : @ecs.EntityId
  bodies : Array[@ecs.EntityId]
  gt : @ecs.ComponentTypeId
  frame : @ref.Ref[Int]
}

///|
/// Implements `ecs_scene_shader_wgsl`.
fn ecs_scene_shader_wgsl() -> String {
  let prefix_bindings = @ecs_wgsl.global_transform_words_binding_default() +
    @ecs_wgsl.camera_words_binding_default()
  let prefix = prefix_bindings
  let suffix =
    #|
    #|struct VertexOut {
    #|  @builtin(position) position: vec4<f32>,
    #|  @location(0) color: vec3<f32>,
    #|};
    #|
    #|@vertex
    #|fn vertexMain(
    #|  @location(0) local_pos: vec3<f32>,
    #|  @location(1) transform_ref: vec2<u32>,
    #|  @location(2) color: vec3<f32>,
    #|) -> VertexOut {
    #|  let world_pos = rn_transform_point(
    #|    rn_load_global_transform(transform_ref),
    #|    local_pos,
    #|  );
    #|  let camera = rn_load_camera(0u);
    #|  let clip = camera.view_proj * world_pos;
    #|  var o: VertexOut;
    #|  o.position = clip;
    #|  o.color = color;
    #|  return o;
    #|}
    #|
    #|@fragment
    #|fn fragmentMain(@location(0) color: vec3<f32>) -> @location(0) vec4<f32> {
    #|  return vec4<f32>(color, 1.0);
    #|}
    #|
  let code = prefix +
    @ecs_wgsl.global_transform_helpers_default() +
    @ecs_wgsl.camera_helpers_default() +
    suffix
  code
}

///|
/// Implements `create_renderer`.
pub fn create_renderer(context : @wgpu.GPUContext) -> WebGPURenderer? {
  let (device, canvas_context, format, queue) = context.get()
  Some(
    create_renderer_for_device(
      device,
      queue,
      format,
      context=Some(canvas_context),
    ),
  )
}

///|
/// Implements `create_renderer_for_device`.
pub fn create_renderer_for_device(
  device : @wgpu.GPUDevice,
  queue : @wgpu.GPUQueue,
  format : String,
  context? : @wgpu.GPUCanvasContext? = None,
) -> WebGPURenderer {
  let shader = device.create_shader_module(ecs_scene_shader_wgsl())
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
  let vertex_layout_instances = @wgpu.global_transform_ref_instance_vertex_buffer_layout(
    instance_stride.to_uint64(),
    1U,
    0UL,
    [
      {
        format: @wgpu.GPUVertexFormat::Float32x3,
        offset: 8UL,
        shader_location: 2U,
      },
    ],
  )
  let pipeline_descriptor : @wgpu.GPURenderPipelineDescriptor = {
    vertex: shader,
    fragment: shader,
    topology: @wgpu.GPUPrimitiveTopology::TriangleList,
    formats: [format],
    vertex_buffers: [vertex_layout_vertices, vertex_layout_instances],
    depth_stencil_format: Some("depth24plus"),
  }
  let pipeline = device.create_render_pipeline(pipeline_descriptor)
  @wgpu.shaderModule_release(shader)
  let layout_transforms = pipeline.get_bind_group_layout(0U)
  let layout_camera = pipeline.get_bind_group_layout(1U)
  let world = @ecs.World::new()
  let camera = world.create_entity()
  let sun = world.create_entity()
  let earth = world.create_entity()
  let moon = world.create_entity()
  let schedule = @ecs.Schedule::new()
  schedule.add_system(@ecs.transform_propagation_system(world))
  let bodies : Array[@ecs.EntityId] = [sun, earth, moon]
  let gt = world.global_transform_component()
  let id_m = @m44.Matrix44F::identity()
  ignore(world.set_global_transform(sun, id_m))
  ignore(world.set_global_transform(earth, id_m))
  ignore(world.set_global_transform(moon, id_m))
  ignore(world.set_child_of(earth, sun))
  ignore(world.set_child_of(moon, earth))
  push_camera_matrices(world, camera)
  let transform_storage = device.create_global_transform_words_buffer(world)
  let camera_storage = device.create_camera_words_buffer(world)
  let bind_transforms = device.create_global_transform_words_bind_group(
    pipeline, transform_storage, 0U, 0U,
  )
  let bind_camera = device.create_camera_words_bind_group(
    pipeline, camera_storage, 1U, 0U,
  )
  let vusage = @wgpu.GPU_BUFFER_USAGE_VERTEX | @wgpu.GPU_BUFFER_USAGE_COPY_DST
  let vertex_byte_len = (verts_per_cube * vertex_stride_local).to_uint64()
  let vertex_buffer = device.create_buffer(vertex_byte_len, vusage)
  let vertex_bytes = FixedArray::make(
    verts_per_cube * vertex_stride_local,
    (0 : Byte),
  )
  write_vertex_positions_only(vertex_bytes, 0.42)
  queue.write_buffer_from_fixed_array(vertex_buffer, 0UL, vertex_bytes)
  let instance_bytes = FixedArray::make(3 * instance_stride, (0 : Byte))
  for ii = 0; ii < 3; ii = ii + 1 {
    let base = ii * instance_stride
    let mut cr = 0.0
    let mut cg = 0.0
    let mut cb = 0.0
    if ii == 0 {
      cr = 1.0
      cg = 0.65
      cb = 0.15
    } else if ii == 1 {
      cr = 0.2
      cg = 0.55
      cb = 1.0
    } else {
      // Moon: magenta
      cr = 1.0
      cg = 0.0
      cb = 1.0
    }
    @writes.put_f32_le(instance_bytes, base + 8, cr)
    @writes.put_f32_le(instance_bytes, base + 12, cg)
    @writes.put_f32_le(instance_bytes, base + 16, cb)
  }
  world.write_global_transform_refs_into(
    bodies, instance_bytes, instance_stride, 0,
  )
  let instance_buffer = device.create_buffer(
    (3 * instance_stride).to_uint64(),
    vusage,
  )
  queue.write_buffer_from_fixed_array(instance_buffer, 0UL, instance_bytes)
  let iusage = @wgpu.GPU_BUFFER_USAGE_INDEX | @wgpu.GPU_BUFFER_USAGE_COPY_DST
  let index_buffer = device.create_buffer(index_buffer_byte_length, iusage)
  let index_bytes = index_cube_u16_bytes()
  queue.write_buffer_from_fixed_array(index_buffer, 0UL, index_bytes)
  let depth_texture = device.create_texture(
    canvas_width,
    canvas_height,
    "depth24plus",
    @wgpu.GPU_TEXTURE_USAGE_RENDER_ATTACHMENT,
  )
  let depth_view = depth_texture.create_view()
  push_local_transforms(world, bodies, 0.0)
  ignore(schedule.run(world, @ecs.SystemContext::new((0.0 : Float), 0)))
  queue.drain_and_upload_global_transform_writes(transform_storage, world)
  queue.drain_and_upload_camera_writes(camera_storage, world)
  {
    context,
    device,
    queue,
    pipeline,
    depth_texture,
    depth_view,
    vertex_buffer,
    instance_buffer,
    index_buffer,
    transform_storage,
    camera_storage,
    bind_transforms,
    bind_camera,
    layout_transforms,
    layout_camera,
    world,
    schedule,
    camera,
    bodies,
    gt,
    frame: @ref.new(0),
  }
}

///|
/// Implements `push_camera_matrices`.
fn push_camera_matrices(world : @ecs.World, camera : @ecs.EntityId) -> Unit {
  let view = @m44.Matrix44::rotation_x(camera_elevation_rad)
    .mat_mul(@m44.Matrix44::translation(0.0, -2.0, -5.6, 1.0, 0.0))
    .to_float()
  let proj = @m44.Matrix44::ortho(-3.8, 3.8, -3.8, 3.8, 0.1, 50.0).to_float()
  ignore(
    world.set_camera_matrices(
      camera,
      view,
      proj,
      (0.1 : Float),
      (50.0 : Float),
      Float::from_double(canvas_width.to_double() / canvas_height.to_double()),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
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
/// Implements `render_frame`.
pub fn render_frame(renderer : WebGPURenderer) -> Unit {
  let canvas_context = match renderer.context {
    Some(c) => c
    None => abort("render_frame requires a canvas context")
  }
  let texture = canvas_context.get_current_texture()
  let color_view = texture.create_view()
  render_frame_to_view(renderer, color_view)
  @wgpu.textureView_release(color_view)
  canvas_context.present()
}

///|
/// Implements `render_frame_to_view`.
pub fn render_frame_to_view(
  renderer : WebGPURenderer,
  color_view : @wgpu.GPUTextureView,
) -> Unit {
  renderer.frame.val = renderer.frame.val + 1
  let t = renderer.frame.val.to_double() * 0.022
  push_local_transforms(renderer.world, renderer.bodies, t)
  ignore(
    renderer.schedule.run(
      renderer.world,
      @ecs.SystemContext::new((0.022 : Float), renderer.frame.val),
    ),
  )
  renderer.queue.drain_and_upload_global_transform_writes(
    renderer.transform_storage,
    renderer.world,
  )
  push_camera_matrices(renderer.world, renderer.camera)
  renderer.queue.drain_and_upload_camera_writes(
    renderer.camera_storage,
    renderer.world,
  )
  let encoder = renderer.device.create_command_encoder()
  let render_pass = encoder.begin_render_pass({
    color_attachments: [
      Some({
        view: color_view,
        clear_value: Some({ r: 0.03, g: 0.04, b: 0.09, a: 1.0 }),
        load_op: @wgpu.GPULoadOp::Clear,
        store_op: @wgpu.GPUStoreOp::Store,
      }),
    ],
    depth_stencil_attachment: Some({
      view: renderer.depth_view,
      depth_clear_value: Some(1.0),
      depth_load_op: @wgpu.GPULoadOp::Clear,
      depth_store_op: @wgpu.GPUStoreOp::Store,
    }),
  })
  render_pass.set_pipeline(renderer.pipeline)
  render_pass.set_bind_group(0U, renderer.bind_transforms, empty_offsets())
  render_pass.set_bind_group(1U, renderer.bind_camera, empty_offsets())
  render_pass.set_index_buffer(
    renderer.index_buffer,
    @wgpu.GPUIndexFormat::Uint16,
    0UL,
    index_buffer_byte_length,
  )
  render_pass.set_vertex_buffer(
    0,
    renderer.vertex_buffer,
    0UL,
    (verts_per_cube * vertex_stride_local).to_uint64(),
  )
  render_pass.set_vertex_buffer(
    1,
    renderer.instance_buffer,
    0UL,
    (3 * instance_stride).to_uint64(),
  )
  render_pass.draw_indexed(index_u16_count, instance_count=3)
  render_pass.end()
  render_pass.release()
  let command_buffer = encoder.finish()
  renderer.queue.submit(command_buffer)
  encoder.release()
}

///|
/// Implements `WebGPURenderer::release`.
pub fn WebGPURenderer::release(self : WebGPURenderer) -> Unit {
  @wgpu.bindGroup_release(self.bind_transforms)
  @wgpu.bindGroup_release(self.bind_camera)
  @wgpu.bindGroupLayout_release(self.layout_transforms)
  @wgpu.bindGroupLayout_release(self.layout_camera)
  self.index_buffer.release()
  self.instance_buffer.release()
  self.vertex_buffer.release()
  self.transform_storage.release()
  self.camera_storage.release()
  @wgpu.textureView_release(self.depth_view)
  self.depth_texture.release()
  self.pipeline.release()
}

///|
/// Implements `webgpu_renderer_release`.
pub fn webgpu_renderer_release(renderer : WebGPURenderer) -> Unit {
  renderer.release()
}
