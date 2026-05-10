///|
/// WebGPU `GPUIndexFormat` (`setIndexBuffer` format).
pub(all) enum GPUIndexFormat {
  Uint16
  Uint32
} derive(Eq)

///|
/// String passed to the browser `GPUQueue.setIndexBuffer`.
pub fn GPUIndexFormat::to_js_tag(self : GPUIndexFormat) -> String {
  match self {
    Uint16 => "uint16"
    Uint32 => "uint32"
  }
}
