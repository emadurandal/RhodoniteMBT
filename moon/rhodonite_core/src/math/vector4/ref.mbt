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
#cfg(target="js")
extern "js" fn write_f32x4_mut_view(
  data : MutArrayView[Byte],
  x : Float,
  y : Float,
  z : Float,
  w : Float,
) -> Unit =
  #| (data, x, y, z, w) => {
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
  #|     f32[i + 3] = Math.fround(w);
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
  #|   put(12, w);
  #| }

///|
#cfg(not(target="js"))
fn write_f32x4_mut_view(
  data : MutArrayView[Byte],
  x : Float,
  y : Float,
  z : Float,
  w : Float,
) -> Unit {
  let ux = x.reinterpret_as_uint()
  let uy = y.reinterpret_as_uint()
  let uz = z.reinterpret_as_uint()
  let uw = w.reinterpret_as_uint()
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
  data[12] = (uw & 0xFFU).to_byte()
  data[13] = ((uw >> 8) & 0xFFU).to_byte()
  data[14] = ((uw >> 16) & 0xFFU).to_byte()
  data[15] = ((uw >> 24) & 0xFFU).to_byte()
}

///|
/// Writes all four f32 lanes into a borrowed byte vector in one call.
pub fn Vector4Ref::set(
  self : Vector4Ref[Byte],
  x : Float,
  y : Float,
  z : Float,
  w : Float,
) -> Unit {
  write_f32x4_mut_view(self.data, x, y, z, w)
}

///|
/// Writes all four f32 lanes into a 16-byte borrowed view without constructing a [`Vector4Ref`].
pub fn Vector4Ref::write_mut_view(
  data : MutArrayView[Byte],
  x : Float,
  y : Float,
  z : Float,
  w : Float,
) -> Unit {
  guard data.length() == 16 else {
    abort("Vector4Ref::write_mut_view: expected 16 bytes")
  }
  write_f32x4_mut_view(data, x, y, z, w)
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
