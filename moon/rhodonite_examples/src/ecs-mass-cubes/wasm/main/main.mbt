///|
fn host_now_ms() -> Double = "rhodonite_ecs_mass_cubes_host" "now_ms"

///|
fn host_entity_count() -> Int = "rhodonite_ecs_mass_cubes_host" "entity_count"

///|
fn host_initialize_renderer(per_side : Int, transform_stride : Int) -> Unit = "rhodonite_ecs_mass_cubes_host" "initialize_renderer"

///|
#cfg(target="wasm-gc")
fn host_write_initial_global_transforms(
  per_side : Int,
  wave_time : Double,
) -> Unit = "rhodonite_ecs_mass_cubes_host" "write_initial_global_transforms"

///|
#cfg(target="wasm-gc")
fn host_write_global_transform_y(wave_time : Double) -> Unit = "rhodonite_ecs_mass_cubes_host" "write_global_transform_y"

///|
#cfg(target="wasm")
fn host_write_initial_global_transform_bytes(ptr : Int, byte_len : Int) -> Unit = "rhodonite_ecs_mass_cubes_host" "write_initial_global_transform_bytes"

///|
#cfg(target="wasm")
fn host_write_global_transform_bytes(ptr : Int, byte_len : Int) -> Unit = "rhodonite_ecs_mass_cubes_host" "write_global_transform_bytes"

///|
fn host_render_frame(fps : Double, cpu_ms : Double) -> Unit = "rhodonite_ecs_mass_cubes_host" "render_frame"

///|
let grid_spacing : Double = 0.14

///|
let cube_scale : Float = 0.055

///|
#cfg(target="wasm")
fn fixedarray_float_object_ptr(values : FixedArray[Float]) -> Int = "%identity"

///|
#cfg(target="wasm")
fn fixedarray_float_payload_ptr(values : FixedArray[Float]) -> Int {
  // MoonBit's current wasm array layout stores the payload after an 8-byte header.
  fixedarray_float_object_ptr(values) + 8
}

///|
fn grid_side_len(n : Int) -> Int {
  let mut s = 1
  while s * s < n {
    s = s + 1
  }
  s
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
#cfg(target="wasm")
fn write_mass_cubes_full_wasm_f32_upload(
  values : FixedArray[Float],
  count : Int,
  per_side : Int,
  wave_time : Double,
) -> Unit {
  let half = Float::from_double((per_side - 1).to_double() * 0.5)
  let grid_spacing_f = Float::from_double(grid_spacing)
  let sin_step = Float::from_double(@math.sin(0.09))
  let cos_step = Float::from_double(@math.cos(0.09))
  let mut local_i = 0
  let mut row = 0
  let mut column = 0
  let mut out = 0
  while local_i < count {
    let remaining_in_row = per_side - column
    let remaining_count = count - local_i
    let row_count = if remaining_count > remaining_in_row {
      remaining_in_row
    } else {
      remaining_count
    }
    let mut x = (Float::from_int(column) - half) * grid_spacing_f
    let z = (Float::from_int(row) - half) * grid_spacing_f
    let mut wave_s = Float::from_double(
      @math.sin(local_i.to_double() * 0.09 + wave_time),
    )
    let mut wave_c = Float::from_double(
      @math.cos(local_i.to_double() * 0.09 + wave_time),
    )
    let mut row_i = 0
    while row_i < row_count {
      values[out] = cube_scale
      values[out + 1] = 0.0
      values[out + 2] = 0.0
      values[out + 3] = x
      values[out + 4] = 0.0
      values[out + 5] = cube_scale
      values[out + 6] = 0.0
      values[out + 7] = wave_s * 0.12
      values[out + 8] = 0.0
      values[out + 9] = 0.0
      values[out + 10] = cube_scale
      values[out + 11] = z
      let next_s = wave_s * cos_step + wave_c * sin_step
      wave_c = wave_c * cos_step - wave_s * sin_step
      wave_s = next_s
      x = x + grid_spacing_f
      local_i = local_i + 1
      out = out + 12
      row_i = row_i + 1
    }
    row = row + 1
    column = 0
  }
}

///|
#cfg(target="wasm")
fn write_mass_cubes_y_wasm_f32_upload(
  values : FixedArray[Float],
  count : Int,
  wave_time : Double,
) -> Unit {
  let sin_step = Float::from_double(@math.sin(0.09))
  let cos_step = Float::from_double(@math.cos(0.09))
  let mut local_i = 0
  let mut y_index = 7
  let mut wave_s = Float::from_double(@math.sin(wave_time))
  let mut wave_c = Float::from_double(@math.cos(wave_time))
  while local_i < count {
    values[y_index] = wave_s * 0.12
    let next_s = wave_s * cos_step + wave_c * sin_step
    wave_c = wave_c * cos_step - wave_s * sin_step
    wave_s = next_s
    local_i = local_i + 1
    y_index = y_index + 12
  }
}

///|
#cfg(target="wasm")
fn make_upload_f32_for_target(count : Int) -> FixedArray[Float] {
  FixedArray::make(count * 12, (0.0 : Float))
}

///|
#cfg(target="wasm-gc")
fn make_upload_f32_for_target(_count : Int) -> FixedArray[Float] {
  FixedArray::make(0, (0.0 : Float))
}

///|
#cfg(target="wasm")
fn write_initial_global_transforms_for_target(
  _world : @ecs.World,
  count : Int,
  per_side : Int,
  upload_f32 : FixedArray[Float],
) -> Unit {
  write_mass_cubes_full_wasm_f32_upload(upload_f32, count, per_side, 0.0)
}

///|
#cfg(target="wasm-gc")
fn write_initial_global_transforms_for_target(
  _world : @ecs.World,
  _count : Int,
  _per_side : Int,
  _upload_f32 : FixedArray[Float],
) -> Unit {
  ()
}

///|
#cfg(target="wasm")
fn host_write_initial_global_transforms_for_target(
  _world : @ecs.World,
  _per_side : Int,
  _upload_f32 : FixedArray[Float],
  upload_ptr : Int,
  upload_len : Int,
) -> Unit {
  host_write_initial_global_transform_bytes(upload_ptr, upload_len)
}

///|
#cfg(target="wasm-gc")
fn host_write_initial_global_transforms_for_target(
  _world : @ecs.World,
  per_side : Int,
  _upload_f32 : FixedArray[Float],
  _upload_ptr : Int,
  _upload_len : Int,
) -> Unit {
  host_write_initial_global_transforms(per_side, 0.0)
}

///|
#cfg(target="wasm")
fn write_global_transform_y_for_target(
  _world : @ecs.World,
  count : Int,
  wave_time : Double,
  upload_f32 : FixedArray[Float],
  upload_ptr : Int,
  upload_len : Int,
) -> Unit {
  write_mass_cubes_y_wasm_f32_upload(upload_f32, count, wave_time)
  host_write_global_transform_bytes(upload_ptr, upload_len)
}

///|
#cfg(target="wasm-gc")
fn write_global_transform_y_for_target(
  _world : @ecs.World,
  _count : Int,
  wave_time : Double,
  _upload_f32 : FixedArray[Float],
  _upload_ptr : Int,
  _upload_len : Int,
) -> Unit {
  host_write_global_transform_y(wave_time)
}

///|
struct WasmRenderer {
  world : @ecs.World
  entity_count : Int
  frame : @ref.Ref[Int]
  perf_last_frame_start_ms : @ref.Ref[Double]
  upload_f32 : FixedArray[Float]
  upload_ptr : Int
  upload_len : Int
}

///|
let demo_renderer : @ref.Ref[WasmRenderer?] = @ref.new(None)

///|
#cfg(target="wasm")
fn global_transform_upload_ptr_for_target(
  upload_f32 : FixedArray[Float],
) -> Int {
  fixedarray_float_payload_ptr(upload_f32)
}

///|
#cfg(target="wasm-gc")
fn global_transform_upload_ptr_for_target(
  _upload_f32 : FixedArray[Float],
) -> Int {
  0
}

///|
#cfg(target="wasm")
fn global_transform_upload_len_for_target(
  upload_f32 : FixedArray[Float],
) -> Int {
  upload_f32.length() * 4
}

///|
#cfg(target="wasm-gc")
fn global_transform_upload_len_for_target(
  _upload_f32 : FixedArray[Float],
) -> Int {
  0
}

///|
pub fn create_wasm_renderer() -> Unit {
  let world = @ecs.World::new()
  let count = host_entity_count()
  let per_side = grid_side_len(count)
  let gt = world.global_transform_component()
  let _ = world.spawn_transform_global_batch(count, fn(
    i,
    _entity,
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
  })
  ignore(world.drain_resize_events())
  let stride = 48
  let upload_f32 = make_upload_f32_for_target(count)
  write_initial_global_transforms_for_target(world, count, per_side, upload_f32)
  let upload_ptr = global_transform_upload_ptr_for_target(upload_f32)
  let upload_len = global_transform_upload_len_for_target(upload_f32)
  host_initialize_renderer(per_side, stride)
  host_write_initial_global_transforms_for_target(
    world, per_side, upload_f32, upload_ptr, upload_len,
  )
  ignore(gt)
  demo_renderer.val = Some({
    world,
    entity_count: count,
    frame: @ref.new(0),
    perf_last_frame_start_ms: @ref.new(-1.0),
    upload_f32,
    upload_ptr,
    upload_len,
  })
}

///|
pub fn ecs_mass_cubes_wasm_render_tick() -> Unit {
  match demo_renderer.val {
    None => ()
    Some(renderer) => {
      let t_frame_start = host_now_ms()
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
      let wave_time = renderer.frame.val.to_double() * 0.018 * 1.8
      write_global_transform_y_for_target(
        renderer.world,
        renderer.entity_count,
        wave_time,
        renderer.upload_f32,
        renderer.upload_ptr,
        renderer.upload_len,
      )
      let cpu_ms = host_now_ms() - t_frame_start
      host_render_frame(fps, cpu_ms)
    }
  }
}

///|
fn main {
  ()
}
