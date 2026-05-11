///|
/// Homogeneous translation (column-major). Pass `one = 1` and `zero = 0` in `T`.
pub fn[T] Matrix44::translation(
  tx : T,
  ty : T,
  tz : T,
  one : T,
  zero : T,
) -> Matrix44[T] {
  Matrix44::new_col_major(
    one, zero, zero, zero, zero, one, zero, zero, zero, zero, one, zero, tx, ty,
    tz, one,
  )
}

///|
/// Rotation about **+X** (radians, right-handed). Returns [`Matrix44D`] (column-major).
pub fn Matrix44::rotation_x(angle : Double) -> Matrix44D {
  let c = @math.cos(angle)
  let s = @math.sin(angle)
  let one = (1.0 : Double)
  let zero = (0.0 : Double)
  Matrix44::new_col_major(
    one,
    zero,
    zero,
    zero,
    zero,
    c,
    s,
    zero,
    zero,
    -s,
    c,
    zero,
    zero,
    zero,
    zero,
    one,
  )
}

///|
/// Rotation about **+Y** (radians, right-handed). Returns [`Matrix44D`] (column-major).
pub fn Matrix44::rotation_y(angle : Double) -> Matrix44D {
  let c = @math.cos(angle)
  let s = @math.sin(angle)
  let one = (1.0 : Double)
  let zero = (0.0 : Double)
  Matrix44::new_col_major(
    c,
    zero,
    -s,
    zero,
    zero,
    one,
    zero,
    zero,
    s,
    zero,
    c,
    zero,
    zero,
    zero,
    zero,
    one,
  )
}

///|
/// Rotation about **+Z** (radians, right-handed). Returns [`Matrix44D`] (column-major).
pub fn Matrix44::rotation_z(angle : Double) -> Matrix44D {
  let c = @math.cos(angle)
  let s = @math.sin(angle)
  let one = (1.0 : Double)
  let zero = (0.0 : Double)
  Matrix44::new_col_major(
    c,
    -s,
    zero,
    zero,
    s,
    c,
    zero,
    zero,
    zero,
    zero,
    one,
    zero,
    zero,
    zero,
    zero,
    one,
  )
}

///|
/// Orthographic projection (column-major) mapping the frustum to NDC:
/// **x** and **y** in `[-1, 1]`, **z** in `[0, 1]` (WebGPU depth).
/// `near` and `far` are depths along **negative Z** (larger magnitude = farther).
/// Requires `right != left` (unity `one` is derived as `(right - left) / (right - left)`).
pub fn[T : Add + Sub + Div] Matrix44::ortho(
  left : T,
  right : T,
  bottom : T,
  top : T,
  near : T,
  far : T,
) -> Matrix44[T] {
  let dx = right - left
  let dy = top - bottom
  let dz = near - far
  let zero = right - right
  let one = dx / dx
  let two = one + one
  Matrix44::new_col_major(
    two / dx,
    zero,
    zero,
    zero,
    zero,
    two / dy,
    zero,
    zero,
    zero,
    zero,
    one / dz,
    zero,
    (right + left) / (left - right),
    (top + bottom) / (bottom - top),
    near / dz,
    one,
  )
}
