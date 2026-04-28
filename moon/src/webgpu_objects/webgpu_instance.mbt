// WebGPU instance implementation

///|
/// 他パッケージから `impl` するには `pub(open)` が必要。
pub(open) trait WebGPUInstance {
  getPreferredCanvasFormat(self : Self) -> String
  async requestAdapter(self : Self) -> &WebGPUAdapter
}
