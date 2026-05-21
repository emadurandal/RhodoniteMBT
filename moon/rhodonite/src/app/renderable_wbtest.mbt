/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "renderable component payload stores mesh and material handles" {
  let mesh = MeshHandle::{ index: 7 }
  let material = MaterialHandle::{ index: 11 }
  let bytes = renderable_component_bytes(mesh, material)
  assert_true(bytes.length() == renderable_component_stride())
  assert_true(@writes.get_u32_le(bytes, 0).reinterpret_as_int() == 7)
  assert_true(@writes.get_u32_le(bytes, 4).reinterpret_as_int() == 11)
}

///|
test "set_renderable adds and updates the component payload" {
  let world = @ecs.World::new()
  let renderable = register_renderable_component(world)
  assert_true(world.component_cpu_stride(renderable.id()) == Some(8))
  let entity = world.create_entity()
  assert_true(
    set_renderable(world, entity, renderable, MeshHandle::{ index: 1 }, MaterialHandle::{
      index: 2,
    }),
  )
  assert_true(
    set_renderable(world, entity, renderable, MeshHandle::{ index: 3 }, MaterialHandle::{
      index: 4,
    }),
  )
  match world.component_bytes(entity, renderable.id()) {
    Some(bytes) => {
      assert_true(@writes.get_u32_le(bytes, 0).reinterpret_as_int() == 3)
      assert_true(@writes.get_u32_le(bytes, 4).reinterpret_as_int() == 4)
    }
    None => abort("missing renderable bytes")
  }
}
