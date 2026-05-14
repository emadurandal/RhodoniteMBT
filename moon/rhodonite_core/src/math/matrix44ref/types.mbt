///|
/// Borrowed 4×4 matrix in **column-major** order (`values[col * 4 + row]`). The view
/// must hold **16** elements of type `T` (`Float`, `Double`, ...), **or** (Float only) one
/// GPU transform row via [`std140_row`]. GPU rows may be the legacy 64-byte std140
/// `mat4x4<f32>` layout or the compact 48-byte affine 3x4 layout.
pub(all) struct Matrix44Ref[T] {
  values : MutArrayView[T]?
  /// When [`Some`], this is one GPU transform row; [`values`] must be [`None`] and only
  /// [`Matrix44Ref[Float]`] / [`Matrix44RefF`] uses this path.
  std140_row : MutArrayView[Byte]?
}

///|
pub type Matrix44RefF = Matrix44Ref[Float]

///|
pub type Matrix44RefD = Matrix44Ref[Double]

///|
pub type Matrix44RefI = Matrix44Ref[Int]

///|
pub type Matrix44RefU = Matrix44Ref[UInt]

///|
pub fn[T] Matrix44Ref::from_mut_view(data : MutArrayView[T]) -> Matrix44Ref[T] {
  guard data.length() == 16 else {
    abort("Matrix44Ref::from_mut_view: expected length 16")
  }
  Matrix44Ref::{ values: Some(data), std140_row: None }
}

///|
/// Copies column-major components into an owned [`@m44.Matrix44`].
pub fn[T : Matrix44RefElem] Matrix44Ref::to_matrix44(
  self : Matrix44Ref[T],
) -> @m44.Matrix44[T] {
  @m44.Matrix44::new_col_major(
    self.at(0, 0),
    self.at(1, 0),
    self.at(2, 0),
    self.at(3, 0),
    self.at(0, 1),
    self.at(1, 1),
    self.at(2, 1),
    self.at(3, 1),
    self.at(0, 2),
    self.at(1, 2),
    self.at(2, 2),
    self.at(3, 2),
    self.at(0, 3),
    self.at(1, 3),
    self.at(2, 3),
    self.at(3, 3),
  )
}

///|
/// When `T : Show`, prints `Matrix44::new_col_major(...)` in column-major component order
/// (same layout as [`@m44.Matrix44`]'s [`Show`]).
pub impl[T : Show + Matrix44RefElem] Show for Matrix44Ref[T] with output(
  self,
  logger,
) {
  logger.write_string("Matrix44::new_col_major(")
  for i = 0; i < 16; i = i + 1 {
    if i > 0 {
      logger.write_string(", ")
    }
    let col = i / 4
    let row = i % 4
    logger.write_object(self.at(row, col))
  }
  logger.write_string(")")
}
