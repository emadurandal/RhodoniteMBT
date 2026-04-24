// WebGPU initialization functions

pub struct WebGPUContext {
  device : GPUDevice
  context : GPUCanvasContext
  format : String
  queue : GPUQueue
}

pub fn WebGPUContext::new(
  device : GPUDevice,
  context : GPUCanvasContext,
  format : String,
  queue : GPUQueue,
) -> WebGPUContext {
  { device, context, format, queue }
}