///|
/// Write a uint16 little-endian into `buf` at `off`.
#cfg(target="js")
pub extern "js" fn put_u16_le(
  buf : FixedArray[Byte],
  off : Int,
  u : UInt,
) -> Unit =
  #| (buf, off, u) => {
  #|   buf[off] = u & 0xff;
  #|   buf[off + 1] = (u >>> 8) & 0xff;
  #| }

///|
/// Write a uint16 little-endian into `buf` at `off`.

///|
/// Implements `put_u16_le`.
#cfg(not(target="js"))
pub fn put_u16_le(buf : FixedArray[Byte], off : Int, u : UInt) -> Unit {
  buf[off] = (u & 0xFFU).to_byte()
  buf[off + 1] = ((u >> 8) & 0xFFU).to_byte()
}

///|
/// Write a uint32 little-endian into `buf` at `off`.
#cfg(target="js")
pub extern "js" fn put_u32_le(
  buf : FixedArray[Byte],
  off : Int,
  u : UInt,
) -> Unit =
  #| (buf, off, u) => {
  #|   buf[off] = u & 0xff;
  #|   buf[off + 1] = (u >>> 8) & 0xff;
  #|   buf[off + 2] = (u >>> 16) & 0xff;
  #|   buf[off + 3] = (u >>> 24) & 0xff;
  #| }

///|
/// Write a uint32 little-endian into `buf` at `off`.

///|
/// Implements `put_u32_le`.
#cfg(not(target="js"))
pub fn put_u32_le(buf : FixedArray[Byte], off : Int, u : UInt) -> Unit {
  buf[off] = (u & 0xFFU).to_byte()
  buf[off + 1] = ((u >> 8) & 0xFFU).to_byte()
  buf[off + 2] = ((u >> 16) & 0xFFU).to_byte()
  buf[off + 3] = ((u >> 24) & 0xFFU).to_byte()
}

///|
/// Round `Double` to f32 bits and write them little-endian into `buf` at `off`.
#cfg(target="js")
pub extern "js" fn put_f32_le(
  buf : FixedArray[Byte],
  off : Int,
  d : Double,
) -> Unit =
  #| (buf, off, d) => {
  #|   const scratch = globalThis.__rhodonite_f32_scratch ||
  #|     (globalThis.__rhodonite_f32_scratch = {
  #|       u32: new Uint32Array(1),
  #|       f32: null,
  #|     });
  #|   if (!scratch.f32) scratch.f32 = new Float32Array(scratch.u32.buffer);
  #|   scratch.f32[0] = Math.fround(d);
  #|   const u = scratch.u32[0];
  #|   buf[off] = u & 0xff;
  #|   buf[off + 1] = (u >>> 8) & 0xff;
  #|   buf[off + 2] = (u >>> 16) & 0xff;
  #|   buf[off + 3] = (u >>> 24) & 0xff;
  #| }

///|
/// Round `Double` to f32 bits and write them little-endian into `buf` at `off`.

///|
/// Implements `put_f32_le`.
#cfg(not(target="js"))
pub fn put_f32_le(buf : FixedArray[Byte], off : Int, d : Double) -> Unit {
  let u = Float::from_double(d).reinterpret_as_uint()
  put_u32_le(buf, off, u)
}

///|
/// Read a uint32 little-endian from `buf` at `off`.
#cfg(target="js")
pub extern "js" fn get_u32_le(buf : FixedArray[Byte], off : Int) -> UInt =
  #| (buf, off) =>
  #|   (buf[off] & 0xff) |
  #|   ((buf[off + 1] & 0xff) << 8) |
  #|   ((buf[off + 2] & 0xff) << 16) |
  #|   ((buf[off + 3] & 0xff) << 24)

///|
/// Read a uint32 little-endian from `buf` at `off`.

///|
/// Implements `get_u32_le`.
#cfg(not(target="js"))
pub fn get_u32_le(buf : FixedArray[Byte], off : Int) -> UInt {
  buf[off].to_uint() |
  (buf[off + 1].to_uint() << 8) |
  (buf[off + 2].to_uint() << 16) |
  (buf[off + 3].to_uint() << 24)
}

///|
/// Same as [`get_u32_le`] for a zero-copy [`ArrayView`] over bytes.
#cfg(target="js")
pub extern "js" fn get_u32_le_byte_view(
  buf : ArrayView[Byte],
  off : Int,
) -> UInt =
  #| (buf, off) => {
  #|   const bytes = buf.buf;
  #|   const i = buf.start + off;
  #|   return (bytes[i] & 0xff) |
  #|     ((bytes[i + 1] & 0xff) << 8) |
  #|     ((bytes[i + 2] & 0xff) << 16) |
  #|     ((bytes[i + 3] & 0xff) << 24);
  #| }

///|
/// Same as [`get_u32_le`] for a zero-copy [`ArrayView`] over bytes.

///|
/// Implements `get_u32_le_byte_view`.
#cfg(not(target="js"))
pub fn get_u32_le_byte_view(buf : ArrayView[Byte], off : Int) -> UInt {
  buf[off].to_uint() |
  (buf[off + 1].to_uint() << 8) |
  (buf[off + 2].to_uint() << 16) |
  (buf[off + 3].to_uint() << 24)
}

///|
/// Read an IEEE754 `f32` stored little-endian at `off`; returns `Double`.
#cfg(target="js")
pub extern "js" fn get_f32_le(buf : FixedArray[Byte], off : Int) -> Double =
  #| (buf, off) => {
  #|   const bits =
  #|     (buf[off] & 0xff) |
  #|     ((buf[off + 1] & 0xff) << 8) |
  #|     ((buf[off + 2] & 0xff) << 16) |
  #|     ((buf[off + 3] & 0xff) << 24);
  #|   const scratch = globalThis.__rhodonite_f32_scratch ||
  #|     (globalThis.__rhodonite_f32_scratch = {
  #|       u32: new Uint32Array(1),
  #|       f32: null,
  #|     });
  #|   if (!scratch.f32) scratch.f32 = new Float32Array(scratch.u32.buffer);
  #|   scratch.u32[0] = bits >>> 0;
  #|   return scratch.f32[0];
  #| }

///|
/// Read an IEEE754 `f32` stored little-endian at `off`; returns `Double`.

///|
/// Implements `get_f32_le`.
#cfg(not(target="js"))
pub fn get_f32_le(buf : FixedArray[Byte], off : Int) -> Double {
  Float::reinterpret_from_uint(get_u32_le(buf, off)).to_double()
}

///|
/// Same as [`get_u32_le`] for a [`MutArrayView`] over bytes.
#cfg(target="js")
pub extern "js" fn get_u32_le_mut_view(
  buf : MutArrayView[Byte],
  off : Int,
) -> UInt =
  #| (buf, off) => {
  #|   const bytes = buf.buf;
  #|   const i = buf.start + off;
  #|   return (bytes[i] & 0xff) |
  #|     ((bytes[i + 1] & 0xff) << 8) |
  #|     ((bytes[i + 2] & 0xff) << 16) |
  #|     ((bytes[i + 3] & 0xff) << 24);
  #| }

///|
/// Same as [`get_u32_le`] for a [`MutArrayView`] over bytes.

///|
/// Implements `get_u32_le_mut_view`.
#cfg(not(target="js"))
pub fn get_u32_le_mut_view(buf : MutArrayView[Byte], off : Int) -> UInt {
  buf[off].to_uint() |
  (buf[off + 1].to_uint() << 8) |
  (buf[off + 2].to_uint() << 16) |
  (buf[off + 3].to_uint() << 24)
}

///|
/// Same as [`put_u32_le`] into a [`MutArrayView`].
#cfg(target="js")
pub extern "js" fn put_u32_le_mut_view(
  buf : MutArrayView[Byte],
  off : Int,
  u : UInt,
) -> Unit =
  #| (buf, off, u) => {
  #|   const bytes = buf.buf;
  #|   const i = buf.start + off;
  #|   bytes[i] = u & 0xff;
  #|   bytes[i + 1] = (u >>> 8) & 0xff;
  #|   bytes[i + 2] = (u >>> 16) & 0xff;
  #|   bytes[i + 3] = (u >>> 24) & 0xff;
  #| }

///|
/// Same as [`put_u32_le`] into a [`MutArrayView`].

///|
/// Implements `put_u32_le_mut_view`.
#cfg(not(target="js"))
pub fn put_u32_le_mut_view(
  buf : MutArrayView[Byte],
  off : Int,
  u : UInt,
) -> Unit {
  buf[off] = (u & 0xFFU).to_byte()
  buf[off + 1] = ((u >> 8) & 0xFFU).to_byte()
  buf[off + 2] = ((u >> 16) & 0xFFU).to_byte()
  buf[off + 3] = ((u >> 24) & 0xFFU).to_byte()
}

///|
/// Same as [`put_f32_le`] into a [`MutArrayView`].
#cfg(target="js")
pub extern "js" fn put_f32_le_mut_view(
  buf : MutArrayView[Byte],
  off : Int,
  d : Double,
) -> Unit =
  #| (buf, off, d) => {
  #|   const scratch = globalThis.__rhodonite_f32_scratch ||
  #|     (globalThis.__rhodonite_f32_scratch = {
  #|       u32: new Uint32Array(1),
  #|       f32: null,
  #|     });
  #|   if (!scratch.f32) scratch.f32 = new Float32Array(scratch.u32.buffer);
  #|   scratch.f32[0] = Math.fround(d);
  #|   const u = scratch.u32[0];
  #|   const bytes = buf.buf;
  #|   const i = buf.start + off;
  #|   bytes[i] = u & 0xff;
  #|   bytes[i + 1] = (u >>> 8) & 0xff;
  #|   bytes[i + 2] = (u >>> 16) & 0xff;
  #|   bytes[i + 3] = (u >>> 24) & 0xff;
  #| }

///|
/// Same as [`put_f32_le`] into a [`MutArrayView`].

///|
/// Implements `put_f32_le_mut_view`.
#cfg(not(target="js"))
pub fn put_f32_le_mut_view(
  buf : MutArrayView[Byte],
  off : Int,
  d : Double,
) -> Unit {
  let u = Float::from_double(d).reinterpret_as_uint()
  put_u32_le_mut_view(buf, off, u)
}
