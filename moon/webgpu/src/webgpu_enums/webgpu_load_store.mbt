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
