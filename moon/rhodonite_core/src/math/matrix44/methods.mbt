///|
fn rows_exc(skip : Int) -> (Int, Int, Int) {
  match skip {
    0 => (1, 2, 3)
    1 => (0, 2, 3)
    2 => (0, 1, 3)
    3 => (0, 1, 2)
    _ => abort("rows_exc: invalid skip")
  }
}

///|
fn cols_exc(skip : Int) -> (Int, Int, Int) {
  rows_exc(skip)
}

///|
fn[T : Mul + Add + Sub] det3_values(
  a00 : T,
  a10 : T,
  a20 : T,
  a01 : T,
  a11 : T,
  a21 : T,
  a02 : T,
  a12 : T,
  a22 : T,
) -> T {
  a00 * (a11 * a22 - a12 * a21) -
  a01 * (a10 * a22 - a12 * a20) +
  a02 * (a10 * a21 - a11 * a20)
}

///|
fn[T : Mul + Add + Sub] mat4_minor(
  m : Matrix44[T],
  skip_r : Int,
  skip_c : Int,
) -> T {
  let (r0, r1, r2) = rows_exc(skip_r)
  let (c0, c1, c2) = cols_exc(skip_c)
  det3_values(
    m.at(r0, c0),
    m.at(r1, c0),
    m.at(r2, c0),
    m.at(r0, c1),
    m.at(r1, c1),
    m.at(r2, c1),
    m.at(r0, c2),
    m.at(r1, c2),
    m.at(r2, c2),
  )
}

///|
fn[T : Mul + Add + Sub + Neg] matrix4_cofactor(
  m : Matrix44[T],
  r : Int,
  c : Int,
) -> T {
  let mi = mat4_minor(m, r, c)
  if (r + c) % 2 == 0 {
    mi
  } else {
    -mi
  }
}

///|
pub fn[T] Matrix44::new_col_major(
  m00 : T,
  m10 : T,
  m20 : T,
  m30 : T,
  m01 : T,
  m11 : T,
  m21 : T,
  m31 : T,
  m02 : T,
  m12 : T,
  m22 : T,
  m32 : T,
  m03 : T,
  m13 : T,
  m23 : T,
  m33 : T,
) -> Matrix44[T] {
  Matrix44::{
    data: (
      [
        m00, m10, m20, m30, m01, m11, m21, m31, m02, m12, m22, m32, m03, m13, m23,
        m33,
      ] : FixedArray[T]),
  }
}

///|
pub fn[T] Matrix44::from_cols(
  c0 : @v4.Vector4[T],
  c1 : @v4.Vector4[T],
  c2 : @v4.Vector4[T],
  c3 : @v4.Vector4[T],
) -> Matrix44[T] {
  Matrix44::new_col_major(
    c0.x(),
    c0.y(),
    c0.z(),
    c0.w(),
    c1.x(),
    c1.y(),
    c1.z(),
    c1.w(),
    c2.x(),
    c2.y(),
    c2.z(),
    c2.w(),
    c3.x(),
    c3.y(),
    c3.z(),
    c3.w(),
  )
}

///|
pub fn[T : Default] Matrix44::zero() -> Matrix44[T] {
  let z = T::default()
  Matrix44::new_col_major(z, z, z, z, z, z, z, z, z, z, z, z, z, z, z, z)
}

///|
pub fn[T] Matrix44::identity_with(one : T, zero : T) -> Matrix44[T] {
  Matrix44::new_col_major(
    one, zero, zero, zero, zero, one, zero, zero, zero, zero, one, zero, zero, zero,
    zero, one,
  )
}

///|
pub fn Matrix44F::identity() -> Matrix44F {
  Matrix44::identity_with((1.0 : Float), (0.0 : Float))
}

///|
pub fn[T] Matrix44::at(self : Matrix44[T], row : Int, col : Int) -> T {
  self.data[col * 4 + row]
}

///|
/// Returns the inner `FixedArray` unchanged (length 16, column-major).
pub fn[T] Matrix44::data(self : Matrix44[T]) -> FixedArray[T] {
  self.data
}

///|
pub fn[T : Mul] Matrix44::scale(self : Matrix44[T], s : T) -> Matrix44[T] {
  Matrix44::{
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
        self.data[9] * s,
        self.data[10] * s,
        self.data[11] * s,
        self.data[12] * s,
        self.data[13] * s,
        self.data[14] * s,
        self.data[15] * s,
      ] : FixedArray[T]),
  }
}

///|
pub fn[T : Div] Matrix44::div_scalar(self : Matrix44[T], s : T) -> Matrix44[T] {
  Matrix44::{
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
        self.data[9] / s,
        self.data[10] / s,
        self.data[11] / s,
        self.data[12] / s,
        self.data[13] / s,
        self.data[14] / s,
        self.data[15] / s,
      ] : FixedArray[T]),
  }
}

///|
pub fn[T] Matrix44::transpose(self : Matrix44[T]) -> Matrix44[T] {
  Matrix44::from_cols(
    @v4.Vector4::new(self.at(0, 0), self.at(1, 0), self.at(2, 0), self.at(3, 0)),
    @v4.Vector4::new(self.at(0, 1), self.at(1, 1), self.at(2, 1), self.at(3, 1)),
    @v4.Vector4::new(self.at(0, 2), self.at(1, 2), self.at(2, 2), self.at(3, 2)),
    @v4.Vector4::new(self.at(0, 3), self.at(1, 3), self.at(2, 3), self.at(3, 3)),
  )
}

///|
/// Matrix product `self * other` (standard linear algebra).
pub fn[T : Mul + Add] Matrix44::mat_mul(
  self : Matrix44[T],
  other : Matrix44[T],
) -> Matrix44[T] {
  Matrix44::from_cols(
    self.mul_vec4(
      @v4.Vector4::new(
        other.at(0, 0),
        other.at(1, 0),
        other.at(2, 0),
        other.at(3, 0),
      ),
    ),
    self.mul_vec4(
      @v4.Vector4::new(
        other.at(0, 1),
        other.at(1, 1),
        other.at(2, 1),
        other.at(3, 1),
      ),
    ),
    self.mul_vec4(
      @v4.Vector4::new(
        other.at(0, 2),
        other.at(1, 2),
        other.at(2, 2),
        other.at(3, 2),
      ),
    ),
    self.mul_vec4(
      @v4.Vector4::new(
        other.at(0, 3),
        other.at(1, 3),
        other.at(2, 3),
        other.at(3, 3),
      ),
    ),
  )
}

///|
/// Column vector multiply: `self * v` (treats `v` as a column 4-vector).
pub fn[T : Mul + Add] Matrix44::mul_vec4(
  self : Matrix44[T],
  v : @v4.Vector4[T],
) -> @v4.Vector4[T] {
  let x = v.x()
  let y = v.y()
  let z = v.z()
  let w = v.w()
  @v4.Vector4::new(
    self.at(0, 0) * x +
    self.at(0, 1) * y +
    self.at(0, 2) * z +
    self.at(0, 3) * w,
    self.at(1, 0) * x +
    self.at(1, 1) * y +
    self.at(1, 2) * z +
    self.at(1, 3) * w,
    self.at(2, 0) * x +
    self.at(2, 1) * y +
    self.at(2, 2) * z +
    self.at(2, 3) * w,
    self.at(3, 0) * x +
    self.at(3, 1) * y +
    self.at(3, 2) * z +
    self.at(3, 3) * w,
  )
}

///|
/// Homogeneous point: applies `M * (x, y, z, 1)` and divides by the resulting `w` (when non-zero).
pub fn Matrix44F::transform_point(
  self : Matrix44F,
  p : @v3.Vector3F,
) -> @v3.Vector3F {
  let r = self.mul_vec4(@v4.Vector4::new(p.x(), p.y(), p.z(), (1.0 : Float)))
  let w = r.w()
  if w == (0.0 : Float) {
    @v3.Vector3F::zero()
  } else {
    @v3.Vector3::new(r.x() / w, r.y() / w, r.z() / w)
  }
}

///|
pub fn[T : Mul + Add + Sub] Matrix44::determinant(self : Matrix44[T]) -> T {
  let a00 = self.at(0, 0)
  let a01 = self.at(0, 1)
  let a02 = self.at(0, 2)
  let a03 = self.at(0, 3)
  a00 * mat4_minor(self, 0, 0) -
  a01 * mat4_minor(self, 0, 1) +
  a02 * mat4_minor(self, 0, 2) -
  a03 * mat4_minor(self, 0, 3)
}

///|
/// Returns `None` when the determinant is exactly `T::default()` (typically 0).
pub fn[T : Mul + Add + Sub + Div + Neg + Eq + Default] Matrix44::inverse(
  self : Matrix44[T],
) -> Matrix44[T]? {
  let det = self.determinant()
  if det == T::default() {
    None
  } else {
    Some(
      Matrix44::from_cols(
        @v4.Vector4::new(
          matrix4_cofactor(self, 0, 0) / det,
          matrix4_cofactor(self, 0, 1) / det,
          matrix4_cofactor(self, 0, 2) / det,
          matrix4_cofactor(self, 0, 3) / det,
        ),
        @v4.Vector4::new(
          matrix4_cofactor(self, 1, 0) / det,
          matrix4_cofactor(self, 1, 1) / det,
          matrix4_cofactor(self, 1, 2) / det,
          matrix4_cofactor(self, 1, 3) / det,
        ),
        @v4.Vector4::new(
          matrix4_cofactor(self, 2, 0) / det,
          matrix4_cofactor(self, 2, 1) / det,
          matrix4_cofactor(self, 2, 2) / det,
          matrix4_cofactor(self, 2, 3) / det,
        ),
        @v4.Vector4::new(
          matrix4_cofactor(self, 3, 0) / det,
          matrix4_cofactor(self, 3, 1) / det,
          matrix4_cofactor(self, 3, 2) / det,
          matrix4_cofactor(self, 3, 3) / det,
        ),
      ),
    )
  }
}
