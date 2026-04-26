// WebGPU render pipeline descriptor implementation

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
pub fn WebGPURenderPipelineDescriptor::get(
  self : WebGPURenderPipelineDescriptor,
) -> (GPUShaderModule, GPUShaderModule, String, Array[String]) {
  (self.vertex, self.fragment, self.topology, self.formats)
}
