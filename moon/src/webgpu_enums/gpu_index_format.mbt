///|
/// WebGPU `GPUIndexFormat`（`setIndexBuffer` の形式）。
pub(all) enum GPUIndexFormat {
  Uint16
  Uint32
} derive(Eq)

///|
/// ブラウザの `GPUQueue.setIndexBuffer` に渡す文字列。
pub fn GPUIndexFormat::to_js_tag(self : GPUIndexFormat) -> String {
  match self {
    Uint16 => "uint16"
    Uint32 => "uint32"
  }
}
