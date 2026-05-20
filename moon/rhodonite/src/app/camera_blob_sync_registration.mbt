/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Registration key for the builtin Camera blob sync system.
priv struct CameraBlobSyncRegistration {
  phase : PhaseKey
  lens_component : @ecs.ComponentTypeId
}
