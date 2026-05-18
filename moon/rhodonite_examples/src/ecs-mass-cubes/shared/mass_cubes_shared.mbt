///|
#cfg(target="native")
extern "C" fn rhodonite_mass_cubes_entity_count_or_default(
  default_count : Int,
) -> Int = "rhodonite_mass_cubes_entity_count_or_default"

///|
/// Returns the root entity count used by the mass-cubes samples.
///
/// On native, override with `RHODONITE_MASS_CUBES_ENTITY_COUNT` (e.g. `50000`) when
/// debugging startup crashes or low-memory machines.
#cfg(target="native")
pub fn entity_count() -> Int {
  rhodonite_mass_cubes_entity_count_or_default(800_000)
}

///|
/// Returns the root entity count used by the mass-cubes samples.
#cfg(not(target="native"))
pub fn entity_count() -> Int {
  800_000
}

///|
/// Returns the canvas width used by the mass-cubes samples.
pub fn canvas_width() -> UInt {
  800U
}

///|
/// Returns the canvas height used by the mass-cubes samples.
pub fn canvas_height() -> UInt {
  600U
}

///|
/// Returns the local vertex byte stride for the cube mesh.
pub fn vertex_stride_local() -> Int {
  12
}

///|
/// Returns the per-instance byte stride for transform refs and color.
pub fn instance_stride() -> Int {
  24
}

///|
/// Returns the vertex count for the cube corner mesh.
pub fn verts_per_cube() -> Int {
  8
}

///|
/// Returns the u16 index count for the cube mesh.
pub fn index_u16_count() -> Int {
  36
}

///|
/// Returns the initial orbit camera pitch in radians.
pub fn camera_elevation_rad() -> Double {
  0.42
}

///|
/// Returns the spacing between mass-cubes grid cells.
pub fn grid_spacing() -> Double {
  0.14
}

///|
/// Returns the cube mesh scale used by transform writers.
pub fn cube_scale() -> Float {
  0.055
}

///|
/// Returns the minimum on-screen XZ grid spacing kept by the MassCubes auto-fit camera.
fn min_interactive_grid_pitch_px() -> Double {
  0.56
}

///|
/// Returns the smallest `s` with `s * s >= n` for a roughly square XZ grid.
pub fn grid_side_len(n : Int) -> Int {
  let mut s = 1
  while s * s < n {
    s = s + 1
  }
  s
}

///|
/// Returns the world-space XZ grid position for a mass-cubes entity index.
pub fn grid_xz_for_index(idx : Int, per_side : Int) -> (Float, Float) {
  let ix = idx % per_side
  let iz = idx / per_side
  let half = (per_side - 1).to_double() * 0.5
  let fx = ix.to_double() - half
  let fz = iz.to_double() - half
  (
    Float::from_double(fx * grid_spacing()),
    Float::from_double(fz * grid_spacing()),
  )
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
/// Builds view and projection matrices for the mass-cubes orthographic camera.
pub fn camera_matrices(
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
  let extent_xz = half * grid_spacing()
  let wave = 0.12
  let margin = cube_scale().to_double() * 2.5
  let wave_y = wave + cube_scale().to_double() * 1.1
  let (y_lo, y_hi) = view_space_y_range_corners(view_base, extent_xz, wave_y)
  let cy = (y_lo + y_hi) * 0.5
  let hy = (y_hi - y_lo) * 0.5 + margin
  let hx = extent_xz + margin
  let aspect = canvas_width().to_double() / canvas_height().to_double()
  let mut half_w = hx
  let mut half_h = hy
  if half_w / half_h < aspect {
    half_w = half_h * aspect
  } else {
    half_h = half_w / aspect
  }
  let max_half_w_for_grid_pitch = grid_spacing() *
    canvas_width().to_double() /
    (2.0 * min_interactive_grid_pitch_px())
  if half_w > max_half_w_for_grid_pitch {
    half_w = max_half_w_for_grid_pitch
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
