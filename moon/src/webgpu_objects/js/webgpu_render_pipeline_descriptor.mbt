///|
pub struct WebGPURenderPipelineDescriptor {
  vertex : GPUShaderModule
  fragment : GPUShaderModule
  topology : @webgpu_enums.GPUPrimitiveTopology
  formats : Array[String]
}

///|
pub fn WebGPURenderPipelineDescriptor::new(
  vertex~ : GPUShaderModule,
  fragment~ : GPUShaderModule,
  topology~ : @webgpu_enums.GPUPrimitiveTopology,
  formats~ : Array[String],
) -> WebGPURenderPipelineDescriptor {
  { vertex, fragment, topology, formats }
}
