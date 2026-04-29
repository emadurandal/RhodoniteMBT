///|
pub struct WebGPURenderPipelineDescriptor {
  vertex : GPUShaderModule
  fragment : GPUShaderModule
  topology : String
  formats : Array[String]
}

///|
pub fn WebGPURenderPipelineDescriptor::new(
  vertex~ : GPUShaderModule,
  fragment~ : GPUShaderModule,
  topology~ : String,
  formats~ : Array[String],
) -> WebGPURenderPipelineDescriptor {
  { vertex, fragment, topology, formats }
}

///|
pub fn create_render_pipeline_descriptor(
  vertex~ : GPUShaderModule,
  fragment~ : GPUShaderModule,
  topology~ : String,
  formats~ : Array[String],
) -> WebGPURenderPipelineDescriptor {
  WebGPURenderPipelineDescriptor::new(vertex~, fragment~, topology~, formats~)
}

///|
pub fn webgpu_render_pipeline_descriptor_get(
  descriptor : WebGPURenderPipelineDescriptor,
) -> (GPUShaderModule, GPUShaderModule, String, Array[String]) {
  (
    descriptor.vertex,
    descriptor.fragment,
    descriptor.topology,
    descriptor.formats,
  )
}
