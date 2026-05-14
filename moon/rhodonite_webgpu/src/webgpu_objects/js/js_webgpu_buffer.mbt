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
