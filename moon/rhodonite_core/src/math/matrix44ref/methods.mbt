///|
fn[T : Mul + Add + Sub + Matrix44RefElem] mat4_minor_ref(
  m : Matrix44Ref[T],
  skip_r : Int,
  skip_c : Int,
) -> T {
  let (r0, r1, r2) = @m44.rows_exc(skip_r)
  let (c0, c1, c2) = @m44.cols_exc(skip_c)
  @m44.det3_values(
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
fn[T : Mul + Add + Sub + Neg + Matrix44RefElem] matrix4_cofactor_ref(
  m : Matrix44Ref[T],
  r : Int,
  c : Int,
) -> T {
  let mi = mat4_minor_ref(m, r, c)
  if (r + c) % 2 == 0 {
    mi
  } else {
    -mi
  }
}

///|
pub fn[T : Matrix44RefElem] Matrix44Ref::at(
  self : Matrix44Ref[T],
  row : Int,
  col : Int,
) -> T {
  match self.std140_row {
    Some(bytes) => T::read_std140_mat4_cell(bytes, row, col)
    None =>
      match self.values {
        Some(v) => v[col * 4 + row]
        None => abort("Matrix44Ref::at: empty reference")
      }
  }
}

///|
pub fn[T : Matrix44RefElem] Matrix44Ref::set_at(
  self : Matrix44Ref[T],
  row : Int,
  col : Int,
  v : T,
) -> Unit {
  match self.std140_row {
    Some(bytes) => T::write_std140_mat4_cell(bytes, row, col, v)
    None =>
      match self.values {
        Some(data) => data[col * 4 + row] = v
        None => abort("Matrix44Ref::set_at: empty reference")
      }
  }
}

///|
/// Returns the backing [`MutArrayView`] (length 16, column-major `T` slots).
pub fn[T] Matrix44Ref::data(self : Matrix44Ref[T]) -> MutArrayView[T] {
  match self.std140_row {
    Some(_) =>
      abort(
        "Matrix44Ref::data: not available for std140 GPU row views (use at/set_at)",
      )
    None =>
      match self.values {
        Some(v) => v
        None => abort("Matrix44Ref::data: empty reference")
      }
  }
}

///|
pub fn[T : Matrix44RefElem] Matrix44Ref::write_col_major(
  self : Matrix44Ref[T],
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
) -> Unit {
  self.set_at(0, 0, m00)
  self.set_at(1, 0, m10)
  self.set_at(2, 0, m20)
  self.set_at(3, 0, m30)
  self.set_at(0, 1, m01)
  self.set_at(1, 1, m11)
  self.set_at(2, 1, m21)
  self.set_at(3, 1, m31)
  self.set_at(0, 2, m02)
  self.set_at(1, 2, m12)
  self.set_at(2, 2, m22)
  self.set_at(3, 2, m32)
  self.set_at(0, 3, m03)
  self.set_at(1, 3, m13)
  self.set_at(2, 3, m23)
  self.set_at(3, 3, m33)
}

///|
pub fn[T : Matrix44RefElem] Matrix44Ref::write_from_cols(
  self : Matrix44Ref[T],
  c0 : @v4.Vector4[T],
  c1 : @v4.Vector4[T],
  c2 : @v4.Vector4[T],
  c3 : @v4.Vector4[T],
) -> Unit {
  self.write_col_major(
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
pub fn[T : Default + Matrix44RefElem] Matrix44Ref::write_zero(
  self : Matrix44Ref[T],
) -> Unit {
  let z = T::default()
  self.write_col_major(z, z, z, z, z, z, z, z, z, z, z, z, z, z, z, z)
}

///|
pub fn[T : Matrix44RefElem] Matrix44Ref::write_identity_with(
  self : Matrix44Ref[T],
  one : T,
  zero : T,
) -> Unit {
  self.write_col_major(
    one, zero, zero, zero, zero, one, zero, zero, zero, zero, one, zero, zero, zero,
    zero, one,
  )
}

///|
pub fn Matrix44RefF::write_identity(self : Matrix44RefF) -> Unit {
  self.write_identity_with((1.0 : Float), (0.0 : Float))
}

///|
pub fn[T : Mul + Matrix44RefElem] Matrix44Ref::scale(
  self : Matrix44Ref[T],
  s : T,
) -> @m44.Matrix44[T] {
  @m44.Matrix44::new_col_major(
    self.at(0, 0) * s,
    self.at(1, 0) * s,
    self.at(2, 0) * s,
    self.at(3, 0) * s,
    self.at(0, 1) * s,
    self.at(1, 1) * s,
    self.at(2, 1) * s,
    self.at(3, 1) * s,
    self.at(0, 2) * s,
    self.at(1, 2) * s,
    self.at(2, 2) * s,
    self.at(3, 2) * s,
    self.at(0, 3) * s,
    self.at(1, 3) * s,
    self.at(2, 3) * s,
    self.at(3, 3) * s,
  )
}

///|
pub fn[T : Div + Matrix44RefElem] Matrix44Ref::div_scalar(
  self : Matrix44Ref[T],
  s : T,
) -> @m44.Matrix44[T] {
  @m44.Matrix44::new_col_major(
    self.at(0, 0) / s,
    self.at(1, 0) / s,
    self.at(2, 0) / s,
    self.at(3, 0) / s,
    self.at(0, 1) / s,
    self.at(1, 1) / s,
    self.at(2, 1) / s,
    self.at(3, 1) / s,
    self.at(0, 2) / s,
    self.at(1, 2) / s,
    self.at(2, 2) / s,
    self.at(3, 2) / s,
    self.at(0, 3) / s,
    self.at(1, 3) / s,
    self.at(2, 3) / s,
    self.at(3, 3) / s,
  )
}

///|
pub fn[T : Matrix44RefElem] Matrix44Ref::transpose(
  self : Matrix44Ref[T],
) -> @m44.Matrix44[T] {
  @m44.Matrix44::from_cols(
    @v4.Vector4::new(self.at(0, 0), self.at(0, 1), self.at(0, 2), self.at(0, 3)),
    @v4.Vector4::new(self.at(1, 0), self.at(1, 1), self.at(1, 2), self.at(1, 3)),
    @v4.Vector4::new(self.at(2, 0), self.at(2, 1), self.at(2, 2), self.at(2, 3)),
    @v4.Vector4::new(self.at(3, 0), self.at(3, 1), self.at(3, 2), self.at(3, 3)),
  )
}

///|
/// Matrix product `self * other` (both refs).
pub fn[T : Mul + Add + Matrix44RefElem] Matrix44Ref::mat_mul(
  self : Matrix44Ref[T],
  other : Matrix44Ref[T],
) -> @m44.Matrix44[T] {
  @m44.Matrix44::from_cols(
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
/// Matrix product `self * other` with an owned right-hand side.
pub fn[T : Mul + Add + Matrix44RefElem] Matrix44Ref::mat_mul_matrix(
  self : Matrix44Ref[T],
  other : @m44.Matrix44[T],
) -> @m44.Matrix44[T] {
  @m44.Matrix44::from_cols(
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
pub fn[T : Mul + Add + Matrix44RefElem] Matrix44Ref::mul_vec4(
  self : Matrix44Ref[T],
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
pub fn Matrix44RefF::transform_point(
  self : Matrix44RefF,
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
pub fn[T : Mul + Add + Sub + Matrix44RefElem] Matrix44Ref::determinant(
  self : Matrix44Ref[T],
) -> T {
  let a00 = self.at(0, 0)
  let a01 = self.at(0, 1)
  let a02 = self.at(0, 2)
  let a03 = self.at(0, 3)
  a00 * mat4_minor_ref(self, 0, 0) -
  a01 * mat4_minor_ref(self, 0, 1) +
  a02 * mat4_minor_ref(self, 0, 2) -
  a03 * mat4_minor_ref(self, 0, 3)
}

///|
/// Returns `None` when the determinant is exactly `T::default()` (typically 0).
pub fn[T : Mul + Add + Sub + Div + Neg + Eq + Default + Matrix44RefElem] Matrix44Ref::inverse(
  self : Matrix44Ref[T],
) -> @m44.Matrix44[T]? {
  let det = self.determinant()
  if det == T::default() {
    None
  } else {
    Some(
      @m44.Matrix44::from_cols(
        @v4.Vector4::new(
          matrix4_cofactor_ref(self, 0, 0) / det,
          matrix4_cofactor_ref(self, 0, 1) / det,
          matrix4_cofactor_ref(self, 0, 2) / det,
          matrix4_cofactor_ref(self, 0, 3) / det,
        ),
        @v4.Vector4::new(
          matrix4_cofactor_ref(self, 1, 0) / det,
          matrix4_cofactor_ref(self, 1, 1) / det,
          matrix4_cofactor_ref(self, 1, 2) / det,
          matrix4_cofactor_ref(self, 1, 3) / det,
        ),
        @v4.Vector4::new(
          matrix4_cofactor_ref(self, 2, 0) / det,
          matrix4_cofactor_ref(self, 2, 1) / det,
          matrix4_cofactor_ref(self, 2, 2) / det,
          matrix4_cofactor_ref(self, 2, 3) / det,
        ),
        @v4.Vector4::new(
          matrix4_cofactor_ref(self, 3, 0) / det,
          matrix4_cofactor_ref(self, 3, 1) / det,
          matrix4_cofactor_ref(self, 3, 2) / det,
          matrix4_cofactor_ref(self, 3, 3) / det,
        ),
      ),
    )
  }
}

///|
/// Component-wise sum; same semantics as [`@m44.Matrix44`] `+`, but result is owned
/// (standard `Add` on [`Matrix44Ref`] would require returning another ref).
pub fn[T : Add + Matrix44RefElem] Matrix44Ref::add_matrix(
  self : Matrix44Ref[T],
  other : Matrix44Ref[T],
) -> @m44.Matrix44[T] {
  self.to_matrix44() + other.to_matrix44()
}

///|
pub fn[T : Sub + Matrix44RefElem] Matrix44Ref::sub_matrix(
  self : Matrix44Ref[T],
  other : Matrix44Ref[T],
) -> @m44.Matrix44[T] {
  self.to_matrix44() - other.to_matrix44()
}

///|
pub fn[T : Neg + Matrix44RefElem] Matrix44Ref::neg_matrix(
  self : Matrix44Ref[T],
) -> @m44.Matrix44[T] {
  -self.to_matrix44()
}

///|
/// Hadamard (component-wise) product; use [`Matrix44Ref::mat_mul`] for matrix multiplication.
pub fn[T : Mul + Matrix44RefElem] Matrix44Ref::mul_hadamard_matrix(
  self : Matrix44Ref[T],
  other : Matrix44Ref[T],
) -> @m44.Matrix44[T] {
  self.to_matrix44() * other.to_matrix44()
}
