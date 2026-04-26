// WebGPU color attachment implementation

///|
pub struct WebGPUColorAttachment {
  view : GPUTextureView
  clearValue : WebGPUColor?
  loadOp : String
  storeOp : String
}

///|
pub fn WebGPUColorAttachment::new(
  view~ : GPUTextureView,
  clearValue~ : WebGPUColor?,
  loadOp~ : String,
  storeOp~ : String,
) -> WebGPUColorAttachment {
  { view, clearValue, loadOp, storeOp }
}

///|
pub fn WebGPUColorAttachment::get(
  self : WebGPUColorAttachment,
) -> (GPUTextureView, WebGPUColor?, String, String) {
  (self.view, self.clearValue, self.loadOp, self.storeOp)
}
