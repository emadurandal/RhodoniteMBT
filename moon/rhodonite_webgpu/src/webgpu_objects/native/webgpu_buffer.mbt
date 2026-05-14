///|
pub fn buffer_release(buffer : GPUBuffer) -> Unit {
  buffer.raw.release()
}

///|
fn empty_bytes_view() -> BytesView {
  let empty : Bytes = []
  empty[:]
}

///|
pub fn webgpu_buffer_readback_view(
  buffer : GPUBuffer,
  instance : WebGPUInstance,
  offset : UInt64,
  size : UInt64,
) -> BytesView {
  let buf_size = buffer.raw.size()
  if offset + size > buf_size {
    return empty_bytes_view()
  }
  let aligned_offset = offset - offset % 8UL
  let prefix = offset - aligned_offset
  let need = prefix + size
  let rem = need % 4UL
  let aligned_size = if rem == 0UL { need } else { need + (4UL - rem) }
  if aligned_offset + aligned_size > buf_size {
    return empty_bytes_view()
  }
  let out = Bytes::new(aligned_size.to_int())
  let ok = @c.buffer_readback_sync(
    instance.instance.raw.raw,
    buffer.raw.raw,
    aligned_offset,
    aligned_size,
    out,
    aligned_size,
  )
  if !ok {
    empty_bytes_view()
  } else {
    out[:][prefix.to_int():(prefix + size).to_int()]
  }
}

///|
pub fn webgpu_buffer_readback(
  buffer : GPUBuffer,
  instance : WebGPUInstance,
  offset : UInt64,
  size : UInt64,
) -> Bytes {
  buffer.raw.readback(instance.instance.raw, offset, size)
}
