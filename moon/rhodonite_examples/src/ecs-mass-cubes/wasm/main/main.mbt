///|
fn host_now_ms() -> Double = "rhodonite_ecs_mass_cubes_host" "now_ms"

///|
fn host_initialize_renderer(per_side : Int, transform_stride : Int) -> Unit = "rhodonite_ecs_mass_cubes_host" "initialize_renderer"

///|
fn host_write_initial_global_transforms(
  per_side : Int,
  wave_time : Double,
) -> Unit = "rhodonite_ecs_mass_cubes_host" "write_initial_global_transforms"

///|
fn host_write_global_transform_y(wave_time : Double) -> Unit = "rhodonite_ecs_mass_cubes_host" "write_global_transform_y"

///|
fn host_render_frame(fps : Double, cpu_ms : Double) -> Unit = "rhodonite_ecs_mass_cubes_host" "render_frame"

///|
let entity_count : Int = 600_000

///|
let grid_spacing : Double = 0.14

///|
let cube_scale : Float = 0.055

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
fn write_mass_cubes_full_range(
  range : @ecs.GpuComponentWriteRange,
  per_side : Int,
  wave_time : Double,
) -> Unit {
  let bytes = range.bytes()
  let stride = range.stride()
  let first = range.first_entity_index()
  let count = range.count()
  let half = (per_side - 1).to_double() * 0.5
  let scale_d = cube_scale.to_double()
  let sin_step = @math.sin(0.09)
  let cos_step = @math.cos(0.09)
  let mut local_i = 0
  let mut row = first / per_side
  let mut column = first % per_side
  while local_i < count {
    let remaining_in_row = per_side - column
    let remaining_count = count - local_i
    let row_count = if remaining_count > remaining_in_row {
      remaining_in_row
    } else {
      remaining_count
    }
    let mut x = (column.to_double() - half) * grid_spacing
    let z = (row.to_double() - half) * grid_spacing
    let global_i = first + local_i
    let mut wave_s = @math.sin(global_i.to_double() * 0.09 + wave_time)
    let mut wave_c = @math.cos(global_i.to_double() * 0.09 + wave_time)
    let mut row_i = 0
    while row_i < row_count {
      let base = local_i * stride
      @writes.put_f32_le_mut_view(bytes, base + 0, scale_d)
      @writes.put_f32_le_mut_view(bytes, base + 4, 0.0)
      @writes.put_f32_le_mut_view(bytes, base + 8, 0.0)
      @writes.put_f32_le_mut_view(bytes, base + 12, 0.0)
      @writes.put_f32_le_mut_view(bytes, base + 16, 0.0)
      @writes.put_f32_le_mut_view(bytes, base + 20, scale_d)
      @writes.put_f32_le_mut_view(bytes, base + 24, 0.0)
      @writes.put_f32_le_mut_view(bytes, base + 28, 0.0)
      @writes.put_f32_le_mut_view(bytes, base + 32, 0.0)
      @writes.put_f32_le_mut_view(bytes, base + 36, 0.0)
      @writes.put_f32_le_mut_view(bytes, base + 40, scale_d)
      @writes.put_f32_le_mut_view(bytes, base + 44, 0.0)
      @writes.put_f32_le_mut_view(bytes, base + 48, x)
      @writes.put_f32_le_mut_view(bytes, base + 52, wave_s * 0.12)
      @writes.put_f32_le_mut_view(bytes, base + 56, z)
      @writes.put_f32_le_mut_view(bytes, base + 60, 1.0)
      let next_s = wave_s * cos_step + wave_c * sin_step
      wave_c = wave_c * cos_step - wave_s * sin_step
      wave_s = next_s
      x = x + grid_spacing
      local_i = local_i + 1
      row_i = row_i + 1
    }
    row = row + 1
    column = 0
  }
}

///|
fn write_mass_cubes_y_range(
  range : @ecs.GpuComponentWriteRange,
  wave_time : Double,
) -> Unit {
  let bytes = range.bytes()
  let stride = range.stride()
  let first = range.first_entity_index()
  let count = range.count()
  let sin_step = @math.sin(0.09)
  let cos_step = @math.cos(0.09)
  let mut local_i = 0
  let mut wave_s = @math.sin(first.to_double() * 0.09 + wave_time)
  let mut wave_c = @math.cos(first.to_double() * 0.09 + wave_time)
  while local_i < count {
    @writes.put_f32_le_mut_view(bytes, local_i * stride + 52, wave_s * 0.12)
    let next_s = wave_s * cos_step + wave_c * sin_step
    wave_c = wave_c * cos_step - wave_s * sin_step
    wave_s = next_s
    local_i = local_i + 1
  }
}

///|
struct WasmRenderer {
  world : @ecs.World
  frame : @ref.Ref[Int]
  perf_last_frame_start_ms : @ref.Ref[Double]
}

///|
let demo_renderer : @ref.Ref[WasmRenderer?] = @ref.new(None)

///|
pub fn create_wasm_renderer() -> Unit {
  let world = @ecs.World::new()
  let per_side = grid_side_len(entity_count)
  let gt = world.global_transform_component()
  let _ = world.spawn_transform_global_batch(entity_count, fn(
    i,
    _entity,
    tf_row,
    gt_row,
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
    @comp.global_transform_write_identity_row(gt_row)
  })
  ignore(world.drain_resize_events())
  let stride = @comp.global_transform_gpu_layout().stride
  ignore(
    world.write_global_transforms_dense_range_views(entity_count, range => {
      write_mass_cubes_full_range(range, per_side, 0.0)
    }),
  )
  host_initialize_renderer(per_side, stride)
  host_write_initial_global_transforms(per_side, 0.0)
  ignore(gt)
  demo_renderer.val = Some({
    world,
    frame: @ref.new(0),
    perf_last_frame_start_ms: @ref.new(-1.0),
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
      ignore(
        renderer.world.write_global_transforms_dense_range_views(entity_count, range => {
          write_mass_cubes_y_range(range, wave_time)
        }),
      )
      host_write_global_transform_y(wave_time)
      let cpu_ms = host_now_ms() - t_frame_start
      host_render_frame(fps, cpu_ms)
    }
  }
}

///|
fn main {
  ()
}
