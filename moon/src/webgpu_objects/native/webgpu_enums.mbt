///|
/// WebGPU `GPULoadOp` (`"load"` \| `"clear"`).
pub(all) enum GPULoadOp {
  Load
  Clear
} derive(Eq)

///|
/// WebGPU `GPUStoreOp` (`"store"` \| `"discard"`).
pub(all) enum GPUStoreOp {
  Store
  Discard
} derive(Eq)

///|
pub fn gpu_load_op_load() -> GPULoadOp {
  GPULoadOp::Load
}

///|
pub fn gpu_load_op_clear() -> GPULoadOp {
  GPULoadOp::Clear
}

///|
pub fn gpu_store_op_store() -> GPUStoreOp {
  GPUStoreOp::Store
}

///|
pub fn gpu_store_op_discard() -> GPUStoreOp {
  GPUStoreOp::Discard
}
