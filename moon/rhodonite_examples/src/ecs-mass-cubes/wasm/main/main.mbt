///|
/// Implements `host_now_ms`.
fn host_now_ms() -> Double = "rhodonite_ecs_mass_cubes_host" "now_ms"

///|
/// Implements `host_entity_count`.
fn host_entity_count() -> Int = "rhodonite_ecs_mass_cubes_host" "entity_count"

///|
/// Implements `host_initialize_renderer`.
fn host_initialize_renderer(per_side : Int, transform_stride : Int) -> Unit = "rhodonite_ecs_mass_cubes_host" "initialize_renderer"

///|
/// Implements `host_write_initial_global_transforms`.
fn host_write_initial_global_transforms(
  per_side : Int,
  wave_time : Double,
) -> Unit = "rhodonite_ecs_mass_cubes_host" "write_initial_global_transforms"

///|
/// Implements `host_write_global_transform_y`.
fn host_write_global_transform_y(wave_time : Double) -> Unit = "rhodonite_ecs_mass_cubes_host" "write_global_transform_y"

///|
/// Implements `host_render_frame`.
fn host_render_frame(fps : Double, cpu_ms : Double) -> Unit = "rhodonite_ecs_mass_cubes_host" "render_frame"

///|
let grid_spacing : Double = 0.14

///|
let cube_scale : Float = 0.055

///|
/// Implements `grid_side_len`.
fn grid_side_len(n : Int) -> Int {
  let mut s = 1
  while s * s < n {
    s = s + 1
  }
  s
}

///|
/// Implements `grid_xz_for_index`.
fn grid_xz_for_index(idx : Int, per_side : Int) -> (Float, Float) {
  let ix = idx % per_side
  let iz = idx / per_side
  let half = (per_side - 1).to_double() * 0.5
  let fx = ix.to_double() - half
  let fz = iz.to_double() - half
  (Float::from_double(fx * grid_spacing), Float::from_double(fz * grid_spacing))
}

///|
/// Defines `WasmRenderer`.
struct WasmRenderer {
  frame : @ref.Ref[Int]
  perf_last_frame_start_ms : @ref.Ref[Double]
}

///|
let demo_renderer : @ref.Ref[WasmRenderer?] = @ref.new(None)

///|
/// Implements `create_wasm_renderer`.
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
  let stride = 24
  host_initialize_renderer(per_side, stride)
  host_write_initial_global_transforms(per_side, 0.0)
  ignore(gt)
  ignore(world)
  demo_renderer.val = Some({
    frame: @ref.new(0),
    perf_last_frame_start_ms: @ref.new(-1.0),
  })
}

///|
/// Implements `ecs_mass_cubes_wasm_render_tick`.
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
      host_write_global_transform_y(wave_time)
      let cpu_ms = host_now_ms() - t_frame_start
      host_render_frame(fps, cpu_ms)
    }
  }
}

///|
/// Implements `main {`.
fn main {
  ()
}
