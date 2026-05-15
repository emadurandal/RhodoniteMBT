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
let entity_count : Int = 800_000

///|
enum GlobalTransformPrecisionMode {
  AllF32
  AllF16
  FirstHalfF32SecondHalfF16
  EvenIdF32OddIdF16
} derive(Eq)

///|
let global_transform_precision_mode : GlobalTransformPrecisionMode = AllF16

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
let camera_elevation_rad : Double = 0.42

///|
let grid_spacing : Double = 0.14

///|
let cube_scale : Float = 0.055

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
/// View-space **z** extrema of the grid AABB corners after `view_rot` (before extra Z pull).
fn view_space_z_range_corners(
  view_rot : @m44.Matrix44D,
  extent_xz : Double,
  wave_y : Double,
) -> (Double, Double) {
  let sx_arr = [-1.0, 1.0]
  let sz_arr = [-1.0, 1.0]
  let wy_arr = [-1.0, 1.0]
  let mut i = 0
  let mut z_min = (0.0 : Double)
  let mut z_max = (0.0 : Double)
  for sx = 0; sx < 2; sx = sx + 1 {
    for sy = 0; sy < 2; sy = sy + 1 {
      for sz = 0; sz < 2; sz = sz + 1 {
        let wx = sx_arr[sx] * extent_xz
        let wy = wy_arr[sy] * wave_y
        let wz = sz_arr[sz] * extent_xz
        let v = view_rot.mul_vec4(@v4.Vector4::new(wx, wy, wz, (1.0 : Double)))
        let z = v.z()
        if i == 0 {
          z_min = z
          z_max = z
        } else {
          if z < z_min {
            z_min = z
          }
          if z > z_max {
            z_max = z
          }
        }
        i = i + 1
      }
    }
  }
  (z_min, z_max)
}

///|
/// View-space **y** extrema of the same world AABB corners (for ortho `bottom`/`top`).
fn view_space_y_range_corners(
  view_rot : @m44.Matrix44D,
  extent_xz : Double,
  wave_y : Double,
) -> (Double, Double) {
  let sx_arr = [-1.0, 1.0]
  let sz_arr = [-1.0, 1.0]
  let wy_arr = [-1.0, 1.0]
  let mut i = 0
  let mut y_min = (0.0 : Double)
  let mut y_max = (0.0 : Double)
  for sx = 0; sx < 2; sx = sx + 1 {
    for sy = 0; sy < 2; sy = sy + 1 {
      for sz = 0; sz < 2; sz = sz + 1 {
        let wx = sx_arr[sx] * extent_xz
        let wy = wy_arr[sy] * wave_y
        let wz = sz_arr[sz] * extent_xz
        let v = view_rot.mul_vec4(@v4.Vector4::new(wx, wy, wz, (1.0 : Double)))
        let y = v.y()
        if i == 0 {
          y_min = y
          y_max = y
        } else {
          if y < y_min {
            y_min = y
          }
          if y > y_max {
            y_max = y
          }
        }
        i = i + 1
      }
    }
  }
  (y_min, y_max)
}

///|
/// Ortho frustum that fits the tilted XZ grid in view space and matches canvas aspect.
///
/// WebGPU clips to `0 ≤ clip.z ≤ clip.w`. [`Matrix44::ortho`] maps view **z** in
/// `[-far, -near]` to NDC depth `[0, 1]`. This grid can reach **positive** view **z**,
/// so we pull along **−Z** and extend **far** so the whole slab stays inside the clip volume.
fn camera_uniform_bytes() -> FixedArray[Byte] {
  let view_rot = @m44.Matrix44::rotation_x(camera_elevation_rad).mat_mul(
    @m44.Matrix44::translation(0.0, 0.0, -16.0, 1.0, 0.0),
  )
  let per_side = grid_side_len(entity_count)
  let half = (per_side - 1).to_double() * 0.5
  let extent_xz = half * grid_spacing
  let wave = 0.12
  let margin = cube_scale.to_double() * 2.5
  /// World **y** bound: wave motion + scaled unit cube local **y** (±1 in mesh space).
  let wave_y = wave + cube_scale.to_double() * 1.1
  let (y_lo, y_hi) = view_space_y_range_corners(view_rot, extent_xz, wave_y)
  let cy = (y_lo + y_hi) * 0.5
  let hy = (y_hi - y_lo) * 0.5 + margin
  let hx = extent_xz + margin
  let aspect = canvas_width.to_double() / canvas_height.to_double()
  let mut half_w = hx
  let mut half_h = hy
  if half_w / half_h < aspect {
    half_w = half_h * aspect
  } else {
    half_h = half_w / aspect
  }
  let left = -half_w
  let right = half_w
  let bottom = cy - half_h
  let top = cy + half_h
  let (z_lo, z_hi) = view_space_z_range_corners(view_rot, extent_xz, wave_y)
  let pull_z = if z_hi > -0.15 { -z_hi - 1.0 } else { 0.0 }
  let view = @m44.Matrix44::translation(0.0, 0.0, pull_z, 1.0, 0.0).mat_mul(
    view_rot,
  )
  let z_min_pulled = z_lo + pull_z
  let far_need = -z_min_pulled + 8.0
  let far_clip = if far_need > 80.0 { far_need } else { 80.0 }
  let proj = @m44.Matrix44::ortho(left, right, bottom, top, 0.1, far_clip)
  let vp = proj.mat_mul(view)
  let bytes = FixedArray::make(256, (0 : Byte))
  put_mat4_col_major_f64_to_bytes(bytes, vp)
  bytes
}

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
fn global_transform_default_format() -> @comp.GlobalTransformGpuFormat {
  match global_transform_precision_mode {
    AllF32 => Affine3x4F32
    _ => Affine3x4F16
  }
}

///|
fn entity_uses_f32(entity : @ecs.EntityId, local_index : Int) -> Bool {
  match global_transform_precision_mode {
    AllF32 => true
    AllF16 => false
    FirstHalfF32SecondHalfF16 => local_index < entity_count / 2
    EvenIdF32OddIdF16 => entity.index % 2 == 0
  }
}

///|
fn apply_global_transform_precision_mode(
  world : @ecs.World,
  entities : Array[@ecs.EntityId],
) -> Unit {
  match global_transform_precision_mode {
    AllF32 | AllF16 => ()
    _ =>
      for i = 0; i < entities.length(); i = i + 1 {
        let e = entities[i]
        if entity_uses_f32(e, i) {
          ignore(world.set_global_transform_format(e, Affine3x4F32))
        }
      }
  }
}

///|
fn write_mass_cubes_transform_blob(
  writer : @ecs.GlobalTransformBlobWriter,
  per_side : Int,
  t : Double,
  full_rows : Bool,
) -> Unit {
  let wave_time = t * 1.8
  let sin_step = @math.sin(0.09)
  let cos_step = @math.cos(0.09)
  if !full_rows {
    let set_y = writer.element_setter(1, 3)
    let mut i = 0
    let mut wave_sin = @math.sin(wave_time)
    let mut wave_cos = @math.cos(wave_time)
    while i < entity_count {
      set_y(i, Float::from_double(wave_sin * 0.12))
      let next_sin = wave_sin * cos_step + wave_cos * sin_step
      wave_cos = wave_cos * cos_step - wave_sin * sin_step
      wave_sin = next_sin
      i = i + 1
    }
    return
  }
  let half = (per_side - 1).to_double() * 0.5
  let step = Float::from_double(grid_spacing)
  let mut local_index = 0
  let mut row = 0
  while local_index < entity_count {
    let remaining = entity_count - local_index
    let row_count = if per_side < remaining { per_side } else { remaining }
    let mut x = Float::from_double((0.0 - half) * grid_spacing)
    let z = Float::from_double((row.to_double() - half) * grid_spacing)
    let phase = local_index.to_double() * 0.09 + wave_time
    let mut wave_sin = @math.sin(phase)
    let mut wave_cos = @math.cos(phase)
    for _ix = 0; _ix < row_count; _ix = _ix + 1 {
      let y = Float::from_double(wave_sin * 0.12)
      writer.set_affine3x4_at(
        local_index,
        cube_scale,
        (0.0 : Float),
        (0.0 : Float),
        x,
        (0.0 : Float),
        cube_scale,
        (0.0 : Float),
        y,
        (0.0 : Float),
        (0.0 : Float),
        cube_scale,
        z,
      )
      let next_sin = wave_sin * cos_step + wave_cos * sin_step
      wave_cos = wave_cos * cos_step - wave_sin * sin_step
      wave_sin = next_sin
      local_index = local_index + 1
      x = x + step
    }
    row = row + 1
  }
}

///|
fn update_and_drain_global_transforms(
  world : @ecs.World,
  tf : @ecs.ComponentTypeId,
  gt : @ecs.ComponentTypeId,
  per_side : Int,
  t : Double,
  transform_refs : FixedArray[Byte],
  upload_range : @ecs.GlobalTransformUploadRange,
  dense_transform_layout : @ecs.GlobalTransformDenseLayout?,
  full_rows : Bool,
) -> Array[@ecs.GpuWriteView] {
  ignore(tf)
  ignore(gt)
  world.write_global_transform_blob_range_by_refs(
    transform_refs,
    entity_count,
    upload_range,
    dense_transform_layout,
    fn(writer) {
      write_mass_cubes_transform_blob(writer, per_side, t, full_rows)
    },
  )
}

///|
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
  camera_uniform : @wgpu.GPUBuffer
  bind_transforms : @wgpu.GPUBindGroup
  bind_camera : @wgpu.GPUBindGroup
  layout_transforms : @wgpu.GPUBindGroupLayout
  layout_camera : @wgpu.GPUBindGroupLayout
  world : @ecs.World
  gt : @ecs.ComponentTypeId
  tf : @ecs.ComponentTypeId
  per_side : Int
  transform_refs : FixedArray[Byte]
  transform_upload_range : @ecs.GlobalTransformUploadRange
  dense_transform_layout : @ecs.GlobalTransformDenseLayout?
  bind_group_offsets : Array[UInt]
  frame : @ref.Ref[Int]
  perf_last_frame_start_ms : @ref.Ref[Double]
}

///|
fn ecs_mass_shader_wgsl() -> String {
  let prefix_camera =
    #|struct CameraUniform {
    #|  view_proj: mat4x4<f32>,
    #|}
    #|
  let camera_binding =
    #|
    #|@group(1) @binding(0) var<uniform> camera: CameraUniform;
    #|
  let prefix_bindings = @ecs_wgsl.global_transform_words_binding_default() +
    camera_binding
  let prefix = prefix_camera + prefix_bindings
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
  let code = prefix + @ecs_wgsl.global_transform_helpers_default() + suffix
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
pub fn create_renderer_for_device(
  device : @wgpu.GPUDevice,
  queue : @wgpu.GPUQueue,
  format : String,
  context? : @wgpu.GPUCanvasContext? = None,
) -> WebGPURenderer {
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
  let world = @ecs.World::new_with_global_transform_format(
    global_transform_default_format(),
  )
  let gt = world.global_transform_component()
  let tf = world.transform_component()
  let per_side = grid_side_len(entity_count)
  let inst_bytes_len = entity_count * instance_stride
  let instance_bytes = FixedArray::make(inst_bytes_len, (0 : Byte))
  let entities = world.spawn_transform_global_batch(entity_count, fn(
    i,
    e,
    tf_row,
    _gt_row,
  ) {
    let (gx, gz) = grid_xz_for_index(i, per_side)
    @comp.Transform3D::write_trs_to_component_mut_view(
      tf_row,
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
    )
    let base = i * instance_stride
    let (cr, cg, cb) = instance_color_rgb(e.index)
    @writes.put_f32_le(instance_bytes, base + 8, cr)
    @writes.put_f32_le(instance_bytes, base + 12, cg)
    @writes.put_f32_le(instance_bytes, base + 16, cb)
  })
  apply_global_transform_precision_mode(world, entities)
  world.write_global_transform_refs_into(
    entities, instance_bytes, instance_stride, 0,
  )
  let transform_refs = world.extract_global_transform_refs(entities)
  let dense_transform_layout = @ecs.detect_dense_global_transform_layout(
    transform_refs, entity_count,
  )
  let transform_upload_range = @ecs.compute_global_transform_upload_range(
    transform_refs, entity_count, dense_transform_layout,
  )
  let transform_storage = device.create_global_transform_words_buffer(world)
  let cam_usage = @wgpu.GPU_BUFFER_USAGE_UNIFORM |
    @wgpu.GPU_BUFFER_USAGE_COPY_DST
  let camera_uniform = device.create_buffer(256UL, cam_usage)
  queue.write_buffer_from_fixed_array(
    camera_uniform,
    0UL,
    camera_uniform_bytes(),
  )
  let bind_transforms = device.create_global_transform_words_bind_group(
    pipeline, transform_storage, 0U, 0U,
  )
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
  let writes0 = update_and_drain_global_transforms(
    world, tf, gt, per_side, 0.0, transform_refs, transform_upload_range, dense_transform_layout,
    true,
  )
  queue.upload_global_transform_writes(transform_storage, writes0)
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
    camera_uniform,
    bind_transforms,
    bind_camera,
    layout_transforms,
    layout_camera,
    world,
    gt,
    tf,
    per_side,
    transform_refs,
    transform_upload_range,
    dense_transform_layout,
    bind_group_offsets: [],
    frame: @ref.new(0),
    perf_last_frame_start_ms: @ref.new(-1.0),
  }
}

///|
pub fn render_frame(renderer : WebGPURenderer) -> Unit {
  let canvas_context = match renderer.context {
    Some(c) => c
    None => abort("render_frame requires a canvas context")
  }
  let texture = canvas_context.get_current_texture()
  let color_view = texture.create_view()
  render_frame_to_view(renderer, color_view, record_perf=true)
  @wgpu.textureView_release(color_view)
  canvas_context.present()
}

///|
pub fn render_frame_to_view(
  renderer : WebGPURenderer,
  color_view : @wgpu.GPUTextureView,
  record_perf? : Bool = false,
) -> Unit {
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
  let writes = update_and_drain_global_transforms(
    renderer.world,
    tf,
    gt,
    renderer.per_side,
    t,
    renderer.transform_refs,
    renderer.transform_upload_range,
    renderer.dense_transform_layout,
    false,
  )
  renderer.queue.upload_global_transform_writes(
    renderer.transform_storage,
    writes,
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
  render_pass.set_bind_group(
    0U,
    renderer.bind_transforms,
    renderer.bind_group_offsets,
  )
  render_pass.set_bind_group(
    1U,
    renderer.bind_camera,
    renderer.bind_group_offsets,
  )
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
  if record_perf {
    let cpu_ms = monotonic_ms() - t_frame_start
    ecs_mass_cubes_perf_overlay(fps, cpu_ms)
    ecs_mass_cubes_perf_console_log(fps, cpu_ms, renderer.frame.val)
  }
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
