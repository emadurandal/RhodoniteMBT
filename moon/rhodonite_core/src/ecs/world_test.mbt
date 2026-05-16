///|
test "World exposes component metadata without exposing registry mutation" {
  let world = World::new()
  let cpu = world.register_cpu_component("MetadataCPU", 4)
  match world.component_info(cpu) {
    Some(info) => {
      assert_eq(info.name, "MetadataCPU")
      assert_eq(info.cpu_stride, 4)
    }
    None => abort("expected component metadata")
  }
  assert_eq(world.component_cpu_stride(cpu), Some(4))
  assert_true(world.component_info(ComponentTypeId::new(9999)) is None)
}

///|
test "CPU components move entities between archetypes and preserve bytes" {
  let world = World::new()
  let transform = world.register_cpu_component("TransformCPU", 4)
  let material = world.register_cpu_component("MaterialCPU", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, transform, bytes4(1, 2, 3, 4)))
  assert_true(world.add_component_bytes(entity, material, bytes4(5, 6, 7, 8)))
  assert_true(world.has_component(entity, transform))
  assert_true(world.has_component(entity, material))
  match world.component_bytes(entity, transform) {
    Some(bytes) => assert_eq(bytes, bytes4(1, 2, 3, 4))
    None => abort("missing transform bytes")
  }
  assert_true(world.remove_component(entity, transform))
  assert_true(!world.has_component(entity, transform))
  assert_true(world.has_component(entity, material))
  match world.component_bytes(entity, material) {
    Some(bytes) => assert_eq(bytes, bytes4(5, 6, 7, 8))
    None => abort("missing material bytes")
  }
}

///|
test "add_component and add_component_bytes support CPU components" {
  let world = World::new()
  let cpu = world.register_cpu_component("AddComponentCpu", 4)
  let cpu_entity = world.create_entity()
  assert_true(world.add_component(cpu_entity, cpu))
  match world.component_bytes(cpu_entity, cpu) {
    Some(bytes) => assert_eq(bytes, bytes4(0, 0, 0, 0))
    None => abort("expected AddComponentCpu bytes")
  }
  assert_true(!world.add_component(cpu_entity, cpu))
}

///|
test "add_component_bytes rejects invalid byte lengths before mutating ownership" {
  let world = World::new()
  let cpu = world.register_cpu_component("AddComponentBytesCpuStride", 4)
  let cpu_entity = world.create_entity()
  assert_true(
    !world.add_component_bytes(cpu_entity, cpu, ([1, 2, 3] : FixedArray[Byte])),
  )
  assert_true(!world.has_component(cpu_entity, cpu))
  assert_true(world.add_component_bytes(cpu_entity, cpu, bytes4(1, 2, 3, 4)))
  match world.component_bytes(cpu_entity, cpu) {
    Some(bytes) => assert_eq(bytes, bytes4(1, 2, 3, 4))
    None => abort("expected AddComponentBytesCpuStride bytes")
  }
}

///|
test "builtin Transform3D uses ComponentTypeId index 0" {
  let world = World::new()
  assert_eq(world.transform_component().index, 0)
}

///|
test "builtin GlobalTransform uses ComponentTypeId index 1" {
  let world = World::new()
  assert_eq(world.global_transform_component().index, 1)
}

///|
test "builtin ChildOf uses ComponentTypeId index 2" {
  let world = World::new()
  assert_eq(world.child_of_component().index, 2)
}

///|
test "set_component_bytes updates existing component without archetype migration" {
  let world = World::new()
  let qa = world.register_cpu_component("SetComponentA", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  match world.location(e) {
    Some(before) => {
      assert_true(world.set_component_bytes(e, qa, bytes4(9, 10, 11, 12)))
      match world.location(e) {
        Some(after) => {
          assert_eq(after.archetype_index, before.archetype_index)
          assert_eq(after.row, before.row)
        }
        None => abort("expected location after set")
      }
    }
    None => abort("expected location before set")
  }
  match world.component_bytes(e, qa) {
    Some(bytes) => assert_eq(bytes, bytes4(9, 10, 11, 12))
    None => abort("expected SetComponentA bytes")
  }
  assert_true(!world.add_component_bytes(e, qa, bytes4(0, 0, 0, 0)))
}
