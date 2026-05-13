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
    zero,
    zero,
    zero,
    zero,
    one,
  )
}

///|
/// Orthographic projection (column-major, column vectors: `clip = ortho * vec4(x,y,z,1)`).
/// Maps the axis-aligned box `[left, right] × [bottom, top]` in view **x**/**y**, with
/// **near**/**far** positive distances along **−Z** (near plane at `z = -near`, far at `z = -far`),
/// to WebGPU NDC: **x** and **y** in `[-1, 1]`, **z** in `[0, 1]`.
///
/// XY offsets live in the fourth **column** so `clip.w` stays `1` (homogeneous divide does not
/// distort **x**/**y**). Requires `right != left`.
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
  let tx = (right + left) / (left - right)
  let ty = (top + bottom) / (bottom - top)
  let tz = near / dz
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
    tx,
    ty,
    tz,
    one,
  )
}
