// WebGPU render pass depth stencil attachment implementation

///|
/// Defines `WebGPURenderPassDepthStencilAttachment`.
pub struct WebGPURenderPassDepthStencilAttachment {
  view : GPUTextureView
  depthClearValue : Double?
  depthLoadOp : String?
  depthStoreOp : String?
  depthReadOnly : Bool?
  stencilClearValue : Double
  stencilLoadOp : String?
  stencilStoreOp : String?
  stencilReadOnly : Bool?
}

///|
/// Implements `WebGPURenderPassDepthStencilAttachment::new`.
pub fn WebGPURenderPassDepthStencilAttachment::new(
  view~ : GPUTextureView,
  depthClearValue? : Double? = None,
  depthLoadOp? : String,
  depthStoreOp? : String,
  depthReadOnly? : Bool,
  stencilClearValue? : Double = 0,
  stencilLoadOp? : String,
  stencilStoreOp? : String,
  stencilReadOnly? : Bool,
) -> WebGPURenderPassDepthStencilAttachment {
  {
    view,
    depthClearValue,
    depthLoadOp,
    depthStoreOp,
    depthReadOnly,
    stencilClearValue,
    stencilLoadOp,
    stencilStoreOp,
    stencilReadOnly,
  }
}

///|
/// Implements `WebGPURenderPassDepthStencilAttachment::get`.
pub fn WebGPURenderPassDepthStencilAttachment::get(
  self : WebGPURenderPassDepthStencilAttachment,
) -> (
  GPUTextureView,
  Double?,
  String?,
  String?,
  Bool?,
  Double,
  String?,
  String?,
  Bool?,
) {
  (
    self.view,
    self.depthClearValue,
    self.depthLoadOp,
    self.depthStoreOp,
    self.depthReadOnly,
    self.stencilClearValue,
    self.stencilLoadOp,
    self.stencilStoreOp,
    self.stencilReadOnly,
  )
}

///|
/// Implements `create_render_pass_depth_stencil_attachment`.
pub fn create_render_pass_depth_stencil_attachment(
  view~ : GPUTextureView,
  depthClearValue~ : Double?,
  depthLoadOp~ : @webgpu_enums.GPULoadOp,
  depthStoreOp~ : @webgpu_enums.GPUStoreOp,
) -> WebGPURenderPassDepthStencilAttachment {
  let load_str = match depthLoadOp {
    @webgpu_enums.GPULoadOp::Clear => "clear"
    @webgpu_enums.GPULoadOp::Load => "load"
  }
  let store_str = match depthStoreOp {
    @webgpu_enums.GPUStoreOp::Store => "store"
    @webgpu_enums.GPUStoreOp::Discard => "discard"
  }
  WebGPURenderPassDepthStencilAttachment::new(
    view~,
    depthClearValue~,
    depthLoadOp=load_str,
    depthStoreOp=store_str,
    depthReadOnly=false,
  )
}
