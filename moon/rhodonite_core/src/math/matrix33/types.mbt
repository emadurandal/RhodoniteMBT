///|
/// 3×3 matrix in **column-major** order (`data[c * 3 + r]` = row `r`, column `c`).
/// `T` is expected to be a numeric field (`Float`, `Double`, ...).
pub(all) struct Matrix33[T] {
  data : FixedArray[T]
}

///|
pub type Matrix33F = Matrix33[Float]

///|
pub type Matrix33D = Matrix33[Double]

///|
pub type Matrix33I = Matrix33[Int]

///|
pub type Matrix33U = Matrix33[UInt]

///|
/// When `T : Show`, prints `Matrix33::new_col_major(...)` in column-major component order.
pub impl[T : Show] Show for Matrix33[T] with output(self, logger) {
  logger.write_string("Matrix33::new_col_major(")
  for i = 0; i < 9; i = i + 1 {
    if i > 0 {
      logger.write_string(", ")
    }
    logger.write_object(self.data[i])
  }
  logger.write_string(")")
}
