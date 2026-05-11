///|
pub fn[T] Matrix33::new_col_major(
  m00 : T,
  m10 : T,
  m20 : T,
  m01 : T,
  m11 : T,
  m21 : T,
  m02 : T,
  m12 : T,
  m22 : T,
) -> Matrix33[T] {
  Matrix33::{
    data: ([m00, m10, m20, m01, m11, m21, m02, m12, m22] : FixedArray[T]),
  }
}

///|
pub fn[T] Matrix33::from_cols(
  c0 : @v3.Vector3[T],
  c1 : @v3.Vector3[T],
  c2 : @v3.Vector3[T],
) -> Matrix33[T] {
  Matrix33::new_col_major(
    c0.x(),
    c0.y(),
    c0.z(),
    c1.x(),
    c1.y(),
    c1.z(),
    c2.x(),
    c2.y(),
    c2.z(),
  )
}

///|
pub fn[T : Default] Matrix33::zero() -> Matrix33[T] {
  let z = T::default()
  Matrix33::new_col_major(z, z, z, z, z, z, z, z, z)
}

///|
pub fn[T] Matrix33::identity_with(one : T, zero : T) -> Matrix33[T] {
  Matrix33::new_col_major(one, zero, zero, zero, one, zero, zero, zero, one)
}

///|
pub fn Matrix33F::identity() -> Matrix33F {
  Matrix33::identity_with((1.0 : Float), (0.0 : Float))
}

///|
pub fn[T] Matrix33::at(self : Matrix33[T], row : Int, col : Int) -> T {
  self.data[col * 3 + row]
}

///|
/// Returns the inner `FixedArray` unchanged (length 9, column-major).
pub fn[T] Matrix33::data(self : Matrix33[T]) -> FixedArray[T] {
  self.data
}

///|
pub fn[T : Mul] Matrix33::scale(self : Matrix33[T], s : T) -> Matrix33[T] {
  Matrix33::{
    data: (
      [
        self.data[0] * s,
        self.data[1] * s,
        self.data[2] * s,
        self.data[3] * s,
        self.data[4] * s,
        self.data[5] * s,
        self.data[6] * s,
        self.data[7] * s,
        self.data[8] * s,
      ] : FixedArray[T]),
  }
}

///|
pub fn[T : Div] Matrix33::div_scalar(self : Matrix33[T], s : T) -> Matrix33[T] {
  Matrix33::{
    data: (
      [
        self.data[0] / s,
        self.data[1] / s,
        self.data[2] / s,
        self.data[3] / s,
        self.data[4] / s,
        self.data[5] / s,
        self.data[6] / s,
        self.data[7] / s,
        self.data[8] / s,
      ] : FixedArray[T]),
  }
}

///|
pub fn[T] Matrix33::transpose(self : Matrix33[T]) -> Matrix33[T] {
  Matrix33::from_cols(
    @v3.Vector3::new(self.at(0, 0), self.at(0, 1), self.at(0, 2)),
    @v3.Vector3::new(self.at(1, 0), self.at(1, 1), self.at(1, 2)),
    @v3.Vector3::new(self.at(2, 0), self.at(2, 1), self.at(2, 2)),
  )
}

///|
/// Matrix product `self * other` (standard linear algebra).
pub fn[T : Mul + Add] Matrix33::mat_mul(
  self : Matrix33[T],
  other : Matrix33[T],
) -> Matrix33[T] {
  Matrix33::from_cols(
    self.mul_vec(
      @v3.Vector3::new(other.at(0, 0), other.at(1, 0), other.at(2, 0)),
    ),
    self.mul_vec(
      @v3.Vector3::new(other.at(0, 1), other.at(1, 1), other.at(2, 1)),
    ),
    self.mul_vec(
      @v3.Vector3::new(other.at(0, 2), other.at(1, 2), other.at(2, 2)),
    ),
  )
}

///|
/// Column vector multiply: `self * v` (treats `v` as a column 3-vector).
pub fn[T : Mul + Add] Matrix33::mul_vec(
  self : Matrix33[T],
  v : @v3.Vector3[T],
) -> @v3.Vector3[T] {
  let x = v.x()
  let y = v.y()
  let z = v.z()
  @v3.Vector3::new(
    self.at(0, 0) * x + self.at(0, 1) * y + self.at(0, 2) * z,
    self.at(1, 0) * x + self.at(1, 1) * y + self.at(1, 2) * z,
    self.at(2, 0) * x + self.at(2, 1) * y + self.at(2, 2) * z,
  )
}

///|
pub fn[T : Mul + Add + Sub] Matrix33::determinant(self : Matrix33[T]) -> T {
  let a = self.at(0, 0)
  let b = self.at(0, 1)
  let c = self.at(0, 2)
  let d = self.at(1, 0)
  let e = self.at(1, 1)
  let f = self.at(1, 2)
  let g = self.at(2, 0)
  let h = self.at(2, 1)
  let i = self.at(2, 2)
  a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
}

///|
/// Returns `None` when the determinant is exactly `T::default()` (typically 0).
pub fn[T : Mul + Add + Sub + Div + Eq + Default] Matrix33::inverse(
  self : Matrix33[T],
) -> Matrix33[T]? {
  let det = self.determinant()
  if det == T::default() {
    None
  } else {
    let a = self.at(0, 0)
    let b = self.at(0, 1)
    let c = self.at(0, 2)
    let d = self.at(1, 0)
    let e = self.at(1, 1)
    let f = self.at(1, 2)
    let g = self.at(2, 0)
    let h = self.at(2, 1)
    let i = self.at(2, 2)
    let inv00 = (e * i - f * h) / det
    let inv01 = (c * h - b * i) / det
    let inv02 = (b * f - c * e) / det
    let inv10 = (f * g - d * i) / det
    let inv11 = (a * i - c * g) / det
    let inv12 = (c * d - a * f) / det
    let inv20 = (d * h - e * g) / det
    let inv21 = (b * g - a * h) / det
    let inv22 = (a * e - b * d) / det
    Some(
      Matrix33::new_col_major(
        inv00, inv10, inv20, inv01, inv11, inv21, inv02, inv12, inv22,
      ),
    )
  }
}
