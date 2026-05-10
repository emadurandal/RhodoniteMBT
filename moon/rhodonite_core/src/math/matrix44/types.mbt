///|
/// 4×4 matrix in **column-major** order (`data[c * 4 + r]` = row `r`, column `c`).
/// `T` is expected to be a numeric field (`Float`, `Double`, ...).
pub(all) struct Matrix4[T] {
  data : FixedArray[T]
}

///|
pub type Matrix4F = Matrix4[Float]

///|
pub type Matrix4D = Matrix4[Double]

///|
pub type Matrix4I = Matrix4[Int]

///|
pub type Matrix4U = Matrix4[UInt]

///|
/// When `T : Show`, prints `Matrix4::new_col_major(...)` in column-major component order.
pub impl[T : Show] Show for Matrix4[T] with output(self, logger) {
  logger.write_string("Matrix4::new_col_major(")
  for i = 0; i < 16; i = i + 1 {
    if i > 0 {
      logger.write_string(", ")
    }
    logger.write_object(self.data[i])
  }
  logger.write_string(")")
}
