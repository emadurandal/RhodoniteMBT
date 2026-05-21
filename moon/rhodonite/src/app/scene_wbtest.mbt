/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "scene infers common orbit camera component ids from registered systems" {
  let scene = Scene::new("camera")
  let world = scene.world()
  let orbit = world.register_cpu_component("RuntimeTestOrbit", 4)
  let home = world.register_cpu_component("RuntimeTestHome", 4)
  let lens = world.register_cpu_component("RuntimeTestLens", 4)
  scene.add_common_systems(
    orbit_component=Some(orbit),
    home_component=Some(home),
    lens_component=Some(lens),
  )
  assert_true(scene.inferred_common_orbit_component() == Some(orbit))
  assert_true(scene.inferred_common_home_component(Some(orbit)) == Some(home))
  assert_true(scene.inferred_common_lens_component(Some(orbit)) == Some(lens))
}
