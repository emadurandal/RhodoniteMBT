///|
pub fn webgpu_buffer_readback_view(
  _buffer : GPUBuffer,
  _instance : WebGPUInstance,
  _offset : UInt64,
  _size : UInt64,
) -> BytesView {
  abort(
    "webgpu_buffer_readback_view is only available through the native backend",
  )
}

///|
pub fn webgpu_buffer_readback(
  _buffer : GPUBuffer,
  _instance : WebGPUInstance,
  _offset : UInt64,
  _size : UInt64,
) -> Bytes {
  abort("webgpu_buffer_readback is only available through the native backend")
}

///|
pub async fn webgpu_buffer_readback_async(
  buffer : GPUBuffer,
  offset : UInt64,
  size : UInt64,
) -> Bytes {
  @js_async.Promise::wait(
    buffer_readback_async(
      buffer,
      js_u64_to_double(offset),
      js_u64_to_double(size),
    ),
  )
}

///|
extern "js" fn buffer_readback_async(
  buffer : GPUBuffer,
  offset : Double,
  size : Double,
) -> @js_async.Promise[Bytes] =
  #| async (buffer, offset, size) => {
  #|   await buffer.mapAsync(1, offset, size);
  #|   try {
  #|     return new Uint8Array(buffer.getMappedRange(offset, size).slice(0));
  #|   } finally {
  #|     buffer.unmap();
  #|   }
  #| }
