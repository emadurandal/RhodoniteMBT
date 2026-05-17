///|
#cfg(target="js")
extern "js" fn monotonic_ms() -> Double =
  #| () => performance.now()

///|
#cfg(target="native")
extern "C" fn sdl_get_ticks() -> UInt64 = "SDL_GetTicks"

///|

///|
/// Implements `monotonic_ms`.
#cfg(target="native")
fn monotonic_ms() -> Double {
  sdl_get_ticks().to_double()
}

///|

///|
/// Implements `monotonic_ms`.
#cfg(not(any(target="js", target="native")))
fn monotonic_ms() -> Double {
  0.0
}

///|
/// Number of root entities (grid layout). Increase to stress CPU/GPU; keep within device limits.
let entity_count : Int = @mass_shared.entity_count()

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
let canvas_width : UInt = @mass_shared.canvas_width()

///|
let canvas_height : UInt = @mass_shared.canvas_height()

///|
let vertex_stride_local : Int = @mass_shared.vertex_stride_local()

///|
let instance_stride : Int = @mass_shared.instance_stride()

///|
let verts_per_cube : Int = @mass_shared.verts_per_cube()

///|
let index_u16_count : Int = @mass_shared.index_u16_count()

///|
let index_buffer_byte_length : UInt64 = (index_u16_count * 2).to_uint64()

///|
let camera_elevation_rad : Double = @mass_shared.camera_elevation_rad()

///|
let grid_spacing : Double = @mass_shared.grid_spacing()

///|
let cube_scale : Float = @mass_shared.cube_scale()

///|
/// Smallest `s` with `s * s >= n` for a roughly square XZ grid.
fn grid_side_len(n : Int) -> Int {
  @mass_shared.grid_side_len(n)
}

///|
/// Ortho frustum that fits the tilted XZ grid in view space and matches canvas aspect.
///
/// WebGPU clips to `0 ≤ clip.z ≤ clip.w`. [`Matrix44::ortho`] maps view **z** in
/// `[-far, -near]` to NDC depth `[0, 1]`. This grid can reach **positive** view **z**,
/// so we pull along **−Z** and extend **far** so the whole slab stays inside the clip volume.
fn camera_matrices(
  yaw : Double,
  pitch : Double,
  pan_x : Double,
  pan_y : Double,
  dolly : Double,
) -> (@m44.Matrix44F, @m44.Matrix44F, Float, Float, Float) {
  @mass_shared.camera_matrices(entity_count, yaw, pitch, pan_x, pan_y, dolly)
}

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
/// Implements `instance_color_rgb`.
fn instance_color_rgb(idx : Int) -> (Double, Double, Double) {
  let i = idx % 125
  let r = (i % 5).to_double() * 0.22 + 0.12
  let g = (i / 5 % 5).to_double() * 0.22 + 0.08
  let b = (i / 25 % 5).to_double() * 0.22 + 0.1
  (r, g, b)
}

///|
/// Implements `grid_xz_for_index`.
fn grid_xz_for_index(idx : Int, per_side : Int) -> (Float, Float) {
  @mass_shared.grid_xz_for_index(idx, per_side)
}

///|
/// Converts a GlobalTransform GPU format to the compact numeric code used by dense writers.
fn global_transform_format_code_int(
  format : @comp.GlobalTransformGpuFormat,
) -> Int {
  @comp.global_transform_format_code(format).reinterpret_as_int()
}

///|
/// Writes the animated Y translation for a dense GlobalTransform blob in JavaScript.
#cfg(target="js")
extern "js" fn write_mass_cubes_dense_y_transform_wave(
  bytes : MutArrayView[Byte],
  count : Int,
  first_word : Int,
  words_per_entity : Int,
  format_code : Int,
  wave_time : Double,
) -> Unit =
  #| (
  #|   bytes,
  #|   count,
  #|   firstWord,
  #|   wordsPerEntity,
  #|   formatCode,
  #|   waveTime,
  #| ) => {
  #|   const src = bytes.buf;
  #|   const start = bytes.start;
  #|   const byteLength = bytes.end - bytes.start;
  #|   if (!ArrayBuffer.isView(src)) {
  #|     throw new Error("MassCubes dense transform writer requires typed byte storage.");
  #|   }
  #|   const floats = new Float32Array(src.buffer, src.byteOffset + start, byteLength >> 2);
  #|   const sinStep = Math.sin(0.09);
  #|   const cosStep = Math.cos(0.09);
  #|   let waveSin = Math.sin(waveTime);
  #|   let waveCos = Math.cos(waveTime);
  #|   if (formatCode === 1) {
  #|     const halfIndexBase = (3 - firstWord) * 2 + 1;
  #|     const Float16ArrayCtor = globalThis.Float16Array;
  #|     if (typeof Float16ArrayCtor === "function") {
  #|       const halfFloats = new Float16ArrayCtor(src.buffer, src.byteOffset + start, byteLength >> 1);
  #|       for (let i = 0; i < count; i++) {
  #|         halfFloats[i * wordsPerEntity * 2 + halfIndexBase] = waveSin * 0.12;
  #|         const nextSin = waveSin * cosStep + waveCos * sinStep;
  #|         waveCos = waveCos * cosStep - waveSin * sinStep;
  #|         waveSin = nextSin;
  #|       }
  #|       return;
  #|     }
  #|     let cache = globalThis.__rhodonite_mass_cubes_f32_to_f16_table;
  #|     if (!cache) {
  #|       const base = new Uint16Array(512);
  #|       const shift = new Uint8Array(512);
  #|       for (let i = 0; i < 256; i++) {
  #|         const e = i - 127;
  #|         if (e < -24) {
  #|           base[i] = 0x0000;
  #|           base[i | 0x100] = 0x8000;
  #|           shift[i] = 24;
  #|           shift[i | 0x100] = 24;
  #|         } else if (e < -14) {
  #|           const b = 0x0400 >> (-e - 14);
  #|           const s = -e - 1;
  #|           base[i] = b;
  #|           base[i | 0x100] = b | 0x8000;
  #|           shift[i] = s;
  #|           shift[i | 0x100] = s;
  #|         } else if (e <= 15) {
  #|           const b = (e + 15) << 10;
  #|           base[i] = b;
  #|           base[i | 0x100] = b | 0x8000;
  #|           shift[i] = 13;
  #|           shift[i | 0x100] = 13;
  #|         } else if (e < 128) {
  #|           base[i] = 0x7c00;
  #|           base[i | 0x100] = 0xfc00;
  #|           shift[i] = 24;
  #|           shift[i | 0x100] = 24;
  #|         } else {
  #|           base[i] = 0x7c00;
  #|           base[i | 0x100] = 0xfc00;
  #|           shift[i] = 13;
  #|           shift[i | 0x100] = 13;
  #|         }
  #|       }
  #|       const scratchF32 = new Float32Array(1);
  #|       const scratchU32 = new Uint32Array(scratchF32.buffer);
  #|       cache = globalThis.__rhodonite_mass_cubes_f32_to_f16_table = {
  #|         base,
  #|         shift,
  #|         scratchF32,
  #|         scratchU32,
  #|       };
  #|     }
  #|     const halfBits = new Uint16Array(src.buffer, src.byteOffset + start, byteLength >> 1);
  #|     for (let i = 0; i < count; i++) {
  #|       cache.scratchF32[0] = Math.fround(waveSin * 0.12);
  #|       const bits = cache.scratchU32[0] >>> 0;
  #|       const index = (bits >>> 23) & 0x1ff;
  #|       halfBits[i * wordsPerEntity * 2 + halfIndexBase] =
  #|         cache.base[index] + ((bits & 0x007fffff) >>> cache.shift[index]);
  #|       const nextSin = waveSin * cosStep + waveCos * sinStep;
  #|       waveCos = waveCos * cosStep - waveSin * sinStep;
  #|       waveSin = nextSin;
  #|     }
  #|     return;
  #|   }
  #|   const baseWord = 7 - firstWord;
  #|   for (let i = 0; i < count; i++) {
  #|     floats[i * wordsPerEntity + baseWord] = Math.fround(waveSin * 0.12);
  #|     const nextSin = waveSin * cosStep + waveCos * sinStep;
  #|     waveCos = waveCos * cosStep - waveSin * sinStep;
  #|     waveSin = nextSin;
  #|   }
  #| }

///|
/// Writes the animated Y translation for a dense GlobalTransform blob.
#cfg(not(target="js"))
fn write_mass_cubes_dense_y_transform_wave(
  bytes : MutArrayView[Byte],
  count : Int,
  first_word : Int,
  words_per_entity : Int,
  format_code : Int,
  wave_time : Double,
) -> Unit {
  let sin_step = @math.sin(0.09)
  let cos_step = @math.cos(0.09)
  let mut i = 0
  let mut wave_sin = @math.sin(wave_time)
  let mut wave_cos = @math.cos(wave_time)
  let stride_bytes = words_per_entity * 4
  if format_code == 1 {
    let mut byte_offset = (3 - first_word) * 4 + 2
    while i < count {
      @comp.global_transform_put_f16_le_mut_view(
        bytes,
        byte_offset,
        Float::from_double(wave_sin * 0.12),
      )
      let next_sin = wave_sin * cos_step + wave_cos * sin_step
      wave_cos = wave_cos * cos_step - wave_sin * sin_step
      wave_sin = next_sin
      i = i + 1
      byte_offset = byte_offset + stride_bytes
    }
    return
  }
  let mut byte_offset = (7 - first_word) * 4
  while i < count {
    let bits = Float::from_double(wave_sin * 0.12).reinterpret_as_uint()
    @writes.put_u32_le_mut_view(bytes, byte_offset, bits)
    let next_sin = wave_sin * cos_step + wave_cos * sin_step
    wave_cos = wave_cos * cos_step - wave_sin * sin_step
    wave_sin = next_sin
    i = i + 1
    byte_offset = byte_offset + stride_bytes
  }
}

///|
/// Implements `global_transform_default_format`.
fn global_transform_default_format() -> @comp.GlobalTransformGpuFormat {
  match global_transform_precision_mode {
    AllF32 => Affine3x4F32
    _ => Affine3x4F16
  }
}

///|
/// Implements `entity_uses_f32`.
fn entity_uses_f32(entity : @ecs.EntityId, local_index : Int) -> Bool {
  match global_transform_precision_mode {
    AllF32 => true
    AllF16 => false
    FirstHalfF32SecondHalfF16 => local_index < entity_count / 2
    EvenIdF32OddIdF16 => entity.index % 2 == 0
  }
}

///|
/// Implements `apply_global_transform_precision_mode`.
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
/// Implements `write_mass_cubes_transform_blob`.
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
/// Implements `update_and_drain_global_transforms`.
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
  if !full_rows {
    match dense_transform_layout {
      Some(layout) =>
        return world.write_global_transform_blob_range_views(
          upload_range.first_word,
          upload_range.word_count,
          ///|
          /// Implements `this function`.
          fn(bytes) {
            write_mass_cubes_dense_y_transform_wave(
              bytes,
              entity_count,
              upload_range.first_word,
              layout.words_per_entity,
              global_transform_format_code_int(layout.format),
              t * 1.8,
            )
          },
        )
      None => ()
    }
  }
  world.write_global_transform_blob_range_by_refs(
    transform_refs,
    entity_count,
    upload_range,
    dense_transform_layout,
    ///|
    /// Implements `this function`.
    fn(writer) {
      write_mass_cubes_transform_blob(writer, per_side, t, full_rows)
    },
  )
}

///|
/// Defines `DemoState`.
pub(all) struct DemoState {
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
  scene : @app.Scene
  gt : @ecs.ComponentTypeId
  tf : @ecs.ComponentTypeId
  per_side : Int
  transform_refs : FixedArray[Byte]
  transform_upload_range : @ecs.GlobalTransformUploadRange
  dense_transform_layout : @ecs.GlobalTransformDenseLayout?
  bind_group_offsets : Array[UInt]
  orbit_controller : @ecs.ComponentTypeId
  camera_home : @ecs.ComponentTypeId
  camera_lens : @ecs.ComponentTypeId
  frame : @ref.Ref[Int]
  perf_last_frame_start_ms : @ref.Ref[Double]
  perf_frame_start_ms : @ref.Ref[Double]
  perf_excluded_wait_ms : @ref.Ref[Double]
}

///|
/// Implements `ecs_mass_shader_wgsl`.
fn ecs_mass_shader_wgsl() -> String {
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

///|
/// Implements `ecs_mass_cubes_perf_overlay`.
#cfg(target="js")
fn ecs_mass_cubes_perf_overlay(fps : Double, cpu_ms : Double) -> Unit {
  ecs_mass_cubes_perf_overlay_js(fps, cpu_ms)
}

///|

///|
/// Implements `ecs_mass_cubes_perf_overlay`.
#cfg(not(target="js"))
fn ecs_mass_cubes_perf_overlay(_fps : Double, _cpu_ms : Double) -> Unit {
  ignore(_fps)
  ignore(_cpu_ms)
  ()
}

///|

///|
/// Implements `ecs_mass_cubes_perf_console_log`.
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

///|
/// Implements `ecs_mass_cubes_perf_console_log`.
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
/// Builds the ECS scene used by the mass-cubes sample.
fn create_scene() -> @app.Scene {
  @app.Scene::new_with_world(
    "ecs-mass-cubes",
    @ecs.World::new_with_global_transform_format(
      global_transform_default_format(),
    ),
  )
}

///|
/// Implements `create_engine`.
pub fn create_engine(context : @wgpu.GPUContext) -> @app.Engine {
  @app.Engine::new_with_main_scene(context, create_scene())
}

///|
/// Implements `create_demo_state`.
pub fn create_demo_state(context : @wgpu.GPUContext) -> DemoState? {
  let engine = create_engine(context)
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
  create_demo_state_for_scene(create_scene(), device, queue, format, context~)
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
  let world = scene.world()
  let gt = world.global_transform_component()
  let tf = world.transform_component()
  let orbit_controller = @ecs.register_orbit_camera_controller_component(world)
  let camera_home = @ecs.register_camera_home_transform_component(world)
  let camera_lens = @ecs.register_camera_lens_component(world)
  scene.add_common_systems(
    orbit_component=Some(orbit_controller),
    home_component=Some(camera_home),
  )
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
  let camera = world.create_entity()
  ignore(
    world.set_transform_trs(
      camera,
      (0.0 : Float),
      (0.0 : Float),
      (16.0 : Float),
      0.0,
      0.0,
      0.0,
      1.0,
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    ),
  )
  ignore(world.set_global_transform(camera, @m44.Matrix44F::identity()))
  ignore(
    @ecs.add_orbit_camera_controller_with_distance(
      world,
      camera,
      orbit_controller,
      0.0,
      camera_elevation_rad,
      (16.0 : Float),
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
      (80.0 : Float),
      Float::from_double(canvas_width.to_double() / canvas_height.to_double()),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  let (camera_yaw, camera_pitch, camera_pan_x, camera_pan_y, camera_dolly) = @ecs.orbit_camera_transform(
    world, camera, orbit_controller,
  )
  let (camera_view, camera_proj, camera_near, camera_far, camera_aspect) = camera_matrices(
    camera_yaw, camera_pitch, camera_pan_x, camera_pan_y, camera_dolly,
  )
  match camera_view.inverse() {
    Some(camera_global) =>
      ignore(world.set_global_transform(camera, camera_global))
    None => ()
  }
  ignore(
    world.set_camera_matrices(
      camera,
      camera_view,
      camera_proj,
      camera_near,
      camera_far,
      camera_aspect,
      @ecs.camera_projection_orthographic(),
      (0.0 : Float),
    ),
  )
  scene.set_main_camera(Some(camera))
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
  let demo_state : DemoState = {
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
    scene,
    gt,
    tf,
    per_side,
    transform_refs,
    transform_upload_range,
    dense_transform_layout,
    bind_group_offsets: [],
    orbit_controller,
    camera_home,
    camera_lens,
    frame: @ref.new(0),
    perf_last_frame_start_ms: @ref.new(-1.0),
    perf_frame_start_ms: @ref.new(-1.0),
    perf_excluded_wait_ms: @ref.new(0.0),
  }
  demo_state.add_mass_cubes_camera_sync_system()
  ignore(
    scene.run_schedule_phase(
      @app.phase_post_update(),
      @app.FrameState::new((0.0 : Float), 0, 0.0),
    ),
  )
  ignore(
    scene.run_schedule_phase(
      @app.phase_render_extract(),
      @app.FrameState::new((0.0 : Float), 0, 0.0),
    ),
  )
  queue.drain_and_upload_camera_writes(camera_storage, world)
  demo_state
}

///|
/// Starts per-frame CPU timing and updates the FPS reference point.
fn DemoState::begin_perf_frame(self : DemoState) -> Unit {
  let t_frame_start = monotonic_ms()
  self.perf_frame_start_ms.val = t_frame_start
  self.perf_excluded_wait_ms.val = 0.0
}

///|
/// Excludes external frame pacing waits from the per-frame CPU timing.
fn DemoState::exclude_perf_wait(self : DemoState, wait_ms : Double) -> Unit {
  if self.perf_frame_start_ms.val >= 0.0 {
    self.perf_excluded_wait_ms.val = self.perf_excluded_wait_ms.val + wait_ms
  }
}

///|
/// Returns the scene main camera or aborts because this DemoState requires one.
fn scene_main_camera_or_abort(scene : @app.Scene) -> @ecs.EntityId {
  match scene.main_camera() {
    Some(camera) => camera
    None => abort("render_scene requires Scene.main_camera")
  }
}

///|
/// Updates the scene camera GlobalTransform and Camera blob through the MassCubes camera solver.
fn DemoState::sync_mass_cubes_camera_blob(self : DemoState) -> Unit {
  let world = self.scene.world()
  let camera = scene_main_camera_or_abort(self.scene)
  let (camera_yaw, camera_pitch, camera_pan_x, camera_pan_y, camera_dolly) = @ecs.orbit_camera_transform(
    world,
    camera,
    self.orbit_controller,
  )
  let (camera_view0, camera_proj, camera_near, camera_far, camera_aspect) = camera_matrices(
    camera_yaw, camera_pitch, camera_pan_x, camera_pan_y, camera_dolly,
  )
  match camera_view0.inverse() {
    Some(global) => ignore(world.set_global_transform(camera, global))
    None => ()
  }
  ignore(
    world.set_camera_matrices(
      camera,
      camera_view0,
      camera_proj,
      camera_near,
      camera_far,
      camera_aspect,
      @ecs.camera_projection_orthographic(),
      (0.0 : Float),
    ),
  )
}

///|
/// Adds the MassCubes-specific camera blob sync as a render-extract ECS system.
fn DemoState::add_mass_cubes_camera_sync_system(self : DemoState) -> Unit {
  let world = self.scene.world()
  self.scene.add_system(
    @app.phase_render_extract(),
    "MassCubesCameraSync",
    [self.orbit_controller],
    [world.global_transform_component(), world.camera_component()],
    fn(_world, _ctx, _commands) { self.sync_mass_cubes_camera_blob() },
  )
}

///|
/// Implements `render_frame`.
pub fn render_frame(demo_state : DemoState) -> Unit {
  let canvas_context = match demo_state.context {
    Some(c) => c
    None => abort("render_frame requires a canvas context")
  }
  let texture = canvas_context.get_current_texture()
  let color_view = texture.create_view()
  render_frame_to_view(demo_state, color_view, record_perf=true)
  @wgpu.textureView_release(color_view)
  canvas_context.present()
}

///|
/// Renders the current scene state without advancing app time.
pub fn render_current_frame(
  demo_state : DemoState,
  record_perf? : Bool = false,
) -> Unit {
  let canvas_context = match demo_state.context {
    Some(c) => c
    None => abort("render_current_frame requires a canvas context")
  }
  let t_acquire_start = monotonic_ms()
  let texture = canvas_context.get_current_texture()
  if record_perf {
    demo_state.exclude_perf_wait(monotonic_ms() - t_acquire_start)
  }
  let color_view = texture.create_view()
  render_current_frame_to_view(demo_state, color_view, record_perf~)
  @wgpu.textureView_release(color_view)
  canvas_context.present()
}

///|
/// Updates the wave animation and transform upload data for one app frame.
pub fn DemoState::update_scene(
  self : DemoState,
  frame : @app.FrameState,
) -> Unit {
  self.frame.val = frame.frame_index()
  let t = frame.frame_index().to_double() * 0.018
  let world = self.scene.world()
  let writes = update_and_drain_global_transforms(
    world,
    self.tf,
    self.gt,
    self.per_side,
    t,
    self.transform_refs,
    self.transform_upload_range,
    self.dense_transform_layout,
    false,
  )
  self.queue.upload_global_transform_writes(self.transform_storage, writes)
}

///|
/// Implements `render_frame_to_view`.
pub fn render_frame_to_view(
  demo_state : DemoState,
  color_view : @wgpu.GPUTextureView,
  record_perf? : Bool = false,
) -> Unit {
  demo_state.frame.val = demo_state.frame.val + 1
  if record_perf {
    demo_state.begin_perf_frame()
  }
  demo_state.update_scene(
    @app.FrameState::new(
      (0.022 : Float),
      demo_state.frame.val,
      demo_state.frame.val.to_double() * 0.022,
    ),
  )
  ignore(
    demo_state.scene.run_schedule_phase(
      @app.phase_post_update(),
      @app.FrameState::new(
        (0.022 : Float),
        demo_state.frame.val,
        demo_state.frame.val.to_double() * 0.022,
      ),
    ),
  )
  ignore(
    demo_state.scene.run_schedule_phase(
      @app.phase_render_extract(),
      @app.FrameState::new(
        (0.022 : Float),
        demo_state.frame.val,
        demo_state.frame.val.to_double() * 0.022,
      ),
    ),
  )
  render_current_frame_to_view(demo_state, color_view, record_perf~)
}

///|
/// Renders the current scene state to a target view without advancing the scene.
pub fn render_current_frame_to_view(
  demo_state : DemoState,
  color_view : @wgpu.GPUTextureView,
  record_perf? : Bool = false,
) -> Unit {
  let t_render_start = monotonic_ms()
  let t_frame_start = if demo_state.perf_frame_start_ms.val >= 0.0 {
    demo_state.perf_frame_start_ms.val
  } else {
    t_render_start
  }
  let last_start = demo_state.perf_last_frame_start_ms.val
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
  demo_state.perf_last_frame_start_ms.val = t_frame_start
  demo_state.render_scene(demo_state.scene, color_view)
  if record_perf {
    let raw_cpu_ms = monotonic_ms() -
      t_frame_start -
      demo_state.perf_excluded_wait_ms.val
    let cpu_ms = if raw_cpu_ms > 0.0 { raw_cpu_ms } else { 0.0 }
    ecs_mass_cubes_perf_overlay(fps, cpu_ms)
    ecs_mass_cubes_perf_console_log(fps, cpu_ms, demo_state.frame.val)
  }
  demo_state.perf_frame_start_ms.val = -1.0
}

///|
/// Renders a scene by uploading scene-owned camera data and issuing draw commands.
pub fn DemoState::render_scene(
  self : DemoState,
  scene : @app.Scene,
  color_view : @wgpu.GPUTextureView,
) -> Unit {
  let world = scene.world()
  self.queue.drain_and_upload_camera_writes(self.camera_storage, world)
  let encoder = self.device.create_command_encoder()
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
      view: self.depth_view,
      depth_clear_value: Some(1.0),
      depth_load_op: @wgpu.GPULoadOp::Clear,
      depth_store_op: @wgpu.GPUStoreOp::Store,
    }),
  })
  render_pass.set_pipeline(self.pipeline)
  render_pass.set_bind_group(0U, self.bind_transforms, self.bind_group_offsets)
  render_pass.set_bind_group(1U, self.bind_camera, self.bind_group_offsets)
  render_pass.set_index_buffer(
    self.index_buffer,
    @wgpu.GPUIndexFormat::Uint16,
    0UL,
    index_buffer_byte_length,
  )
  render_pass.set_vertex_buffer(
    0,
    self.vertex_buffer,
    0UL,
    (verts_per_cube * vertex_stride_local).to_uint64(),
  )
  render_pass.set_vertex_buffer(
    1,
    self.instance_buffer,
    0UL,
    (entity_count * instance_stride).to_uint64(),
  )
  render_pass.draw_indexed(index_u16_count, instance_count=entity_count)
  render_pass.end()
  render_pass.release()
  let command_buffer = encoder.finish()
  self.queue.submit(command_buffer)
  encoder.release()
}

///|
/// Registers engine phase handlers that drive this DemoState.
pub fn register_engine_handlers(
  engine : @app.Engine,
  demo_state : DemoState,
) -> Unit {
  engine.add_common_handlers(
    demo_state.scene,
    orbit_component=Some(demo_state.orbit_controller),
    home_component=Some(demo_state.camera_home),
  )
  engine.add_handler_on_phase(@app.phase_update(), fn(_engine, frame) {
    demo_state.begin_perf_frame()
    demo_state.update_scene(frame)
  })
  engine.add_handler_on_phase(
    @app.phase_render(),
    fn(_engine, _frame) {
      if demo_state.scene.visible() {
        render_current_frame(demo_state, record_perf=true)
      }
    },
    slot=@app.PhaseSlot::AfterSchedule,
  )
  engine.add_handler_on_phase(@app.phase_shutdown(), fn(_engine, _frame) {
    demo_state.release()
  })
}

///|
/// Implements `DemoState::release`.
pub fn DemoState::release(self : DemoState) -> Unit {
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
/// Implements `demo_state_release`.
pub fn demo_state_release(demo_state : DemoState) -> Unit {
  demo_state.release()
}
