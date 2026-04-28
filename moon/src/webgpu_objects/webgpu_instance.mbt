// WebGPU instance implementation

///|
/// 他パッケージから `impl` するには `pub(open)` が必要。
/// [requestAdapter] は戻り値の具象型がバックエンドごとに異なるため、トレイトではなく各型のメソッドとして定義する。
pub(open) trait WebGPUInstance {
  getPreferredCanvasFormat(self : Self) -> String
}
