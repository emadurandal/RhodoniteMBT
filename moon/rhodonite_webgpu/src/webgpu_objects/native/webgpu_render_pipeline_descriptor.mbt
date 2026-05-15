///|
/// Defines `WebGPURenderPipelineDescriptor`.
pub struct WebGPURenderPipelineDescriptor {
  vertex : GPUShaderModule
  fragment : GPUShaderModule
  topology : @webgpu_enums.GPUPrimitiveTopology
  formats : Array[String]
}

///|
/// Implements `WebGPURenderPipelineDescriptor::new`.
pub fn WebGPURenderPipelineDescriptor::new(
  vertex~ : GPUShaderModule,
  fragment~ : GPUShaderModule,
  topology~ : @webgpu_enums.GPUPrimitiveTopology,
  formats~ : Array[String],
) -> WebGPURenderPipelineDescriptor {
  { vertex, fragment, topology, formats }
}
