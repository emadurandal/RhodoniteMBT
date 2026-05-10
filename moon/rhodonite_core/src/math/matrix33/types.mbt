///|
/// 3×3 matrix in **column-major** order (`data[c * 3 + r]` = row `r`, column `c`).
/// `T` is expected to be a numeric field (`Float`, `Double`, ...).
pub(all) struct Matrix3[T] {
  data : FixedArray[T]
}

///|
pub type Matrix3F = Matrix3[Float]

///|
pub type Matrix3D = Matrix3[Double]

///|
pub type Matrix3I = Matrix3[Int]

///|
pub type Matrix3U = Matrix3[UInt]

///|
/// When `T : Show`, prints `Matrix3::new_col_major(...)` in column-major component order.
pub impl[T : Show] Show for Matrix3[T] with output(self, logger) {
  logger.write_string("Matrix3::new_col_major(")
  for i = 0; i < 9; i = i + 1 {
    if i > 0 {
      logger.write_string(", ")
    }
    logger.write_object(self.data[i])
  }
  logger.write_string(")")
}
