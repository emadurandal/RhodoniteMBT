// WebGPU render pass encoder abstraction

///|
pub(open) trait WebGPURenderPassEncoder {
  draw(self : Self, vertexCount : Int) -> Unit
  end(self : Self) -> Unit
  release(self : Self) -> Unit
}
