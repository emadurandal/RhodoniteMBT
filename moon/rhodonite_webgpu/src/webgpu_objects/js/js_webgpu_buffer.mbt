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
