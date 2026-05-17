///|
/// Registration key for the builtin orbit camera transform system.
priv struct OrbitCameraTransformRegistration {
  phase : PhaseKey
  orbit_component : @ecs.ComponentTypeId
  home_component : @ecs.ComponentTypeId
}
