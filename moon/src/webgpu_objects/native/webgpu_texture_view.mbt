///|
pub fn textureView_release(view : GPUTextureView) -> Unit {
  view.raw.release()
}
