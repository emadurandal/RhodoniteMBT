///| `GPURenderPipeline` を包み、リリース用のメソッドを `webgpu` パッケージ側に置く。

///|
pub struct RenderPipeline {
  raw : GPURenderPipeline
}

///|
pub fn RenderPipeline::new(raw : GPURenderPipeline) -> RenderPipeline {
  { raw, }
}

///|
pub fn RenderPipeline::get(self : RenderPipeline) -> GPURenderPipeline {
  self.raw
}

///|
pub fn RenderPipeline::release(self : RenderPipeline) -> Unit {
  renderPipeline_release(self.raw)
}
