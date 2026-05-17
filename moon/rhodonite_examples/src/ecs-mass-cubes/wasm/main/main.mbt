///|
/// Implements `host_now_ms`.
fn host_now_ms() -> Double = "rhodonite_ecs_mass_cubes_host" "now_ms"

///|
/// Implements `host_initialize_demo_state`.
fn host_initialize_demo_state(per_side : Int, transform_stride : Int) -> Unit = "rhodonite_ecs_mass_cubes_host" "initialize_demo_state"

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
/// Implements `host_render_demo_frame`.
fn host_render_demo_frame(fps : Double, cpu_ms : Double) -> Unit = "rhodonite_ecs_mass_cubes_host" "render_demo_frame"

///|
/// Implements `host_begin_input_frame`.
fn host_begin_input_frame() -> Unit = "rhodonite_ecs_mass_cubes_host" "begin_input_frame"

///|
/// Implements `host_input_mouse_down`.
fn host_input_mouse_down(button : Int) -> Bool = "rhodonite_ecs_mass_cubes_host" "input_mouse_down"

///|
/// Implements `host_input_mouse_pressed`.
fn host_input_mouse_pressed(button : Int) -> Bool = "rhodonite_ecs_mass_cubes_host" "input_mouse_pressed"

///|
/// Implements `host_input_pointer_delta_x`.
fn host_input_pointer_delta_x() -> Float = "rhodonite_ecs_mass_cubes_host" "input_pointer_delta_x"

///|
/// Implements `host_input_pointer_delta_y`.
fn host_input_pointer_delta_y() -> Float = "rhodonite_ecs_mass_cubes_host" "input_pointer_delta_y"

///|
/// Implements `host_input_wheel_delta_y`.
fn host_input_wheel_delta_y() -> Float = "rhodonite_ecs_mass_cubes_host" "input_wheel_delta_y"

///|
/// Implements `host_write_camera_word`.
fn host_write_camera_word(word_index : Int, word : UInt) -> Unit = "rhodonite_ecs_mass_cubes_host" "write_camera_word"

///|
/// Implements `host_upload_camera_words`.
fn host_upload_camera_words() -> Unit = "rhodonite_ecs_mass_cubes_host" "upload_camera_words"

///|
let camera_elevation_rad : Double = @mass_shared.camera_elevation_rad()

///|
let cube_scale : Float = @mass_shared.cube_scale()

///|
/// Implements `grid_side_len`.
fn grid_side_len(n : Int) -> Int {
  @mass_shared.grid_side_len(n)
}

///|
/// Implements `grid_xz_for_index`.
fn grid_xz_for_index(idx : Int, per_side : Int) -> (Float, Float) {
  @mass_shared.grid_xz_for_index(idx, per_side)
}

///|
/// Updates the builtin Camera blob from the MassCubes camera solver.
fn sync_mass_cubes_camera_blob(
  world : @ecs.World,
  camera : @ecs.EntityId,
  orbit_controller : @ecs.ComponentTypeId,
  count : Int,
) -> Unit {
  let (yaw, pitch, pan_x, pan_y, dolly) = @ecs.orbit_camera_transform(
    world, camera, orbit_controller,
  )
  let (view, proj, near, far, aspect) = @mass_shared.camera_matrices(
    count, yaw, pitch, pan_x, pan_y, dolly,
  )
  ignore(
    world.set_camera_matrices(
      camera,
      view,
      proj,
      near,
      far,
      aspect,
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
}

///|
/// Uploads the current packed Camera blob row to the WebGPU host buffer.
fn upload_current_camera(world : @ecs.World, camera : @ecs.EntityId) -> Unit {
  match world.camera_gpu_row(camera) {
    Some(row) => {
      let words = @comp.camera_gpu_word_count()
      for word = 0; word < words; word = word + 1 {
        host_write_camera_word(word, @writes.get_u32_le(row, word * 4))
      }
      ignore(world.drain_camera_blob_write_views())
      host_upload_camera_words()
    }
    None => abort("upload_current_camera: camera is missing Camera component")
  }
}

///|
/// Updates the WASM-owned orbit controller from host-provided browser input.
fn update_orbit_camera_from_host_input(
  world : @ecs.World,
  camera : @ecs.EntityId,
  orbit_controller : @ecs.ComponentTypeId,
) -> Unit {
  ignore(
    @ecs.update_orbit_camera_controller_from_mouse_frame(
      world,
      camera,
      orbit_controller,
      host_input_mouse_down(0),
      host_input_mouse_pressed(0),
      host_input_mouse_down(1),
      host_input_mouse_pressed(1),
      host_input_pointer_delta_x(),
      host_input_pointer_delta_y(),
      host_input_wheel_delta_y(),
    ),
  )
}

///|
/// Defines `WasmDemoState`.
struct WasmDemoState {
  world : @ecs.World
  camera : @ecs.EntityId
  orbit_controller : @ecs.ComponentTypeId
  frame : @ref.Ref[Int]
  perf_last_frame_start_ms : @ref.Ref[Double]
  perf_frame_start_ms : @ref.Ref[Double]
  perf_current_fps : @ref.Ref[Double]
}

///|
let demo_state : @ref.Ref[WasmDemoState?] = @ref.new(None)

///|
/// Implements `create_wasm_demo_state`.
pub fn create_wasm_demo_state() -> Unit {
  let world = @ecs.World::new()
  let count = @mass_shared.entity_count()
  let per_side = grid_side_len(count)
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
  host_initialize_demo_state(per_side, stride)
  host_write_initial_global_transforms(per_side, 0.0)
  let orbit_controller = @ecs.register_orbit_camera_controller_component(world)
  let camera = world.create_entity()
  ignore(
    @ecs.add_orbit_camera_controller(
      world, camera, orbit_controller, 0.0, camera_elevation_rad,
    ),
  )
  sync_mass_cubes_camera_blob(world, camera, orbit_controller, count)
  upload_current_camera(world, camera)
  demo_state.val = Some({
    world,
    camera,
    orbit_controller,
    frame: @ref.new(0),
    perf_last_frame_start_ms: @ref.new(-1.0),
    perf_frame_start_ms: @ref.new(-1.0),
    perf_current_fps: @ref.new(0.0),
  })
}

///|
/// Runs the WASM-owned input and update phase for one MassCubes frame.
pub fn ecs_mass_cubes_wasm_update_tick() -> Unit {
  match demo_state.val {
    None => ()
    Some(demo_state) => {
      let t_frame_start = host_now_ms()
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
      demo_state.perf_frame_start_ms.val = t_frame_start
      demo_state.perf_current_fps.val = fps
      demo_state.frame.val = demo_state.frame.val + 1
      let wave_time = demo_state.frame.val.to_double() * 0.018 * 1.8
      host_write_global_transform_y(wave_time)
      host_begin_input_frame()
      update_orbit_camera_from_host_input(
        demo_state.world,
        demo_state.camera,
        demo_state.orbit_controller,
      )
    }
  }
}

///|
/// Runs the WASM-owned render-extract phase for the MassCubes camera blob.
pub fn ecs_mass_cubes_wasm_render_extract() -> Unit {
  match demo_state.val {
    None => ()
    Some(demo_state) => {
      sync_mass_cubes_camera_blob(
        demo_state.world,
        demo_state.camera,
        demo_state.orbit_controller,
        @mass_shared.entity_count(),
      )
      upload_current_camera(demo_state.world, demo_state.camera)
    }
  }
}

///|
/// Runs the host render pass after update and render-extract have prepared data.
pub fn ecs_mass_cubes_wasm_render() -> Unit {
  match demo_state.val {
    None => ()
    Some(demo_state) => {
      let t_frame_start = if demo_state.perf_frame_start_ms.val >= 0.0 {
        demo_state.perf_frame_start_ms.val
      } else {
        host_now_ms()
      }
      let cpu_ms = host_now_ms() - t_frame_start
      host_render_demo_frame(demo_state.perf_current_fps.val, cpu_ms)
      demo_state.perf_frame_start_ms.val = -1.0
    }
  }
}

///|
/// Implements `ecs_mass_cubes_wasm_render_tick`.
pub fn ecs_mass_cubes_wasm_render_tick() -> Unit {
  ecs_mass_cubes_wasm_update_tick()
  ecs_mass_cubes_wasm_render_extract()
  ecs_mass_cubes_wasm_render()
}

///|
/// Implements `main {`.
fn main {
  ()
}
