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
  let scene = Scene::new("renderable")
  let world = scene.world()
  assert_true(
    world.component_cpu_stride(scene.renderable_component_id) == Some(16),
  )
  let entity = world.create_entity()
  assert_true(
    set_renderable(
      scene,
      entity,
      RenderableDesc::new(MeshHandle::{ index: 1 }, MaterialHandle::{ index: 2 }),
    ),
  )
  assert_true(
    set_renderable(
      scene,
      entity,
      RenderableDesc::new(
        MeshHandle::{ index: 3 },
        MaterialHandle::{ index: 4 },
        flags=renderable_flags_none(),
      ),
    ),
  )
  match world.component_bytes(entity, scene.renderable_component_id) {
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

///|
test "WorldHistory undoes and redoes Renderable add remove and set bytes" {
  let scene = Scene::new("renderable-history")
  let world = scene.world()
  let history = @ecs.WorldHistory::new()
  let component = scene.renderable_component_id
  let entity = world.create_entity()
  let first = renderable_component_bytes(
    RenderableDesc::new(MeshHandle::{ index: 1 }, MaterialHandle::{ index: 2 }),
  )
  let second = renderable_component_bytes(
    RenderableDesc::new(
      MeshHandle::{ index: 3 },
      MaterialHandle::{ index: 4 },
      flags=renderable_flags_none(),
    ),
  )
  assert_true(history.add_component_bytes(world, entity, component, first))
  assert_true(world.component_bytes(entity, component) == Some(first))
  assert_true(history.undo(world))
  assert_true(!world.has_component(entity, component))
  assert_true(history.redo(world))
  assert_true(world.component_bytes(entity, component) == Some(first))
  assert_true(history.set_component_bytes(world, entity, component, second))
  assert_true(world.component_bytes(entity, component) == Some(second))
  assert_true(history.undo(world))
  assert_true(world.component_bytes(entity, component) == Some(first))
  assert_true(history.redo(world))
  assert_true(world.component_bytes(entity, component) == Some(second))
  assert_true(history.remove_component(world, entity, component))
  assert_true(!world.has_component(entity, component))
  assert_true(history.undo(world))
  assert_true(world.component_bytes(entity, component) == Some(second))
}
