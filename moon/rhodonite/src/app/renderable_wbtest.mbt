/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "renderable component payload stores mesh and material handles" {
  let mesh = MeshHandle::{ index: 7 }
  let material = MaterialHandle::{ index: 11 }
  let flags = renderable_flags_none()
  let bytes = renderable_component_bytes(
    RenderableDesc::new(mesh, material, flags~),
  )
  assert_true(bytes.length() == renderable_component_stride())
  assert_true(@writes.get_u32_le(bytes, 0).reinterpret_as_int() == 7)
  assert_true(@writes.get_u32_le(bytes, 4).reinterpret_as_int() == 11)
  assert_true(@writes.get_u32_le(bytes, 8) == 0U)
  assert_true(@writes.get_u32_le(bytes, 12) == 0U)
}

///|
test "renderable flags report visible participation" {
  assert_true(renderable_flags_default().contains(renderable_flags_visible()))
  assert_true(!renderable_flags_none().contains(renderable_flags_visible()))
}

///|
test "renderable description exposes constructor accessors" {
  let mesh = MeshHandle::{ index: 2 }
  let material = MaterialHandle::{ index: 5 }
  let flags = renderable_flags_none()
  let desc = RenderableDesc::new(mesh, material, flags~)
  assert_true(desc.mesh() == mesh)
  assert_true(desc.material() == material)
  assert_true(desc.flags() == flags)
}

///|
test "set_renderable adds and updates the component payload" {
  let world = @ecs.World::new()
  let renderable = register_renderable_component(world)
  assert_true(world.component_cpu_stride(renderable.id()) == Some(16))
  let entity = world.create_entity()
  assert_true(
    set_renderable(
      world,
      entity,
      renderable,
      RenderableDesc::new(MeshHandle::{ index: 1 }, MaterialHandle::{ index: 2 }),
    ),
  )
  assert_true(
    set_renderable(
      world,
      entity,
      renderable,
      RenderableDesc::new(
        MeshHandle::{ index: 3 },
        MaterialHandle::{ index: 4 },
        flags=renderable_flags_none(),
      ),
    ),
  )
  match world.component_bytes(entity, renderable.id()) {
    Some(bytes) => {
      assert_true(@writes.get_u32_le(bytes, 0).reinterpret_as_int() == 3)
      assert_true(@writes.get_u32_le(bytes, 4).reinterpret_as_int() == 4)
      assert_true(
        !renderable_flags_from_view(bytes).contains(renderable_flags_visible()),
      )
    }
    None => abort("missing renderable bytes")
  }
}
