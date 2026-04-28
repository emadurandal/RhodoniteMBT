// WebGPU device abstraction

///|
pub(open) trait WebGPUDevice {
  getQueue(self : Self) -> &WebGPUQueue
  createCommandEncoder(self : Self) -> &WebGPUCommandEncoder
}
