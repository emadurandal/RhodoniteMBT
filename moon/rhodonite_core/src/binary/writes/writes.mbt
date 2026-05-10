///|
/// Write a uint16 little-endian into `buf` at `off`.
pub fn put_u16_le(buf : FixedArray[Byte], off : Int, u : UInt) -> Unit {
  buf[off] = (u & 0xFFU).to_byte()
  buf[off + 1] = ((u >> 8) & 0xFFU).to_byte()
}

///|
/// Write a uint32 little-endian into `buf` at `off`.
pub fn put_u32_le(buf : FixedArray[Byte], off : Int, u : UInt) -> Unit {
  buf[off] = (u & 0xFFU).to_byte()
  buf[off + 1] = ((u >> 8) & 0xFFU).to_byte()
  buf[off + 2] = ((u >> 16) & 0xFFU).to_byte()
  buf[off + 3] = ((u >> 24) & 0xFFU).to_byte()
}

///|
/// Round `Double` to f32 bits and write them little-endian into `buf` at `off`.
pub fn put_f32_le(buf : FixedArray[Byte], off : Int, d : Double) -> Unit {
  let u = Float::from_double(d).reinterpret_as_uint()
  put_u32_le(buf, off, u)
}

///|
/// Read a uint32 little-endian from `buf` at `off`.
pub fn get_u32_le(buf : FixedArray[Byte], off : Int) -> UInt {
  buf[off].to_uint() |
  (buf[off + 1].to_uint() << 8) |
  (buf[off + 2].to_uint() << 16) |
  (buf[off + 3].to_uint() << 24)
}

///|
/// Same as [`get_u32_le`] for a zero-copy [`ArrayView`] over bytes.
pub fn get_u32_le_byte_view(buf : ArrayView[Byte], off : Int) -> UInt {
  buf[off].to_uint() |
  (buf[off + 1].to_uint() << 8) |
  (buf[off + 2].to_uint() << 16) |
  (buf[off + 3].to_uint() << 24)
}

///|
/// Read an IEEE754 `f32` stored little-endian at `off`; returns `Double`.
pub fn get_f32_le(buf : FixedArray[Byte], off : Int) -> Double {
  Float::reinterpret_from_uint(get_u32_le(buf, off)).to_double()
}
