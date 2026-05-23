/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

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
/// Selects the source-level precision mode for the MassCubes sample.
fn configured_global_transform_precision_mode() -> GlobalTransformPrecisionMode {
  match 1 {
    0 => AllF32
    1 => AllF16
    2 => FirstHalfF32SecondHalfF16
    _ => EvenIdF32OddIdF16
  }
}

///|
let global_transform_precision_mode : GlobalTransformPrecisionMode = configured_global_transform_precision_mode()

///|
/// Canvas resolution (matches demo HTML).
let canvas_width : UInt = @mass_shared.canvas_width()

///|
let canvas_height : UInt = @mass_shared.canvas_height()

///|
let instance_stride : Int = @mass_shared.instance_stride()

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
  renderer : @app.Renderer
  target : @app.RenderTargetResources
  scene : @app.Scene
  mesh : @app.MeshHandle
  instances : @app.InstanceBufferHandle
  gt : @ecs.ComponentTypeId
  tf : @ecs.ComponentTypeId
  per_side : Int
  transform_refs : FixedArray[Byte]
  transform_upload_range : @ecs.GlobalTransformUploadRange
  dense_transform_layout : @ecs.GlobalTransformDenseLayout?
  orbit_controller : @ecs.ComponentTypeId
  camera_home : @ecs.ComponentTypeId
  camera_lens : @ecs.ComponentTypeId
  frame : @ref.Ref[Int]
  perf_last_frame_start_ms : @ref.Ref[Double]
  perf_frame_start_ms : @ref.Ref[Double]
  perf_excluded_wait_ms : @ref.Ref[Double]
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
/// Implements `create_demo_state_for_engine`.
pub fn create_demo_state_for_engine(engine : @app.Engine) -> DemoState? {
  let (_device, canvas_context, _format, _queue) = engine.gpu_context().get()
  Some(
    create_demo_state_with_renderer(
      engine.main_scene(),
      engine.renderer(),
      engine.render_target_resources(),
      context=Some(canvas_context),
    ),
  )
}

///|
/// Creates DemoState backed by caller-provided renderer and target resources.
pub fn create_demo_state_with_renderer(
  scene : @app.Scene,
  renderer : @app.Renderer,
  target : @app.RenderTargetResources,
  context? : @wgpu.GPUCanvasContext? = None,
) -> DemoState {
  let world = scene.world()
  let gt = world.global_transform_component()
  let tf = world.transform_component()
  let orbit_controller = world.orbit_camera_controller_component()
  let camera_home = world.camera_home_transform_component()
  let camera_lens = world.camera_lens_component()
  scene.use_common_runtime(
    transform_propagation=false,
    orbit_camera_blob_sync=false,
  )
  let per_side = grid_side_len(entity_count)
  let inst_bytes_len = entity_count * instance_stride
  let instance_bytes = FixedArray::make(inst_bytes_len, (0 : Byte))
  ignore(world.reserve_batch_capacity([tf, gt], entity_count))
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
    @ecs.setup_orbit_orthographic_camera(
      world,
      camera,
      @ecs.OrbitOrthographicCameraDesc::new(
        0.0,
        camera_elevation_rad,
        (0.0 : Float),
        (0.0 : Float),
        (1.0 : Float),
        (16.0 : Float),
        (0.1 : Float),
        (80.0 : Float),
        Float::from_double(canvas_width.to_double() / canvas_height.to_double()),
        (1.0 : Float),
      ),
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
  let mesh = renderer.register_cube_mesh(
    desc=@app.CubeMeshDesc::new(half_extent=0.42),
  )
  let instances = renderer.register_static_instance_buffer(instance_bytes)
  let writes0 = update_and_drain_global_transforms(
    world, tf, gt, per_side, 0.0, transform_refs, transform_upload_range, dense_transform_layout,
    true,
  )
  renderer.upload_global_transform_writes(world, writes0)
  let demo_state : DemoState = {
    context,
    renderer,
    target,
    scene,
    mesh,
    instances,
    gt,
    tf,
    per_side,
    transform_refs,
    transform_upload_range,
    dense_transform_layout,
    orbit_controller,
    camera_home,
    camera_lens,
    frame: @ref.new(0),
    perf_last_frame_start_ms: @ref.new(-1.0),
    perf_frame_start_ms: @ref.new(-1.0),
    perf_excluded_wait_ms: @ref.new(0.0),
  }
  demo_state.add_mass_cubes_camera_sync_system()
  ignore(scene.prepare_render_state())
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
  @native_gpu_queue.wait_native_gpu_queue(demo_state.renderer.device())
  let t_acquire_start = monotonic_ms()
  let texture = canvas_context.get_current_texture()
  if record_perf {
    demo_state.exclude_perf_wait(monotonic_ms() - t_acquire_start)
  }
  let color_view = texture.create_view()
  render_current_frame_to_view(demo_state, color_view, record_perf~)
  @wgpu.textureView_release(color_view)
  @native_gpu_queue.wait_native_gpu_queue(demo_state.renderer.device())
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
  self.renderer.upload_global_transform_writes(world, writes)
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
    demo_state.scene.run_systems_for_phase(
      @app.phase_post_update(),
      @app.FrameState::new(
        (0.022 : Float),
        demo_state.frame.val,
        demo_state.frame.val.to_double() * 0.022,
      ),
    ),
  )
  ignore(
    demo_state.scene.run_systems_for_phase(
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
  self.sync_mass_cubes_camera_blob()
  self.renderer.render_instanced_mesh(
    scene,
    self.mesh,
    self.instances,
    entity_count,
    self.target,
    color_view,
  )
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
  engine.on_scene_update(demo_state.scene, fn(frame) {
    demo_state.begin_perf_frame()
    demo_state.update_scene(frame)
  })
  engine.on_scene_render(demo_state.scene, fn(_frame) {
    render_current_frame(demo_state, record_perf=true)
  })
}
