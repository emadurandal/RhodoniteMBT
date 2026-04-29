// WebGPU render pass depth stencil attachment implementation

///|
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
pub fn WebGPURenderPassDepthStencilAttachment::new(
  view~ : GPUTextureView,
  depthClearValue? : Double,
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
