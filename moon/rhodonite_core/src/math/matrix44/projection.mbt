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
/// OpenGL-style orthographic projection to NDC `[-1,1]^3`. Pass `one = 1`, `zero = 0` in `T`.
pub fn[T : Add + Sub + Div + Neg] Matrix44::ortho_gl(
  left : T,
  right : T,
  bottom : T,
  top : T,
  near : T,
  far : T,
  one : T,
  zero : T,
) -> Matrix44[T] {
  let two = one + one
  Matrix44::new_col_major(
    two / (right - left),
    zero,
    zero,
    zero,
    zero,
    two / (top - bottom),
    zero,
    zero,
    zero,
    zero,
    -two / (far - near),
    zero,
    -(right + left) / (right - left),
    -(top + bottom) / (top - bottom),
    -(far + near) / (far - near),
    one,
  )
}

///|
/// Maps clip **Z** from OpenGL NDC (`z ∈ [-1, 1]`) to WebGPU (`z ∈ [0, 1]`).
/// Pass `one = 1`, `zero = 0` in `T`.
pub fn[T : Add + Div] Matrix44::ndc_depth_gl_to_webgpu(
  one : T,
  zero : T,
) -> Matrix44[T] {
  let two = one + one
  let half = one / two
  Matrix44::new_col_major(
    one, zero, zero, zero, zero, one, zero, zero, zero, zero, half, zero, zero, zero,
    half, one,
  )
}
