/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Registration key for the builtin orbit camera Camera blob sync system.
priv struct OrbitCameraBlobSyncRegistration {
  phase : PhaseKey
  orbit_component : @ecs.ComponentTypeId
  lens_component : @ecs.ComponentTypeId
}
