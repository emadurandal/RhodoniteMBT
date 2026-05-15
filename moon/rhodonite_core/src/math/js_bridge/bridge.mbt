///| Wrapper so `Vector3F` can be exported to JS as-is for TypeScript / Vitest.

///|
/// Implements `v3f_new`.
pub fn v3f_new(x : Float, y : Float, z : Float) -> @v3.Vector3F {
  @v3.Vector3::new(x, y, z)
}

///|
/// Implements `v3f_zero`.
pub fn v3f_zero() -> @v3.Vector3F {
  @v3.Vector3::zero()
}

///|
/// Implements `v3f_x`.
pub fn v3f_x(v : @v3.Vector3F) -> Float {
  v.x()
}

///|
/// Implements `v3f_y`.
pub fn v3f_y(v : @v3.Vector3F) -> Float {
  v.y()
}

///|
/// Implements `v3f_z`.
pub fn v3f_z(v : @v3.Vector3F) -> Float {
  v.z()
}

///|
/// Implements `v3f_data`.
pub fn v3f_data(v : @v3.Vector3F) -> FixedArray[Float] {
  v.data()
}

///|
/// Implements `v3f_add`.
pub fn v3f_add(a : @v3.Vector3F, b : @v3.Vector3F) -> @v3.Vector3F {
  a + b
}

///|
/// Implements `v3f_sub`.
pub fn v3f_sub(a : @v3.Vector3F, b : @v3.Vector3F) -> @v3.Vector3F {
  a - b
}

///|
/// Implements `v3f_neg`.
pub fn v3f_neg(v : @v3.Vector3F) -> @v3.Vector3F {
  -v
}

///|
/// Implements `v3f_mul`.
pub fn v3f_mul(a : @v3.Vector3F, b : @v3.Vector3F) -> @v3.Vector3F {
  a * b
}

///|
/// Implements `v3f_scale`.
pub fn v3f_scale(v : @v3.Vector3F, s : Float) -> @v3.Vector3F {
  v.scale(s)
}

///|
/// Implements `v3f_div_scalar`.
pub fn v3f_div_scalar(v : @v3.Vector3F, s : Float) -> @v3.Vector3F {
  v.div_scalar(s)
}

///|
/// Implements `v3f_eq`.
pub fn v3f_eq(a : @v3.Vector3F, b : @v3.Vector3F) -> Bool {
  a == b
}

///|
/// Implements `v3f_to_string`.
pub fn v3f_to_string(v : @v3.Vector3F) -> String {
  v.to_string()
}

///| Wrapper so `Vector4F` can be exported to JS as-is for TypeScript / Vitest.

///|
/// Implements `v4f_new`.
pub fn v4f_new(x : Float, y : Float, z : Float, w : Float) -> @v4.Vector4F {
  @v4.Vector4::new(x, y, z, w)
}

///|
/// Implements `v4f_zero`.
pub fn v4f_zero() -> @v4.Vector4F {
  @v4.Vector4::zero()
}

///|
/// Implements `v4f_x`.
pub fn v4f_x(v : @v4.Vector4F) -> Float {
  v.x()
}

///|
/// Implements `v4f_y`.
pub fn v4f_y(v : @v4.Vector4F) -> Float {
  v.y()
}

///|
/// Implements `v4f_z`.
pub fn v4f_z(v : @v4.Vector4F) -> Float {
  v.z()
}

///|
/// Implements `v4f_w`.
pub fn v4f_w(v : @v4.Vector4F) -> Float {
  v.w()
}

///|
/// Implements `v4f_data`.
pub fn v4f_data(v : @v4.Vector4F) -> FixedArray[Float] {
  v.data()
}

///|
/// Implements `v4f_add`.
pub fn v4f_add(a : @v4.Vector4F, b : @v4.Vector4F) -> @v4.Vector4F {
  a + b
}

///|
/// Implements `v4f_sub`.
pub fn v4f_sub(a : @v4.Vector4F, b : @v4.Vector4F) -> @v4.Vector4F {
  a - b
}

///|
/// Implements `v4f_neg`.
pub fn v4f_neg(v : @v4.Vector4F) -> @v4.Vector4F {
  -v
}

///|
/// Implements `v4f_mul`.
pub fn v4f_mul(a : @v4.Vector4F, b : @v4.Vector4F) -> @v4.Vector4F {
  a * b
}

///|
/// Implements `v4f_scale`.
pub fn v4f_scale(v : @v4.Vector4F, s : Float) -> @v4.Vector4F {
  v.scale(s)
}

///|
/// Implements `v4f_div_scalar`.
pub fn v4f_div_scalar(v : @v4.Vector4F, s : Float) -> @v4.Vector4F {
  v.div_scalar(s)
}

///|
/// Implements `v4f_eq`.
pub fn v4f_eq(a : @v4.Vector4F, b : @v4.Vector4F) -> Bool {
  a == b
}

///|
/// Implements `v4f_to_string`.
pub fn v4f_to_string(v : @v4.Vector4F) -> String {
  v.to_string()
}

///| `Matrix33F` / `Matrix44F` for JS (column-major `data`, length 9 / 16).

///|
/// Implements `m3f_new_col_major`.
pub fn m3f_new_col_major(
  m00 : Float,
  m10 : Float,
  m20 : Float,
  m01 : Float,
  m11 : Float,
  m21 : Float,
  m02 : Float,
  m12 : Float,
  m22 : Float,
) -> @m33.Matrix33F {
  @m33.Matrix33::new_col_major(m00, m10, m20, m01, m11, m21, m02, m12, m22)
}

///|
/// Implements `m3f_zero`.
pub fn m3f_zero() -> @m33.Matrix33F {
  @m33.Matrix33::zero()
}

///|
/// Implements `m3f_identity`.
pub fn m3f_identity() -> @m33.Matrix33F {
  @m33.Matrix33F::identity()
}

///|
/// Implements `m3f_data`.
pub fn m3f_data(m : @m33.Matrix33F) -> FixedArray[Float] {
  m.data()
}

///|
/// Implements `m3f_at`.
pub fn m3f_at(m : @m33.Matrix33F, row : Int, col : Int) -> Float {
  m.at(row, col)
}

///|
/// Implements `m3f_transpose`.
pub fn m3f_transpose(m : @m33.Matrix33F) -> @m33.Matrix33F {
  m.transpose()
}

///|
/// Implements `m3f_mat_mul`.
pub fn m3f_mat_mul(a : @m33.Matrix33F, b : @m33.Matrix33F) -> @m33.Matrix33F {
  a.mat_mul(b)
}

///|
/// Implements `m3f_mul_vec`.
pub fn m3f_mul_vec(m : @m33.Matrix33F, v : @v3.Vector3F) -> @v3.Vector3F {
  m.mul_vec(v)
}

///|
/// Implements `m3f_scale`.
pub fn m3f_scale(m : @m33.Matrix33F, s : Float) -> @m33.Matrix33F {
  m.scale(s)
}

///|
/// Implements `m3f_div_scalar`.
pub fn m3f_div_scalar(m : @m33.Matrix33F, s : Float) -> @m33.Matrix33F {
  m.div_scalar(s)
}

///|
/// Implements `m3f_det`.
pub fn m3f_det(m : @m33.Matrix33F) -> Float {
  m.determinant()
}

///|
/// Implements `m3f_inverse`.
pub fn m3f_inverse(m : @m33.Matrix33F) -> @m33.Matrix33F? {
  m.inverse()
}

///|
/// Implements `m3f_add`.
pub fn m3f_add(a : @m33.Matrix33F, b : @m33.Matrix33F) -> @m33.Matrix33F {
  a + b
}

///|
/// Implements `m3f_sub`.
pub fn m3f_sub(a : @m33.Matrix33F, b : @m33.Matrix33F) -> @m33.Matrix33F {
  a - b
}

///|
/// Implements `m3f_neg`.
pub fn m3f_neg(m : @m33.Matrix33F) -> @m33.Matrix33F {
  -m
}

///|
/// Implements `m3f_mul`.
pub fn m3f_mul(a : @m33.Matrix33F, b : @m33.Matrix33F) -> @m33.Matrix33F {
  a * b
}

///|
/// Implements `m3f_eq`.
pub fn m3f_eq(a : @m33.Matrix33F, b : @m33.Matrix33F) -> Bool {
  a == b
}

///|
/// Implements `m3f_to_string`.
pub fn m3f_to_string(m : @m33.Matrix33F) -> String {
  m.to_string()
}

///|
/// Implements `m4f_new_col_major`.
pub fn m4f_new_col_major(
  m00 : Float,
  m10 : Float,
  m20 : Float,
  m30 : Float,
  m01 : Float,
  m11 : Float,
  m21 : Float,
  m31 : Float,
  m02 : Float,
  m12 : Float,
  m22 : Float,
  m32 : Float,
  m03 : Float,
  m13 : Float,
  m23 : Float,
  m33 : Float,
) -> @m44.Matrix44F {
  @m44.Matrix44::new_col_major(
    m00, m10, m20, m30, m01, m11, m21, m31, m02, m12, m22, m32, m03, m13, m23, m33,
  )
}

///|
/// Implements `m4f_zero`.
pub fn m4f_zero() -> @m44.Matrix44F {
  @m44.Matrix44::zero()
}

///|
/// Implements `m4f_identity`.
pub fn m4f_identity() -> @m44.Matrix44F {
  @m44.Matrix44F::identity()
}

///|
/// Implements `matrix44d_to_matrix44f`.
fn matrix44d_to_matrix44f(m : @m44.Matrix44D) -> @m44.Matrix44F {
  let src = m.data()
  let dst : FixedArray[Float] = FixedArray::make(16, (0.0 : Float))
  for i = 0; i < 16; i = i + 1 {
    dst[i] = Float::from_double(src[i])
  }
  @m44.Matrix44::{ data: dst }
}

///|
/// Implements `m4f_rotation_x`.
pub fn m4f_rotation_x(angle : Float) -> @m44.Matrix44F {
  matrix44d_to_matrix44f(@m44.Matrix44::rotation_x(angle.to_double()))
}

///|
/// Implements `m4f_rotation_y`.
pub fn m4f_rotation_y(angle : Float) -> @m44.Matrix44F {
  matrix44d_to_matrix44f(@m44.Matrix44::rotation_y(angle.to_double()))
}

///|
/// Implements `m4f_rotation_z`.
pub fn m4f_rotation_z(angle : Float) -> @m44.Matrix44F {
  matrix44d_to_matrix44f(@m44.Matrix44::rotation_z(angle.to_double()))
}

///|
/// Implements `m4f_translation`.
pub fn m4f_translation(tx : Float, ty : Float, tz : Float) -> @m44.Matrix44F {
  @m44.Matrix44::translation(tx, ty, tz, (1.0 : Float), (0.0 : Float))
}

///|
/// Implements `m4f_ortho`.
pub fn m4f_ortho(
  left : Float,
  right : Float,
  bottom : Float,
  top : Float,
  near : Float,
  far : Float,
) -> @m44.Matrix44F {
  @m44.Matrix44::ortho(left, right, bottom, top, near, far)
}

///|
/// Implements `m4f_data`.
pub fn m4f_data(m : @m44.Matrix44F) -> FixedArray[Float] {
  m.data()
}

///|
/// Implements `m4f_at`.
pub fn m4f_at(m : @m44.Matrix44F, row : Int, col : Int) -> Float {
  m.at(row, col)
}

///|
/// Implements `m4f_transpose`.
pub fn m4f_transpose(m : @m44.Matrix44F) -> @m44.Matrix44F {
  m.transpose()
}

///|
/// Implements `m4f_mat_mul`.
pub fn m4f_mat_mul(a : @m44.Matrix44F, b : @m44.Matrix44F) -> @m44.Matrix44F {
  a.mat_mul(b)
}

///|
/// Implements `m4f_mul_vec4`.
pub fn m4f_mul_vec4(m : @m44.Matrix44F, v : @v4.Vector4F) -> @v4.Vector4F {
  m.mul_vec4(v)
}

///|
/// Implements `m4f_transform_point`.
pub fn m4f_transform_point(
  m : @m44.Matrix44F,
  p : @v3.Vector3F,
) -> @v3.Vector3F {
  m.transform_point(p)
}

///|
/// Implements `m4f_scale`.
pub fn m4f_scale(m : @m44.Matrix44F, s : Float) -> @m44.Matrix44F {
  m.scale(s)
}

///|
/// Implements `m4f_div_scalar`.
pub fn m4f_div_scalar(m : @m44.Matrix44F, s : Float) -> @m44.Matrix44F {
  m.div_scalar(s)
}

///|
/// Implements `m4f_det`.
pub fn m4f_det(m : @m44.Matrix44F) -> Float {
  m.determinant()
}

///|
/// Implements `m4f_inverse`.
pub fn m4f_inverse(m : @m44.Matrix44F) -> @m44.Matrix44F? {
  m.inverse()
}

///|
/// Implements `m4f_add`.
pub fn m4f_add(a : @m44.Matrix44F, b : @m44.Matrix44F) -> @m44.Matrix44F {
  a + b
}

///|
/// Implements `m4f_sub`.
pub fn m4f_sub(a : @m44.Matrix44F, b : @m44.Matrix44F) -> @m44.Matrix44F {
  a - b
}

///|
/// Implements `m4f_neg`.
pub fn m4f_neg(m : @m44.Matrix44F) -> @m44.Matrix44F {
  -m
}

///|
/// Implements `m4f_mul`.
pub fn m4f_mul(a : @m44.Matrix44F, b : @m44.Matrix44F) -> @m44.Matrix44F {
  a * b
}

///|
/// Implements `m4f_eq`.
pub fn m4f_eq(a : @m44.Matrix44F, b : @m44.Matrix44F) -> Bool {
  a == b
}

///|
/// Implements `m4f_to_string`.
pub fn m4f_to_string(m : @m44.Matrix44F) -> String {
  m.to_string()
}

///|
/// Implements `main {`.
fn main {
  ()
}
