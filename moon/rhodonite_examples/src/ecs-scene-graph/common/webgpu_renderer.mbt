///|
/// Canvas resolution (matches demo HTML).
let canvas_width : UInt = 800U

///|
let canvas_height : UInt = 600U

///|
let vertex_stride_local : Int = 12

///|
let instance_stride : Int = 16

///|
let verts_per_cube : Int = 8

///|
let index_u16_count : Int = 36

///|
let index_buffer_byte_length : UInt64 = (index_u16_count * 2).to_uint64()

///|
let camera_elevation_rad : Double = 0.38

///|
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
fn put_mat4_col_major_f64_to_bytes(
  out : FixedArray[Byte],
  m : @m44.Matrix44D,
) -> Unit {
  let d = m.data()
  for i = 0; i < 16; i = i + 1 {
    @writes.put_f32_le(out, i * 4, d[i])
  }
}

///|
fn empty_offsets() -> Array[UInt] {
  []
}

///|
fn max_gt_capacity_from_resize(
  world : @ecs.World,
  gt : @ecs.ComponentTypeId,
) -> Int {
  let mut cap = 0
  let evs = world.drain_resize_events()
  for i = 0; i < evs.length(); i = i + 1 {
    if evs[i].component == gt {
      if evs[i].required_capacity > cap {
        cap = evs[i].required_capacity
      }
    }
  }
  cap
}

///|
pub(all) struct WebGPURenderer {
  context : @wgpu.GPUCanvasContext
  device : @wgpu.GPUDevice
  queue : @wgpu.GPUQueue
  pipeline : @wgpu.GPURenderPipeline
  depth_texture : @wgpu.GPUTexture
  depth_view : @wgpu.GPUTextureView
  vertex_buffer : @wgpu.GPUBuffer
  instance_buffer : @wgpu.GPUBuffer
  index_buffer : @wgpu.GPUBuffer
  transform_storage : @wgpu.GPUBuffer
  camera_uniform : @wgpu.GPUBuffer
  bind_transforms : @wgpu.GPUBindGroup
  bind_camera : @wgpu.GPUBindGroup
  layout_transforms : @wgpu.GPUBindGroupLayout
  layout_camera : @wgpu.GPUBindGroupLayout
  world : @ecs.World
  bodies : Array[@ecs.EntityId]
  gt : @ecs.ComponentTypeId
  frame : @ref.Ref[Int]
}

///|
fn ecs_scene_shader_wgsl() -> String {
  let code =
    #|struct CameraUniform {
    #|  view_proj: mat4x4<f32>,
    #|}
    #|
    #|@group(0) @binding(0) var<storage, read> world_from_entity: array<mat4x4<f32>>;
    #|@group(1) @binding(0) var<uniform> camera: CameraUniform;
    #|
    #|struct VertexOut {
    #|  @builtin(position) position: vec4<f32>,
    #|  @location(0) color: vec3<f32>,
    #|};
    #|
    #|@vertex
    #|fn vertexMain(
    #|  @location(0) local_pos: vec3<f32>,
    #|  @location(1) inst: vec4<f32>,
    #|) -> VertexOut {
    #|  let idx = u32(inst.x);
    #|  let color = vec3<f32>(inst.y, inst.z, inst.w);
    #|  let world_m = world_from_entity[idx];
    #|  let world_pos = world_m * vec4<f32>(local_pos, 1.0);
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
  code
}

///|
pub fn create_renderer(context : @wgpu.GPUContext) -> WebGPURenderer? {
  let (device, canvas_context, format, queue) = context.get()
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
  let vertex_layout_instances : @wgpu.GPUVertexBufferLayout = {
    array_stride: instance_stride.to_uint64(),
    step_mode: @wgpu.GPUVertexStepMode::Instance,
    attributes: [
      {
        format: @wgpu.GPUVertexFormat::Float32x4,
        offset: 0UL,
        shader_location: 1U,
      },
    ],
  }
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
  let stride = @comp.global_transform_gpu_layout().stride
  let mut cap_entities = sun.index + 1
  if earth.index + 1 > cap_entities {
    cap_entities = earth.index + 1
  }
  if moon.index + 1 > cap_entities {
    cap_entities = moon.index + 1
  }
  let ev_cap = max_gt_capacity_from_resize(world, gt)
  if ev_cap > cap_entities {
    cap_entities = ev_cap
  }
  let storage_bytes = (cap_entities * stride).to_uint64()
  let s_usage = @wgpu.GPU_BUFFER_USAGE_STORAGE | @wgpu.GPU_BUFFER_USAGE_COPY_DST
  let transform_storage = device.create_buffer(storage_bytes, s_usage)
  let cam_usage = @wgpu.GPU_BUFFER_USAGE_UNIFORM |
    @wgpu.GPU_BUFFER_USAGE_COPY_DST
  let camera_uniform = device.create_buffer(256UL, cam_usage)
  let bind_transforms = device.create_bind_group({
    layout: layout_transforms,
    entries: [
      {
        binding: 0U,
        resource: @wgpu.GPUBindingResource::Buffer(transform_storage),
      },
    ],
  })
  let bind_camera = device.create_bind_group({
    layout: layout_camera,
    entries: [
      {
        binding: 0U,
        resource: @wgpu.GPUBindingResource::Buffer(camera_uniform),
      },
    ],
  })
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
    let idx_f = bodies[ii].index.to_double()
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
    @writes.put_f32_le(instance_bytes, base + 0, idx_f)
    @writes.put_f32_le(instance_bytes, base + 4, cr)
    @writes.put_f32_le(instance_bytes, base + 8, cg)
    @writes.put_f32_le(instance_bytes, base + 12, cb)
  }
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
  world.update_global_transforms_from_transforms()
  let writes = world.drain_gpu_writes(gt)
  for wi = 0; wi < writes.length(); wi = wi + 1 {
    let w = writes[wi]
    queue.write_buffer_from_fixed_array(
      transform_storage,
      w.byte_offset.to_uint64(),
      w.bytes,
    )
  }
  Some({
    context: canvas_context,
    device,
    queue,
    pipeline,
    depth_texture,
    depth_view,
    vertex_buffer,
    instance_buffer,
    index_buffer,
    transform_storage,
    camera_uniform,
    bind_transforms,
    bind_camera,
    layout_transforms,
    layout_camera,
    world,
    bodies,
    gt,
    frame: @ref.new(0),
  })
}

///|
fn quat_y(angle : Double) -> (Double, Double, Double, Double) {
  let half = angle * 0.5
  let s = @math.sin(half)
  let c = @math.cos(half)
  (0.0, s, 0.0, c)
}

///|
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
pub fn render_frame(renderer : WebGPURenderer) -> Unit {
  renderer.frame.val = renderer.frame.val + 1
  let t = renderer.frame.val.to_double() * 0.022
  let gt = renderer.gt
  push_local_transforms(renderer.world, renderer.bodies, t)
  renderer.world.update_global_transforms_from_transforms()
  let writes = renderer.world.drain_gpu_writes(gt)
  for wi = 0; wi < writes.length(); wi = wi + 1 {
    let w = writes[wi]
    renderer.queue.write_buffer_from_fixed_array(
      renderer.transform_storage,
      w.byte_offset.to_uint64(),
      w.bytes,
    )
  }
  let v_cos = @math.cos(camera_elevation_rad)
  let v_sin = @math.sin(camera_elevation_rad)
  let view = @m44.Matrix44::rotation_x_cos_sin(v_cos, v_sin, 1.0, 0.0).mat_mul(
    @m44.Matrix44::translation(0.0, 0.0, -5.6, 1.0, 0.0),
  )
  let proj = @m44.Matrix44::ortho(-3.8, 3.8, -3.8, 3.8, 0.1, 50.0)
  let vp = proj.mat_mul(view)
  let cam_bytes = FixedArray::make(256, (0 : Byte))
  put_mat4_col_major_f64_to_bytes(cam_bytes, vp)
  renderer.queue.write_buffer_from_fixed_array(
    renderer.camera_uniform,
    0UL,
    cam_bytes,
  )
  let texture = renderer.context.get_current_texture()
  let color_view = texture.create_view()
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
  @wgpu.textureView_release(color_view)
  renderer.context.present()
}

///|
pub fn WebGPURenderer::release(self : WebGPURenderer) -> Unit {
  @wgpu.bindGroup_release(self.bind_transforms)
  @wgpu.bindGroup_release(self.bind_camera)
  @wgpu.bindGroupLayout_release(self.layout_transforms)
  @wgpu.bindGroupLayout_release(self.layout_camera)
  self.index_buffer.release()
  self.instance_buffer.release()
  self.vertex_buffer.release()
  self.transform_storage.release()
  self.camera_uniform.release()
  @wgpu.textureView_release(self.depth_view)
  self.depth_texture.release()
  self.pipeline.release()
}

///|
pub fn webgpu_renderer_release(renderer : WebGPURenderer) -> Unit {
  renderer.release()
}
