/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Function registered by the engine to run inside a phase slot.
priv struct PhaseHandler {
  phase : PhaseKey
  slot : PhaseSlot
  run : (Engine, FrameState) -> Unit
}
