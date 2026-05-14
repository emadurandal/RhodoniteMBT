///|
/// Element type for [`Matrix44Ref`]: supports optional GPU transform byte row ([`Float`] only).
pub(open) trait Matrix44RefElem {
  read_std140_mat4_cell(MutArrayView[Byte], Int, Int) -> Self
  write_std140_mat4_cell(MutArrayView[Byte], Int, Int, Self) -> Unit
}

///|
pub impl Matrix44RefElem for Float with read_std140_mat4_cell(bytes, row, col) -> Float {
  match bytes.length() {
    64 =>
      Float::reinterpret_from_uint(
        @writes.get_u32_le_mut_view(bytes, (col * 4 + row) * 4),
      )
    48 =>
      if row == 3 {
        if col == 3 {
          (1.0 : Float)
        } else {
          (0.0 : Float)
        }
      } else {
        Float::reinterpret_from_uint(
          @writes.get_u32_le_mut_view(bytes, (row * 4 + col) * 4),
        )
      }
    _ => abort("Matrix44RefElem: unsupported GPU row length")
  }
}

///|
pub impl Matrix44RefElem for Float with write_std140_mat4_cell(
  bytes,
  row,
  col,
  v,
) -> Unit {
  match bytes.length() {
    64 => @writes.put_f32_le_mut_view(bytes, (col * 4 + row) * 4, v.to_double())
    48 =>
      if row == 3 {
        let expected = if col == 3 { (1.0 : Float) } else { (0.0 : Float) }
        if v != expected {
          abort(
            "Matrix44RefElem: affine 3x4 row cannot store non-affine bottom row",
          )
        }
      } else {
        @writes.put_f32_le_mut_view(bytes, (row * 4 + col) * 4, v.to_double())
      }
    _ => abort("Matrix44RefElem: unsupported GPU row length")
  }
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
