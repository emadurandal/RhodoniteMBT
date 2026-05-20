/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Registration key for the builtin orbit camera transform system.
priv struct OrbitCameraTransformRegistration {
  phase : PhaseKey
  orbit_component : @ecs.ComponentTypeId
  home_component : @ecs.ComponentTypeId
}
