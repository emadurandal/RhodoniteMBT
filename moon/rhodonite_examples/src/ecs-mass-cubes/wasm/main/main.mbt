///|
/// Implements `host_now_ms`.
fn host_now_ms() -> Double = "rhodonite_ecs_mass_cubes_host" "now_ms"

///|
/// Implements `host_entity_count`.
fn host_entity_count() -> Int = "rhodonite_ecs_mass_cubes_host" "entity_count"

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
let canvas_width : UInt = 800U

///|
let canvas_height : UInt = 600U

///|
let camera_elevation_rad : Double = 0.42

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
/// Returns the view-space z extrema of the grid AABB corners after camera rotation.
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
/// Returns the view-space y extrema of the grid AABB corners after camera rotation.
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
/// Builds the camera view and projection matrices for the mass-cubes grid.
fn camera_matrices(
  count : Int,
  yaw : Double,
  pitch : Double,
  pan_x : Double,
  pan_y : Double,
  dolly : Double,
) -> (@m44.Matrix44F, @m44.Matrix44F, Float, Float, Float) {
  let view_base = @m44.Matrix44::rotation_x(pitch)
    .mat_mul(@m44.Matrix44::rotation_y(yaw))
    .mat_mul(@m44.Matrix44::translation(0.0, 0.0, -16.0, 1.0, 0.0))
  let per_side = grid_side_len(count)
  let half = (per_side - 1).to_double() * 0.5
  let extent_xz = half * grid_spacing
  let wave = 0.12
  let margin = cube_scale.to_double() * 2.5
  let wave_y = wave + cube_scale.to_double() * 1.1
  let (y_lo, y_hi) = view_space_y_range_corners(view_base, extent_xz, wave_y)
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
  let scaled_half_w = half_w * dolly
  let scaled_half_h = half_h * dolly
  let left = -scaled_half_w
  let right = scaled_half_w
  let bottom = cy - scaled_half_h
  let top = cy + scaled_half_h
  let (z_lo, z_hi) = view_space_z_range_corners(view_base, extent_xz, wave_y)
  let pull_z = if z_hi > -0.15 { -z_hi - 1.0 } else { 0.0 }
  let view = @m44.Matrix44::translation(pan_x, pan_y, pull_z, 1.0, 0.0).mat_mul(
    view_base,
  )
  let z_min_pulled = z_lo + pull_z
  let far_need = -z_min_pulled + 8.0
  let far_clip = if far_need > 80.0 { far_need } else { 80.0 }
  let proj = @m44.Matrix44::ortho(left, right, bottom, top, 0.1, far_clip)
  (
    view.to_float(),
    proj.to_float(),
    (0.1 : Float),
    Float::from_double(far_clip),
    Float::from_double(aspect),
  )
}

///|
/// Updates the builtin Camera blob from the orbit controller component.
fn push_camera_matrices(
  world : @ecs.World,
  camera : @ecs.EntityId,
  orbit_controller : @ecs.ComponentTypeId,
  count : Int,
) -> Unit {
  let (yaw, pitch, pan_x, pan_y, dolly) = @orbit.orbit_camera_transform(
    world, camera, orbit_controller,
  )
  let (view, proj, near, far, aspect) = camera_matrices(
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
    @orbit.update_orbit_camera_controller_from_mouse_frame(
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
}

///|
let demo_state : @ref.Ref[WasmDemoState?] = @ref.new(None)

///|
/// Implements `create_wasm_demo_state`.
pub fn create_wasm_demo_state() -> Unit {
  let world = @ecs.World::new()
  let count = host_entity_count()
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
  let orbit_controller = @orbit.register_orbit_camera_controller_component(
    world,
  )
  let camera = world.create_entity()
  ignore(
    @orbit.add_orbit_camera_controller(
      world, camera, orbit_controller, 0.0, camera_elevation_rad,
    ),
  )
  push_camera_matrices(world, camera, orbit_controller, count)
  upload_current_camera(world, camera)
  demo_state.val = Some({
    world,
    camera,
    orbit_controller,
    frame: @ref.new(0),
    perf_last_frame_start_ms: @ref.new(-1.0),
  })
}

///|
/// Implements `ecs_mass_cubes_wasm_render_tick`.
pub fn ecs_mass_cubes_wasm_render_tick() -> Unit {
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
      demo_state.frame.val = demo_state.frame.val + 1
      let wave_time = demo_state.frame.val.to_double() * 0.018 * 1.8
      host_write_global_transform_y(wave_time)
      host_begin_input_frame()
      update_orbit_camera_from_host_input(
        demo_state.world,
        demo_state.camera,
        demo_state.orbit_controller,
      )
      push_camera_matrices(
        demo_state.world,
        demo_state.camera,
        demo_state.orbit_controller,
        host_entity_count(),
      )
      upload_current_camera(demo_state.world, demo_state.camera)
      let cpu_ms = host_now_ms() - t_frame_start
      host_render_demo_frame(fps, cpu_ms)
    }
  }
}

///|
/// Implements `main {`.
fn main {
  ()
}
