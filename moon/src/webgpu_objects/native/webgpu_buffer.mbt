///|
pub fn buffer_release(buffer : GPUBuffer) -> Unit {
  buffer.raw.release()
}
