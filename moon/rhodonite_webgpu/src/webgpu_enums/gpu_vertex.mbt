///|
/// WebGPU vertex step mode (`vertex.buffers[].stepMode`).
pub(all) enum GPUVertexStepMode {
  Vertex
  Instance
} derive(Eq)

///|
/// JS FFI tag (0: vertex, 1: instance).
pub fn GPUVertexStepMode::to_js_tag(self : GPUVertexStepMode) -> Int {
  match self {
    Vertex => 0
    Instance => 1
  }
}

///|
/// Subset of WebGPU `GPUVertexFormat`.
pub(all) enum GPUVertexFormat {
  Float32x2
  Float32x3
  Float32x4
  Uint32x2
} derive(Eq)

///|
/// Index into JS `VERTEX_FORMAT_NAMES`.
pub fn GPUVertexFormat::to_js_tag(self : GPUVertexFormat) -> Int {
  match self {
    Float32x2 => 0
    Float32x3 => 1
    Float32x4 => 2
    Uint32x2 => 3
  }
}

///|
/// Defines `GPUVertexAttribute`.
pub(all) struct GPUVertexAttribute {
  format : GPUVertexFormat
  offset : UInt64
  shader_location : UInt
}

///|
/// Defines `GPUVertexBufferLayout`.
pub(all) struct GPUVertexBufferLayout {
  array_stride : UInt64
  step_mode : GPUVertexStepMode
  attributes : Array[GPUVertexAttribute]
}
