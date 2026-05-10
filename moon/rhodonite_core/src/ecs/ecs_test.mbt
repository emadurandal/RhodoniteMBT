///|
fn bytes4(a : Byte, b : Byte, c : Byte, d : Byte) -> FixedArray[Byte] {
  ([a, b, c, d] : FixedArray[Byte])
}

///|
fn gpu_bytes_with_u32(value : UInt) -> FixedArray[Byte] {
  let bytes = @comp.gpu_component_bytes(16)
  @comp.put_gpu_u32(bytes, 0, value)
  bytes
}

///|
test "EntityId generation invalidates stale handles and reuses gpu index" {
  let world = World::new()
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  assert_true(world.is_alive(e0))
  assert_true(world.is_alive(e1))
  assert_true(world.destroy_entity(e0))
  assert_true(!world.is_alive(e0))
  let e2 = world.create_entity()
  assert_eq(e2.index, e0.index)
  assert_eq(e2.generation, e0.generation + 1)
  assert_eq(e2.gpu_index(), e0.index)
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
test "std140-compatible layout pads vec3 fields to 16 bytes" {
  let fields : Array[(String, @comp.GpuFieldKind)] = [
    ("roughness", @comp.F32),
    ("position", @comp.Vec3F32),
    ("material_id", @comp.U32),
  ]
  let layout = @comp.GpuLayout::std140(fields)
  assert_true(layout.is_valid())
  assert_eq(layout.fields[0].offset, 0)
  assert_eq(layout.fields[1].offset, 16)
  assert_eq(layout.fields[1].size, 16)
  assert_eq(layout.fields[2].offset, 32)
  assert_eq(layout.stride, 48)
}

///|
test "GPU visible components stay flat by EntityId index and drain only dirty ranges" {
  let world = World::new()
  let gpu = world.register_gpu_component(
    "GpuMaterial",
    @comp.GpuLayout::empty(16),
  )
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  let _ = world.create_entity()
  let e3 = world.create_entity()
  let _ = world.drain_resize_events()
  assert_true(world.set_gpu_component_bytes(e0, gpu, gpu_bytes_with_u32(10U)))
  assert_true(world.set_gpu_component_bytes(e1, gpu, gpu_bytes_with_u32(11U)))
  assert_true(world.set_gpu_component_bytes(e3, gpu, gpu_bytes_with_u32(13U)))
  let writes = world.drain_gpu_writes(gpu)
  assert_eq(writes.length(), 2)
  assert_eq(writes[0].byte_offset, e0.index * 16)
  assert_eq(writes[0].bytes.length(), 32)
  assert_eq(writes[0].bytes[0], (10U & 0xFFU).to_byte())
  assert_eq(writes[0].bytes[16], (11U & 0xFFU).to_byte())
  assert_eq(writes[1].byte_offset, e3.index * 16)
  assert_eq(writes[1].bytes.length(), 16)
  assert_eq(writes[1].bytes[0], (13U & 0xFFU).to_byte())
  assert_eq(world.drain_gpu_writes(gpu).length(), 0)
}

///|
test "GPU dirty list deduplicates repeated entity writes and keeps latest bytes" {
  let world = World::new()
  let gpu = world.register_gpu_component(
    "GpuTransform",
    @comp.GpuLayout::empty(16),
  )
  let entity = world.create_entity()
  let _ = world.drain_resize_events()
  assert_true(
    world.set_gpu_component_bytes(entity, gpu, gpu_bytes_with_u32(1U)),
  )
  assert_true(
    world.set_gpu_component_bytes(entity, gpu, gpu_bytes_with_u32(2U)),
  )
  let writes = world.drain_gpu_writes(gpu)
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, entity.index * 16)
  assert_eq(writes[0].bytes.length(), 16)
  assert_eq(writes[0].bytes[0], (2U & 0xFFU).to_byte())
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
test "Transform3D identity roundtrip bytes and World set/get" {
  let world = World::new()
  let tf = world.transform_component()
  let entity = world.create_entity()
  let _ = world.drain_resize_events()
  let t = @comp.Transform3D::identity()
  assert_true(world.set_transform(entity, t))
  match world.get_transform(entity) {
    Some(got) => {
      assert_eq(got.position.x(), t.position.x())
      assert_eq(got.rotation.w(), t.rotation.w())
      assert_eq(got.scale.x(), t.scale.x())
    }
    None => abort("expected Transform3D")
  }
  assert_eq(world.drain_gpu_writes(tf).length(), 0)
  assert_eq(
    world.drain_gpu_writes(world.global_transform_component()).length(),
    0,
  )
}

///|
test "GlobalTransform identity roundtrip and GPU drain" {
  let world = World::new()
  let gt_id = world.global_transform_component()
  let entity = world.create_entity()
  let _ = world.drain_resize_events()
  let g = @comp.GlobalTransform::identity()
  assert_true(world.set_global_transform(entity, g))
  match world.get_global_transform(entity) {
    Some(read) => assert_eq(read.matrix, g.matrix)
    None => abort("expected GlobalTransform")
  }
  let writes = world.drain_gpu_writes(gt_id)
  assert_eq(writes.length(), 1)
}

///|
test "get_gpu_f32 reads put_gpu_f32" {
  let buf = @comp.gpu_component_bytes(16)
  @comp.put_gpu_f32(buf, 4, 2.5)
  assert_eq(@comp.get_gpu_f32(buf, 4), 2.5)
}
