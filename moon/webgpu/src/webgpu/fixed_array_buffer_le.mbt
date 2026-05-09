///|
/// `FixedArray[Byte]` の `off` から uint16 をリトルエンディアンで書き込む（頂点・インデックスバッファ組み立て用）。
pub fn put_u16_le(buf : FixedArray[Byte], off : Int, u : UInt) -> Unit {
  buf[off] = (u & 0xFFU).to_byte()
  buf[off + 1] = ((u >> 8) & 0xFFU).to_byte()
}

///|
/// `FixedArray[Byte]` の `off` から uint32 をリトルエンディアンで書き込む。
pub fn put_u32_le(buf : FixedArray[Byte], off : Int, u : UInt) -> Unit {
  buf[off] = (u & 0xFFU).to_byte()
  buf[off + 1] = ((u >> 8) & 0xFFU).to_byte()
  buf[off + 2] = ((u >> 16) & 0xFFU).to_byte()
  buf[off + 3] = ((u >> 24) & 0xFFU).to_byte()
}

///|
/// `Double` を f32 に丸めたビット列を `off` からリトルエンディアンで書き込む。
pub fn put_f32_le(buf : FixedArray[Byte], off : Int, d : Double) -> Unit {
  let u = Float::from_double(d).reinterpret_as_uint()
  put_u32_le(buf, off, u)
}
