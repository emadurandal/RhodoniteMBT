///|
/// 4×4 matrix in **column-major** order (`data[c * 4 + r]` = row `r`, column `c`).
/// `T` is expected to be a numeric field (`Float`, `Double`, ...).
pub(all) struct Matrix44[T] {
  data : FixedArray[T]
}

///|
pub type Matrix44F = Matrix44[Float]

///|
pub type Matrix44D = Matrix44[Double]

///|
pub type Matrix44I = Matrix44[Int]

///|
pub type Matrix44U = Matrix44[UInt]

///|
/// When `T : Show`, prints `Matrix44::new_col_major(...)` in column-major component order.
pub impl[T : Show] Show for Matrix44[T] with output(self, logger) {
  logger.write_string("Matrix44::new_col_major(")
  for i = 0; i < 16; i = i + 1 {
    if i > 0 {
      logger.write_string(", ")
    }
    logger.write_object(self.data[i])
  }
  logger.write_string(")")
}
