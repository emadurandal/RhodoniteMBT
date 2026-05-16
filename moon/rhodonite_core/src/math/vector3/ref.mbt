///|
/// Borrowed 3-vector as a [`MutArrayView`] over storage; for `T = [`Byte`]` the
/// view length must be **12** (three little-endian `f32`).
pub(all) struct Vector3Ref[T] {
  data : MutArrayView[T]
}

///|
/// Implements `Vector3Ref::from_mut_view`.
pub fn Vector3Ref::from_mut_view(data : MutArrayView[Byte]) -> Vector3Ref[Byte] {
  guard data.length() == 12 else {
    abort("Vector3Ref::from_mut_view: expected 12 bytes")
  }
  Vector3Ref::{ data, }
}

///|
/// Implements `Vector3Ref::x`.
pub fn Vector3Ref::x(self : Vector3Ref[Byte]) -> Float {
  Float::reinterpret_from_uint(@writes.get_u32_le_mut_view(self.data, 0))
}

///|
/// Implements `Vector3Ref::y`.
pub fn Vector3Ref::y(self : Vector3Ref[Byte]) -> Float {
  Float::reinterpret_from_uint(@writes.get_u32_le_mut_view(self.data, 4))
}

///|
/// Implements `Vector3Ref::z`.
pub fn Vector3Ref::z(self : Vector3Ref[Byte]) -> Float {
  Float::reinterpret_from_uint(@writes.get_u32_le_mut_view(self.data, 8))
}

///|
#cfg(target="js")
extern "js" fn write_f32x3_mut_view(
  data : MutArrayView[Byte],
  x : Float,
  y : Float,
  z : Float,
) -> Unit =
  #| (data, x, y, z) => {
  #|   const bytes = data.buf;
  #|   const base = data.start;
  #|   if (ArrayBuffer.isView(bytes) && ((bytes.byteOffset | bytes.byteLength | base) & 3) === 0) {
  #|     let f32 = bytes.__rhodonite_f32_view;
  #|     if (!f32 || f32.buffer !== bytes.buffer || f32.byteOffset !== bytes.byteOffset) {
  #|       f32 = new Float32Array(bytes.buffer, bytes.byteOffset, bytes.byteLength >> 2);
  #|       bytes.__rhodonite_f32_view = f32;
  #|     }
  #|     const i = base >> 2;
  #|     f32[i] = Math.fround(x);
  #|     f32[i + 1] = Math.fround(y);
  #|     f32[i + 2] = Math.fround(z);
  #|     return;
  #|   }
  #|   const scratch = globalThis.__rhodonite_f32_scratch ||
  #|     (globalThis.__rhodonite_f32_scratch = { u32: new Uint32Array(1), f32: null });
  #|   if (!scratch.f32) scratch.f32 = new Float32Array(scratch.u32.buffer);
  #|   const put = (off, v) => {
  #|     scratch.f32[0] = Math.fround(v);
  #|     const u = scratch.u32[0];
  #|     const o = base + off;
  #|     bytes[o] = u & 0xff;
  #|     bytes[o + 1] = (u >>> 8) & 0xff;
  #|     bytes[o + 2] = (u >>> 16) & 0xff;
  #|     bytes[o + 3] = (u >>> 24) & 0xff;
  #|   };
  #|   put(0, x);
  #|   put(4, y);
  #|   put(8, z);
  #| }

///|

///|
/// Implements `write_f32x3_mut_view`.
#cfg(not(target="js"))
fn write_f32x3_mut_view(
  data : MutArrayView[Byte],
  x : Float,
  y : Float,
  z : Float,
) -> Unit {
  let ux = x.reinterpret_as_uint()
  let uy = y.reinterpret_as_uint()
  let uz = z.reinterpret_as_uint()
  data[0] = (ux & 0xFFU).to_byte()
  data[1] = ((ux >> 8) & 0xFFU).to_byte()
  data[2] = ((ux >> 16) & 0xFFU).to_byte()
  data[3] = ((ux >> 24) & 0xFFU).to_byte()
  data[4] = (uy & 0xFFU).to_byte()
  data[5] = ((uy >> 8) & 0xFFU).to_byte()
  data[6] = ((uy >> 16) & 0xFFU).to_byte()
  data[7] = ((uy >> 24) & 0xFFU).to_byte()
  data[8] = (uz & 0xFFU).to_byte()
  data[9] = ((uz >> 8) & 0xFFU).to_byte()
  data[10] = ((uz >> 16) & 0xFFU).to_byte()
  data[11] = ((uz >> 24) & 0xFFU).to_byte()
}

///|
/// Writes all three f32 lanes into a borrowed byte vector in one call. This keeps the
/// zero-copy view model while avoiding three separate setter calls.
pub fn Vector3Ref::set(
  self : Vector3Ref[Byte],
  x : Float,
  y : Float,
  z : Float,
) -> Unit {
  write_f32x3_mut_view(self.data, x, y, z)
}

///|
/// Writes all three f32 lanes into a 12-byte borrowed view without constructing a [`Vector3Ref`].
pub fn Vector3Ref::write_mut_view(
  data : MutArrayView[Byte],
  x : Float,
  y : Float,
  z : Float,
) -> Unit {
  guard data.length() == 12 else {
    abort("Vector3Ref::write_mut_view: expected 12 bytes")
  }
  write_f32x3_mut_view(data, x, y, z)
}

///|
/// Implements `Vector3Ref::set_x`.
pub fn Vector3Ref::set_x(self : Vector3Ref[Byte], v : Float) -> Unit {
  @writes.put_f32_le_mut_view(self.data, 0, v.to_double())
}

///|
/// Implements `Vector3Ref::set_y`.
pub fn Vector3Ref::set_y(self : Vector3Ref[Byte], v : Float) -> Unit {
  @writes.put_f32_le_mut_view(self.data, 4, v.to_double())
}

///|
/// Implements `Vector3Ref::set_z`.
pub fn Vector3Ref::set_z(self : Vector3Ref[Byte], v : Float) -> Unit {
  @writes.put_f32_le_mut_view(self.data, 8, v.to_double())
}
