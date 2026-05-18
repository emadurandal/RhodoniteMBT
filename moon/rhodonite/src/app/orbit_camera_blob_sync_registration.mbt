///|
/// Registration key for the builtin orbit camera Camera blob sync system.
priv struct OrbitCameraBlobSyncRegistration {
  phase : PhaseKey
  orbit_component : @ecs.ComponentTypeId
  lens_component : @ecs.ComponentTypeId
}
