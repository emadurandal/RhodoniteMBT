///|
test "wheel dolly can zoom in to the default lower clamp" {
  let world = @ecs.World::new()
  let camera = world.create_entity()
  let component = register_orbit_camera_controller_component(world)
  assert_true(add_orbit_camera_controller(world, camera, component, 0.0, 0.0))
  let input = @input.InputState::new()
  input.enqueue_event(@input.Wheel((0.0 : Float), (-10000.0 : Float)))
  input.begin_frame()
  assert_true(
    update_orbit_camera_controller_from_input(world, camera, component, input),
  )
  let (_, _, _, _, dolly) = orbit_camera_transform(world, camera, component)
  assert_true(dolly > 0.009)
  assert_true(dolly < 0.011)
}
