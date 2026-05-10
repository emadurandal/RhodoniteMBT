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
