///|
/// Function registered by the engine to run inside a phase slot.
priv struct PhaseHandler {
  phase : PhaseKey
  slot : PhaseSlot
  run : (Engine, FrameState) -> Unit
}
