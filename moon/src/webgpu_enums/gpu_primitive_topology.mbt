///|
/// WebGPU `GPUPrimitiveTopology`（`primitive.topology` に対応する列挙）。
pub(all) enum GPUPrimitiveTopology {
  PointList
  LineList
  LineStrip
  TriangleList
  TriangleStrip
} derive(Eq)

///|
/// JS FFI の `device_createRenderPipeline` に渡すタグ（`TOPOLOGY_NAMES` の添字と一致させること）。
pub fn GPUPrimitiveTopology::to_js_tag(self : GPUPrimitiveTopology) -> Int {
  match self {
    PointList => 0
    LineList => 1
    LineStrip => 2
    TriangleList => 3
    TriangleStrip => 4
  }
}
