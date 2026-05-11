///|
/// Element type for [`Matrix44Ref`]: supports optional std140 GPU `mat4x4<f32>` byte row ([`Float`] only).
pub(open) trait Matrix44RefElem {
  read_std140_mat4_cell(MutArrayView[Byte], Int, Int) -> Self
  write_std140_mat4_cell(MutArrayView[Byte], Int, Int, Self) -> Unit
}

///|
pub impl Matrix44RefElem for Float with read_std140_mat4_cell(bytes, row, col) -> Float {
  Float::reinterpret_from_uint(
    @writes.get_u32_le_mut_view(bytes, (col * 4 + row) * 4),
  )
}

///|
pub impl Matrix44RefElem for Float with write_std140_mat4_cell(
  bytes,
  row,
  col,
  v,
) -> Unit {
  @writes.put_f32_le_mut_view(bytes, (col * 4 + row) * 4, v.to_double())
}

///|
pub impl Matrix44RefElem for Double with read_std140_mat4_cell(
  _bytes,
  _row,
  _col,
) -> Double {
  abort("Matrix44RefElem: std140 GPU row is only used with Matrix44Ref[Float]")
}

///|
pub impl Matrix44RefElem for Double with write_std140_mat4_cell(
  _bytes,
  _row,
  _col,
  _v,
) -> Unit {
  abort("Matrix44RefElem: std140 GPU row is only used with Matrix44Ref[Float]")
}

///|
pub impl Matrix44RefElem for Int with read_std140_mat4_cell(_bytes, _row, _col) -> Int {
  abort("Matrix44RefElem: std140 GPU row is only used with Matrix44Ref[Float]")
}

///|
pub impl Matrix44RefElem for Int with write_std140_mat4_cell(
  _bytes,
  _row,
  _col,
  _v,
) -> Unit {
  abort("Matrix44RefElem: std140 GPU row is only used with Matrix44Ref[Float]")
}

///|
pub impl Matrix44RefElem for UInt with read_std140_mat4_cell(_bytes, _row, _col) -> UInt {
  abort("Matrix44RefElem: std140 GPU row is only used with Matrix44Ref[Float]")
}

///|
pub impl Matrix44RefElem for UInt with write_std140_mat4_cell(
  _bytes,
  _row,
  _col,
  _v,
) -> Unit {
  abort("Matrix44RefElem: std140 GPU row is only used with Matrix44Ref[Float]")
}
