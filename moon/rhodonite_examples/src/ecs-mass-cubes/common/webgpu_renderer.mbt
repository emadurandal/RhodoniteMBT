///|
#cfg(target="js")
extern "js" fn monotonic_ms() -> Double =
  #| () => performance.now()

///|
#cfg(target="native")
extern "C" fn sdl_get_ticks() -> UInt64 = "SDL_GetTicks"

///|
#cfg(target="native")
fn monotonic_ms() -> Double {
  sdl_get_ticks().to_double()
}

///|
#cfg(not(any(target="js", target="native")))
fn monotonic_ms() -> Double {
  0.0
}

///|
/// Number of root entities (grid layout). Increase to stress CPU/GPU; keep within device limits.
let entity_count : Int = 200000

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
let camera_elevation_rad : Double = 0.42

///|
let grid_spacing : Double = 0.14

///|
let cube_scale : Float = 0.055

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
/// Smallest `s` with `s * s >= n` for a roughly square XZ grid.
fn grid_side_len(n : Int) -> Int {
  let mut s = 1
  while s * s < n {
    s = s + 1
  }
  s
}

///|
fn instance_color_rgb(idx : Int) -> (Double, Double, Double) {
  let i = idx % 125
  let r = (i % 5).to_double() * 0.22 + 0.12
  let g = (i / 5 % 5).to_double() * 0.22 + 0.08
  let b = (i / 25 % 5).to_double() * 0.22 + 0.1
  (r, g, b)
}

///|
fn grid_xz_for_index(idx : Int, per_side : Int) -> (Float, Float) {
  let ix = idx % per_side
  let iz = idx / per_side
  let half = (per_side - 1).to_double() * 0.5
  let fx = ix.to_double() - half
  let fz = iz.to_double() - half
  (Float::from_double(fx * grid_spacing), Float::from_double(fz * grid_spacing))
}

///|
#cfg(target="js")
extern "js" fn animate_transforms_query_fast_js(
  world : @ecs.World,
  tf_id : @ecs.ComponentTypeId,
  per_side : Int,
  t : Double,
) -> Bool =
  #| (world, tfId, perSide, t) => {
  #|   const tfIndex = tfId.index;
  #|   const half = (perSide - 1) * 0.5;
  #|   const spacing = 0.14;
  #|   const time = t * 1.8;
  #|   const archetypes = world.archetypes;
  #|   for (let ai = 0; ai < archetypes.length; ai++) {
  #|     const arch = archetypes[ai];
  #|     let tfColumn = null;
  #|     for (let ci = 0; ci < arch.columns.length; ci++) {
  #|       const col = arch.columns[ci];
  #|       if (col.component.index === tfIndex) {
  #|         tfColumn = col;
  #|         break;
  #|       }
  #|     }
  #|     if (!tfColumn) continue;
  #|     if (tfColumn.stride < 40) return false;
  #|     if (!ArrayBuffer.isView(tfColumn.bytes)) {
  #|       const converted = new Uint8Array(tfColumn.bytes.length);
  #|       converted.set(tfColumn.bytes);
  #|       tfColumn.bytes = converted;
  #|     }
  #|     const bytes = tfColumn.bytes;
  #|     const stride = tfColumn.stride;
  #|     if ((bytes.byteOffset & 3) !== 0 || (bytes.byteLength & 3) !== 0 || (stride & 3) !== 0) return false;
  #|     const values = new Float32Array(bytes.buffer, bytes.byteOffset, bytes.byteLength >> 2);
  #|     const strideF32 = stride >> 2;
  #|     const entities = arch.entities;
  #|     for (let row = 0; row < entities.length; row++) {
  #|       const idx = entities[row].index;
  #|       const ix = idx % perSide;
  #|       const iz = Math.trunc(idx / perSide);
  #|       const gx = (ix - half) * spacing;
  #|       const gz = (iz - half) * spacing;
  #|       const wy = Math.sin(idx * 0.09 + time) * 0.12;
  #|       const base = row * strideF32;
  #|       values[base] = Math.fround(gx);
  #|       values[base + 1] = Math.fround(wy);
  #|       values[base + 2] = Math.fround(gz);
  #|     }
  #|   }
  #|   return true;
  #| }

///|
#cfg(target="js")
fn animate_transforms_query_fast(
  world : @ecs.World,
  tf_id : @ecs.ComponentTypeId,
  per_side : Int,
  t : Double,
) -> Bool {
  animate_transforms_query_fast_js(world, tf_id, per_side, t)
}

///|
#cfg(not(target="js"))
fn animate_transforms_query_fast(
  world : @ecs.World,
  tf_id : @ecs.ComponentTypeId,
  per_side : Int,
  t : Double,
) -> Bool {
  ignore(tf_id)
  world.update_transform3d_positions(fn(e) {
    let idx = e.index
    let (gx, gz) = grid_xz_for_index(idx, per_side)
    let phase = idx.to_double() * 0.09 + t * 1.8
    let wy = @math.sin(phase) * 0.12
    (gx, Float::from_double(wy), gz)
  })
  true
}

///|
fn animate_transforms_query(
  world : @ecs.World,
  tf_id : @ecs.ComponentTypeId,
  per_side : Int,
  t : Double,
) -> Unit {
  // if animate_transforms_query_fast(world, tf_id, per_side, t) {
  //   return
  // }
  let q = @ecs.Query::new([tf_id])
  q.for_each(world, row => {
    let idx = row.entity().index
    let (gx, gz) = grid_xz_for_index(idx, per_side)
    let phase = idx.to_double() * 0.09 + t * 1.8
    let wy = @math.sin(phase) * 0.12
    @comp.Transform3D::write_position_to_component_mut_view(
      row.write_view(tf_id),
      gx,
      Float::from_double(wy),
      gz,
    )
  })
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
  gt : @ecs.ComponentTypeId
  tf : @ecs.ComponentTypeId
  per_side : Int
  frame : @ref.Ref[Int]
  perf_last_frame_start_ms : @ref.Ref[Double]
}

///|
fn ecs_mass_shader_wgsl() -> String {
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
#cfg(target="js")
extern "js" fn ecs_mass_cubes_perf_overlay_js(
  fps : Double,
  cpu_ms : Double,
) -> Unit =
  #| (fps, cpuMs) => {
  #|   const el = document.getElementById("ecs-mass-cubes-perf");
  #|   if (!el) return;
  #|   el.textContent =
  #|     "FPS " +
  #|     fps.toFixed(1) +
  #|     "  ·  CPU " +
  #|     cpuMs.toFixed(2) +
  #|     " ms / frame (submit まで)";
  #| }

///|
#cfg(target="js")
fn ecs_mass_cubes_perf_overlay(fps : Double, cpu_ms : Double) -> Unit {
  ecs_mass_cubes_perf_overlay_js(fps, cpu_ms)
}

///|
#cfg(not(target="js"))
fn ecs_mass_cubes_perf_overlay(_fps : Double, _cpu_ms : Double) -> Unit {
  ignore(_fps)
  ignore(_cpu_ms)
  ()
}

///|
#cfg(target="native")
fn ecs_mass_cubes_perf_console_log(
  fps : Double,
  cpu_ms : Double,
  frame_idx : Int,
) -> Unit {
  if frame_idx < 2 || frame_idx % 30 != 0 {
    return
  }
  println(
    "ecs-mass-cubes: FPS=" +
    fps.to_string() +
    "  CPU=" +
    cpu_ms.to_string() +
    " ms/frame (until submit)",
  )
}

///|
#cfg(not(target="native"))
fn ecs_mass_cubes_perf_console_log(
  _fps : Double,
  _cpu_ms : Double,
  _frame_idx : Int,
) -> Unit {
  ignore(_fps)
  ignore(_cpu_ms)
  ignore(_frame_idx)
  ()
}

///|
pub fn create_renderer(context : @wgpu.GPUContext) -> WebGPURenderer? {
  let (device, canvas_context, format, queue) = context.get()
  let shader = device.create_shader_module(ecs_mass_shader_wgsl())
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
  let gt = world.global_transform_component()
  let tf = world.transform_component()
  let per_side = grid_side_len(entity_count)
  let id_m = @m44.Matrix44F::identity()
  let inst_bytes_len = entity_count * instance_stride
  let instance_bytes = FixedArray::make(inst_bytes_len, (0 : Byte))
  let mut max_index_slot = 0
  for i = 0; i < entity_count; i = i + 1 {
    let e = world.create_entity()
    let idx = e.index
    if idx + 1 > max_index_slot {
      max_index_slot = idx + 1
    }
    let (gx, gz) = grid_xz_for_index(i, per_side)
    ignore(
      world.set_transform_trs(
        e,
        gx,
        (0.0 : Float),
        gz,
        0.0,
        0.0,
        0.0,
        1.0,
        cube_scale,
        cube_scale,
        cube_scale,
      ),
    )
    ignore(world.set_global_transform(e, id_m))
    let base = i * instance_stride
    let idx_f = idx.to_double()
    let (cr, cg, cb) = instance_color_rgb(idx)
    @writes.put_f32_le(instance_bytes, base + 0, idx_f)
    @writes.put_f32_le(instance_bytes, base + 4, cr)
    @writes.put_f32_le(instance_bytes, base + 8, cg)
    @writes.put_f32_le(instance_bytes, base + 12, cb)
  }
  let stride = @comp.global_transform_gpu_layout().stride
  let mut cap_entities = max_index_slot
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
  let instance_buffer = device.create_buffer(inst_bytes_len.to_uint64(), vusage)
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
  animate_transforms_query(world, tf, per_side, 0.0)
  world.update_global_transforms_from_transforms()
  let writes0 = world.drain_gpu_writes(gt)
  for wi = 0; wi < writes0.length(); wi = wi + 1 {
    let w = writes0[wi]
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
    gt,
    tf,
    per_side,
    frame: @ref.new(0),
    perf_last_frame_start_ms: @ref.new(-1.0),
  })
}

///|
pub fn render_frame(renderer : WebGPURenderer) -> Unit {
  let t_frame_start = monotonic_ms()
  let last_start = renderer.perf_last_frame_start_ms.val
  let fps = if last_start >= 0.0 {
    let wall_dt = t_frame_start - last_start
    if wall_dt > 1.0e-9 {
      1000.0 / wall_dt
    } else {
      0.0
    }
  } else {
    0.0
  }
  renderer.perf_last_frame_start_ms.val = t_frame_start
  renderer.frame.val = renderer.frame.val + 1
  let t = renderer.frame.val.to_double() * 0.018
  let gt = renderer.gt
  let tf = renderer.tf
  animate_transforms_query(renderer.world, tf, renderer.per_side, t)
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
  let view = @m44.Matrix44::rotation_x(camera_elevation_rad).mat_mul(
    @m44.Matrix44::translation(0.0, 0.0, -16.0, 1.0, 0.0),
  )
  let proj = @m44.Matrix44::ortho(-10.0, 10.0, -10.0, 10.0, 0.1, 80.0)
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
    (entity_count * instance_stride).to_uint64(),
  )
  render_pass.draw_indexed(index_u16_count, instance_count=entity_count)
  render_pass.end()
  render_pass.release()
  let command_buffer = encoder.finish()
  renderer.queue.submit(command_buffer)
  encoder.release()
  let cpu_ms = monotonic_ms() - t_frame_start
  ecs_mass_cubes_perf_overlay(fps, cpu_ms)
  ecs_mass_cubes_perf_console_log(fps, cpu_ms, renderer.frame.val)
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
