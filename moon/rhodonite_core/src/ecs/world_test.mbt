/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "World exposes component metadata without exposing registry mutation" {
  let world = World::new()
  let cpu = world.register_cpu_component("MetadataCPU", 4)
  match world.component_info(cpu) {
    Some(info) => {
      assert_eq(info.name, "MetadataCPU")
      assert_eq(info.cpu_stride, 4)
      assert_true(info.stable_key is None)
      assert_true(info.schema_version is None)
      assert_true(info.schema_hash is None)
    }
    None => abort("expected component metadata")
  }
  let stable = world.register_cpu_component_with_identity(
    "StableMetadataCPU",
    8,
    "com.example.StableMetadataCPU",
    Some("2"),
    Some("sha256:stable-metadata"),
  )
  match world.component_info(stable) {
    Some(info) => {
      assert_eq(info.name, "StableMetadataCPU")
      assert_eq(info.cpu_stride, 8)
      assert_true(info.stable_key == Some("com.example.StableMetadataCPU"))
      assert_true(info.schema_version == Some("2"))
      assert_true(info.schema_hash == Some("sha256:stable-metadata"))
    }
    None => abort("expected stable component metadata")
  }
  assert_true(
    world.component_by_stable_key("com.example.StableMetadataCPU") ==
    Some(stable),
  )
  assert_true(world.component_by_stable_key("com.example.Missing") is None)
  assert_true(world.component_by_stable_key("MetadataCPU") is None)
  assert_true(
    world.component_matches_identity(
      stable,
      "com.example.StableMetadataCPU",
      None,
      None,
    ),
  )
  assert_true(
    world.component_matches_identity(
      stable,
      "com.example.StableMetadataCPU",
      Some("2"),
      Some("sha256:stable-metadata"),
    ),
  )
  assert_true(
    !world.component_matches_identity(
      stable,
      "com.example.StableMetadataCPU",
      Some("3"),
      None,
    ),
  )
  assert_true(
    !world.component_matches_identity(
      stable,
      "com.example.StableMetadataCPU",
      None,
      Some("sha256:mismatch"),
    ),
  )
  assert_true(
    !world.component_matches_identity(
      cpu,
      "com.example.StableMetadataCPU",
      None,
      None,
    ),
  )
  assert_true(
    !world.component_matches_identity(
      ComponentTypeId::new(9999),
      "com.example.StableMetadataCPU",
      None,
      None,
    ),
  )
  assert_true(world.component_cpu_stride(cpu) is Some(4))
  assert_true(world.component_info(ComponentTypeId::new(9999)) is None)
}

///|
test "panic World rejects duplicate component stable keys" {
  let world = World::new()
  ignore(
    world.register_cpu_component_with_identity(
      "DuplicateStableA",
      4,
      "com.example.DuplicateStable",
      None,
      None,
    ),
  )
  ignore(
    world.register_cpu_component_with_identity(
      "DuplicateStableB",
      4,
      "com.example.DuplicateStable",
      None,
      None,
    ),
  )
}

///|
test "panic World rejects empty component stable keys" {
  let world = World::new()
  ignore(
    world.register_cpu_component_with_identity("EmptyStable", 4, "", None, None),
  )
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
    Some(bytes) => assert_true(bytes == bytes4(1, 2, 3, 4))
    None => abort("missing transform bytes")
  }
  assert_true(world.remove_component(entity, transform))
  assert_true(!world.has_component(entity, transform))
  assert_true(world.has_component(entity, material))
  match world.component_bytes(entity, material) {
    Some(bytes) => assert_true(bytes == bytes4(5, 6, 7, 8))
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
    Some(bytes) => assert_true(bytes == bytes4(0, 0, 0, 0))
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
    Some(bytes) => assert_true(bytes == bytes4(1, 2, 3, 4))
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
    Some(bytes) => assert_true(bytes == bytes4(9, 10, 11, 12))
    None => abort("expected SetComponentA bytes")
  }
  assert_true(!world.add_component_bytes(e, qa, bytes4(0, 0, 0, 0)))
}
