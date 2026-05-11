///|
/// Borrowed 3-vector as a [`MutArrayView`] over storage; for `T = [`Byte`]` the
/// view length must be **12** (three little-endian `f32`).
pub(all) struct Vector3Ref[T] {
  data : MutArrayView[T]
}

///|
pub fn Vector3Ref::from_mut_view(data : MutArrayView[Byte]) -> Vector3Ref[Byte] {
  guard data.length() == 12 else {
    abort("Vector3Ref::from_mut_view: expected 12 bytes")
  }
  Vector3Ref::{ data, }
}

///|
pub fn Vector3Ref::x(self : Vector3Ref[Byte]) -> Float {
  Float::reinterpret_from_uint(@writes.get_u32_le_mut_view(self.data, 0))
}

///|
pub fn Vector3Ref::y(self : Vector3Ref[Byte]) -> Float {
  Float::reinterpret_from_uint(@writes.get_u32_le_mut_view(self.data, 4))
}

///|
pub fn Vector3Ref::z(self : Vector3Ref[Byte]) -> Float {
  Float::reinterpret_from_uint(@writes.get_u32_le_mut_view(self.data, 8))
}

///|
pub fn Vector3Ref::set_x(self : Vector3Ref[Byte], v : Float) -> Unit {
  @writes.put_f32_le_mut_view(self.data, 0, v.to_double())
}

///|
pub fn Vector3Ref::set_y(self : Vector3Ref[Byte], v : Float) -> Unit {
  @writes.put_f32_le_mut_view(self.data, 4, v.to_double())
}

///|
pub fn Vector3Ref::set_z(self : Vector3Ref[Byte], v : Float) -> Unit {
  @writes.put_f32_le_mut_view(self.data, 8, v.to_double())
}
