///|
/// Borrowed 4-vector as a [`MutArrayView`]; for `T = [`Byte`]` the view length
/// must be **16** (four little-endian `f32`).
pub(all) struct Vector4Ref[T] {
  data : MutArrayView[T]
}

///|
pub fn Vector4Ref::from_mut_view(data : MutArrayView[Byte]) -> Vector4Ref[Byte] {
  guard data.length() == 16 else {
    abort("Vector4Ref::from_mut_view: expected 16 bytes")
  }
  Vector4Ref::{ data, }
}

///|
pub fn Vector4Ref::x(self : Vector4Ref[Byte]) -> Float {
  Float::reinterpret_from_uint(@writes.get_u32_le_mut_view(self.data, 0))
}

///|
pub fn Vector4Ref::y(self : Vector4Ref[Byte]) -> Float {
  Float::reinterpret_from_uint(@writes.get_u32_le_mut_view(self.data, 4))
}

///|
pub fn Vector4Ref::z(self : Vector4Ref[Byte]) -> Float {
  Float::reinterpret_from_uint(@writes.get_u32_le_mut_view(self.data, 8))
}

///|
pub fn Vector4Ref::w(self : Vector4Ref[Byte]) -> Float {
  Float::reinterpret_from_uint(@writes.get_u32_le_mut_view(self.data, 12))
}

///|
pub fn Vector4Ref::set_x(self : Vector4Ref[Byte], v : Float) -> Unit {
  @writes.put_f32_le_mut_view(self.data, 0, v.to_double())
}

///|
pub fn Vector4Ref::set_y(self : Vector4Ref[Byte], v : Float) -> Unit {
  @writes.put_f32_le_mut_view(self.data, 4, v.to_double())
}

///|
pub fn Vector4Ref::set_z(self : Vector4Ref[Byte], v : Float) -> Unit {
  @writes.put_f32_le_mut_view(self.data, 8, v.to_double())
}

///|
pub fn Vector4Ref::set_w(self : Vector4Ref[Byte], v : Float) -> Unit {
  @writes.put_f32_le_mut_view(self.data, 12, v.to_double())
}
