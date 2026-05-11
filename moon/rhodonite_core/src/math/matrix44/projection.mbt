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
/// Rotation about **+X** (right-handed). Pass `cos(angle)`, `sin(angle)`, `one`, `zero`.
pub fn[T : Neg] Matrix44::rotation_x_cos_sin(
  cos_angle : T,
  sin_angle : T,
  one : T,
  zero : T,
) -> Matrix44[T] {
  Matrix44::new_col_major(
    one,
    zero,
    zero,
    zero,
    zero,
    cos_angle,
    sin_angle,
    zero,
    zero,
    -sin_angle,
    cos_angle,
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
