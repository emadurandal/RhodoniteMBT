///|
/// Views one GPU-side std140 `mat4x4<f32>` row (`row.length() == 64`) as a column-major [`Matrix44RefF`].
/// Reads/writes go through the byte row (little-endian `f32` slots); no separate float backing.
pub fn Matrix44RefF::view_std140_mat4x4_le_gpu_row(
  row : MutArrayView[Byte],
) -> Matrix44RefF {
  if row.length() != 64 {
    abort(
      "Matrix44RefF::view_std140_mat4x4_le_gpu_row: expected 64-byte std140 mat4 row",
    )
  }
  Matrix44Ref::{ values: None, std140_row: Some(row) }
}

///|
/// Views one GPU-side affine 3x4 row (`row.length() == 48`) as a column-major [`Matrix44RefF`].
/// The stored rows are `vec4<f32>` values `[m00,m01,m02,m03]`, `[m10,m11,m12,m13]`,
/// `[m20,m21,m22,m23]`; the last matrix row is implicit `[0,0,0,1]`.
pub fn Matrix44RefF::view_affine3x4_le_gpu_row(
  row : MutArrayView[Byte],
) -> Matrix44RefF {
  if row.length() != 48 {
    abort(
      "Matrix44RefF::view_affine3x4_le_gpu_row: expected 48-byte affine 3x4 row",
    )
  }
  Matrix44Ref::{ values: None, std140_row: Some(row) }
}
