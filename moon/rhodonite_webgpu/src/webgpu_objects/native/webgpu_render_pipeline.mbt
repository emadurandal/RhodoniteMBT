///|
/// Implements `renderPipeline_release`.
pub fn renderPipeline_release(pipeline : GPURenderPipeline) -> Unit {
  pipeline.raw.release()
}
