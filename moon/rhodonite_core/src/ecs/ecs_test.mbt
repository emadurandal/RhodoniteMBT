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
fn transform3d_bytes_identity() -> FixedArray[Byte] {
  let layout = @comp.transform3d_gpu_layout()
  let buf = @comp.gpu_component_bytes(layout.stride)
  let f = layout.fields
  if f.length() != 3 {
    abort("transform3d layout")
  }
  @comp.put_gpu_f32(buf, f[0].offset + 0, 0.0)
  @comp.put_gpu_f32(buf, f[0].offset + 4, 0.0)
  @comp.put_gpu_f32(buf, f[0].offset + 8, 0.0)
  @comp.put_gpu_f32(buf, f[1].offset + 0, 0.0)
  @comp.put_gpu_f32(buf, f[1].offset + 4, 0.0)
  @comp.put_gpu_f32(buf, f[1].offset + 8, 0.0)
  @comp.put_gpu_f32(buf, f[1].offset + 12, 1.0)
  @comp.put_gpu_f32(buf, f[2].offset + 0, 1.0)
  @comp.put_gpu_f32(buf, f[2].offset + 4, 1.0)
  @comp.put_gpu_f32(buf, f[2].offset + 8, 1.0)
  buf
}

///|
fn transform3d_bytes_translation(
  x : Float,
  y : Float,
  z : Float,
) -> FixedArray[Byte] {
  let layout = @comp.transform3d_gpu_layout()
  let buf = @comp.gpu_component_bytes(layout.stride)
  let f = layout.fields
  if f.length() != 3 {
    abort("transform3d layout")
  }
  @comp.put_gpu_f32(buf, f[0].offset + 0, x.to_double())
  @comp.put_gpu_f32(buf, f[0].offset + 4, y.to_double())
  @comp.put_gpu_f32(buf, f[0].offset + 8, z.to_double())
  @comp.put_gpu_f32(buf, f[1].offset + 0, 0.0)
  @comp.put_gpu_f32(buf, f[1].offset + 4, 0.0)
  @comp.put_gpu_f32(buf, f[1].offset + 8, 0.0)
  @comp.put_gpu_f32(buf, f[1].offset + 12, 1.0)
  @comp.put_gpu_f32(buf, f[2].offset + 0, 1.0)
  @comp.put_gpu_f32(buf, f[2].offset + 4, 1.0)
  @comp.put_gpu_f32(buf, f[2].offset + 8, 1.0)
  buf
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
test "World exposes component metadata without exposing registry mutation" {
  let world = World::new()
  let cpu = world.register_cpu_component("MetadataCPU", 4)
  let gpu_layout = @comp.global_transform_gpu_layout()
  let gpu = world.register_gpu_component("MetadataGPU", gpu_layout)
  match world.component_info(cpu) {
    Some(info) => {
      assert_eq(info.name, "MetadataCPU")
      assert_true(info.kind == CpuOnly)
      assert_eq(info.cpu_stride, 4)
      assert_true(info.gpu_layout is None)
    }
    None => abort("expected CPU component metadata")
  }
  match world.component_info(gpu) {
    Some(info) => {
      assert_eq(info.name, "MetadataGPU")
      assert_true(info.kind == GpuVisible)
      assert_eq(info.cpu_stride, 0)
      match info.gpu_layout {
        Some(layout) => assert_eq(layout.stride, gpu_layout.stride)
        None => abort("expected GPU layout")
      }
    }
    None => abort("expected GPU component metadata")
  }
  assert_eq(world.component_cpu_stride(cpu), Some(4))
  assert_eq(world.component_cpu_stride(gpu), Some(0))
  match world.component_gpu_layout(gpu) {
    Some(layout) => assert_eq(layout.stride, gpu_layout.stride)
    None => abort("expected GPU layout")
  }
  assert_true(world.component_gpu_layout(cpu) is None)
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
  assert_true(world.add_component(e0, gpu))
  assert_true(world.add_component(e1, gpu))
  assert_true(world.add_component(e3, gpu))
  let _ = world.drain_resize_events()
  assert_true(world.set_component_bytes(e0, gpu, gpu_bytes_with_u32(10U)))
  assert_true(world.set_component_bytes(e1, gpu, gpu_bytes_with_u32(11U)))
  assert_true(world.set_component_bytes(e3, gpu, gpu_bytes_with_u32(13U)))
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
test "GPU visible active indices stay packed across removal and destroy" {
  let world = World::new()
  let gpu = world.register_gpu_component(
    "GpuActivePacked",
    @comp.GpuLayout::empty(16),
  )
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  let e2 = world.create_entity()
  assert_true(world.add_component(e0, gpu))
  assert_true(world.add_component(e1, gpu))
  assert_true(world.add_component(e2, gpu))
  assert_eq(world.gpu_component_active_indices(gpu).length(), 3)
  assert_true(world.remove_component(e1, gpu))
  let after_remove = world.gpu_component_active_indices(gpu)
  assert_eq(after_remove.length(), 2)
  assert_true(after_remove[0] == e0.index || after_remove[1] == e0.index)
  assert_true(after_remove[0] == e2.index || after_remove[1] == e2.index)
  assert_true(world.destroy_entity(e0))
  let after_destroy = world.gpu_component_active_indices(gpu)
  assert_eq(after_destroy.length(), 1)
  assert_eq(after_destroy[0], e2.index)
}

///|
test "GPU dirty list deduplicates repeated entity writes and keeps latest bytes" {
  let world = World::new()
  let gpu = world.register_gpu_component(
    "GpuTransform",
    @comp.GpuLayout::empty(16),
  )
  let entity = world.create_entity()
  assert_true(world.add_component(entity, gpu))
  let _ = world.drain_resize_events()
  assert_true(world.set_component_bytes(entity, gpu, gpu_bytes_with_u32(1U)))
  assert_true(world.set_component_bytes(entity, gpu, gpu_bytes_with_u32(2U)))
  let writes = world.drain_gpu_writes(gpu)
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, entity.index * 16)
  assert_eq(writes[0].bytes.length(), 16)
  assert_eq(writes[0].bytes[0], (2U & 0xFFU).to_byte())
}

///|
test "GPU visible public APIs require entity component ownership" {
  let world = World::new()
  let gpu = world.register_gpu_component(
    "GpuOwnership",
    @comp.GpuLayout::empty(16),
  )
  let entity = world.create_entity()
  assert_true(!world.set_component_bytes(entity, gpu, gpu_bytes_with_u32(7U)))
  assert_true(!world.clear_gpu_component(entity, gpu))
  assert_true(world.component_bytes(entity, gpu) is None)
  assert_eq(world.drain_gpu_writes(gpu).length(), 0)
}

///|
test "removing GPU visible component clears and dirties flat slot" {
  let world = World::new()
  let gpu = world.register_gpu_component(
    "GpuRemoveClears",
    @comp.GpuLayout::empty(16),
  )
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, gpu, gpu_bytes_with_u32(77U)))
  let _ = world.drain_resize_events()
  let _ = world.drain_gpu_writes(gpu)
  assert_true(world.remove_component(entity, gpu))
  assert_true(!world.has_component(entity, gpu))
  assert_true(world.component_bytes(entity, gpu) is None)
  let writes = world.drain_gpu_writes(gpu)
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, entity.index * 16)
  assert_eq(writes[0].bytes.length(), 16)
  for i = 0; i < writes[0].bytes.length(); i = i + 1 {
    assert_eq(writes[0].bytes[i], (0 : Byte))
  }
}

///|
test "add_component and add_component_bytes support CPU and GPU visible components" {
  let world = World::new()
  let cpu = world.register_cpu_component("AddComponentCpu", 4)
  let gpu = world.register_gpu_component(
    "AddComponentGpu",
    @comp.GpuLayout::empty(16),
  )
  let cpu_entity = world.create_entity()
  let gpu_entity = world.create_entity()
  assert_true(world.add_component(cpu_entity, cpu))
  match world.component_bytes(cpu_entity, cpu) {
    Some(bytes) => assert_eq(bytes, bytes4(0, 0, 0, 0))
    None => abort("expected AddComponentCpu bytes")
  }
  assert_true(
    world.add_component_bytes(gpu_entity, gpu, gpu_bytes_with_u32(44U)),
  )
  match world.component_bytes(gpu_entity, gpu) {
    Some(bytes) => assert_eq(bytes[0], (44U & 0xFFU).to_byte())
    None => abort("expected AddComponentGpu bytes")
  }
  assert_true(!world.add_component(cpu_entity, cpu))
  assert_true(!world.set_component_bytes(gpu_entity, gpu, bytes4(1, 2, 3, 4)))
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
  let gpu_entity = world.create_entity()
  let _ = world.drain_resize_events()
  let gpu = world.register_gpu_component(
    "AddComponentBytesGpuStride",
    @comp.GpuLayout::empty(16),
  )
  assert_true(!world.add_component_bytes(gpu_entity, gpu, bytes4(5, 6, 7, 8)))
  assert_true(!world.has_component(gpu_entity, gpu))
  assert_eq(world.drain_resize_events().length(), 0)
  assert_true(
    world.add_component_bytes(gpu_entity, gpu, gpu_bytes_with_u32(55U)),
  )
  match world.component_bytes(gpu_entity, gpu) {
    Some(bytes) => assert_eq(bytes[0], (55U & 0xFFU).to_byte())
    None => abort("expected AddComponentBytesGpuStride bytes")
  }
}

///|
test "add_component emits resize events through centralized GPU capacity path" {
  let world = World::new()
  let entity = world.create_entity()
  let _ = world.drain_resize_events()
  let gpu = world.register_gpu_component(
    "GpuResizeAfterEntity",
    @comp.GpuLayout::empty(16),
  )
  assert_true(world.add_component(entity, gpu))
  let events = world.drain_resize_events()
  assert_eq(events.length(), 1)
  assert_true(events[0].component == gpu)
  assert_eq(events[0].required_capacity, entity.index + 1)
  assert_true(events[0].needs_full_upload)
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
test "ChildOf roundtrips parent EntityId" {
  let world = World::new()
  let parent = world.create_entity()
  let child = world.create_entity()
  assert_true(world.set_child_of(child, parent))
  match world.get_child_of(child) {
    Some(p) => {
      assert_eq(p.index, parent.index)
      assert_eq(p.generation, parent.generation)
    }
    None => abort("expected ChildOf")
  }
}

///|
test "Transform3D identity roundtrip bytes and World set/get" {
  let world = World::new()
  let tf = world.transform_component()
  let entity = world.create_entity()
  let _ = world.drain_resize_events()
  let buf = transform3d_bytes_identity()
  let n = buf.length()
  let t = @comp.Transform3D::from_component_mut_view(
    buf.mut_view(start=0, end=n),
  )
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
test "Transform3D writes position through zero-copy component view" {
  let buf = transform3d_bytes_identity()
  let n = buf.length()
  let row = buf.mut_view(start=0, end=n)
  @comp.Transform3D::write_position_to_component_mut_view(
    row,
    (2.0 : Float),
    (3.0 : Float),
    (4.0 : Float),
  )
  let t = @comp.Transform3D::from_component_mut_view(row)
  assert_eq(t.position.x(), (2.0 : Float))
  assert_eq(t.position.y(), (3.0 : Float))
  assert_eq(t.position.z(), (4.0 : Float))
  t.position.set((5.0 : Float), (6.0 : Float), (7.0 : Float))
  assert_eq(t.position.x(), (5.0 : Float))
  assert_eq(t.position.y(), (6.0 : Float))
  assert_eq(t.position.z(), (7.0 : Float))
}

///|
test "GlobalTransform identity roundtrip and GPU drain" {
  let world = World::new()
  let gt_id = world.global_transform_component()
  let entity = world.create_entity()
  let _ = world.drain_resize_events()
  let expected = @m44.Matrix44F::identity()
  assert_true(world.set_global_transform(entity, expected))
  match world.get_global_transform(entity) {
    Some(read) => assert_eq(read, expected)
    None => abort("expected Matrix44F")
  }
  let writes = world.drain_gpu_writes(gt_id)
  assert_eq(writes.length(), 1)
}

///|
test "get_gpu_f32 reads put_gpu_f32" {
  let buf = @comp.gpu_component_bytes(16)
  @comp.put_gpu_f32(buf, 4, 2.5)
  assert_eq(@comp.get_gpu_f32(buf, 4), (2.5 : Float))
}

///|
test "compute_global_transform uses Transform3D only without ChildOf" {
  let world = World::new()
  let e = world.create_entity()
  let buf = transform3d_bytes_translation(
    (2.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let n = buf.length()
  let tf = @comp.Transform3D::from_component_mut_view(
    buf.mut_view(start=0, end=n),
  )
  assert_true(world.set_transform(e, tf))
  match world.compute_global_transform(e) {
    Some(m) => {
      assert_eq(m.at(0, 3), (2.0 : Float))
      assert_eq(m.at(1, 3), (0.0 : Float))
      assert_eq(m.at(2, 3), (0.0 : Float))
    }
    None => abort("expected Matrix44F")
  }
}

///|
test "compute_global_transform multiplies parent chain" {
  let world = World::new()
  let parent = world.create_entity()
  let child = world.create_entity()
  let buf_p = transform3d_bytes_translation(
    (10.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let np = buf_p.length()
  let tf_p = @comp.Transform3D::from_component_mut_view(
    buf_p.mut_view(start=0, end=np),
  )
  let buf_c = transform3d_bytes_translation(
    (5.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let nc = buf_c.length()
  let tf_c = @comp.Transform3D::from_component_mut_view(
    buf_c.mut_view(start=0, end=nc),
  )
  assert_true(world.set_transform(parent, tf_p))
  assert_true(world.set_transform(child, tf_c))
  assert_true(world.set_child_of(child, parent))
  match world.compute_global_transform(child) {
    Some(m) => {
      assert_eq(m.at(0, 3), (15.0 : Float))
      assert_eq(m.at(1, 3), (0.0 : Float))
      assert_eq(m.at(2, 3), (0.0 : Float))
    }
    None => abort("expected Matrix44F")
  }
}

///|
test "compute_global_transform returns None without Transform3D" {
  let world = World::new()
  let e = world.create_entity()
  assert_true(world.compute_global_transform(e) is None)
}

///|
test "compute_global_transform returns None on ChildOf cycle" {
  let world = World::new()
  let a = world.create_entity()
  let b = world.create_entity()
  let buf = transform3d_bytes_identity()
  let n = buf.length()
  let tf = @comp.Transform3D::from_component_mut_view(
    buf.mut_view(start=0, end=n),
  )
  assert_true(world.set_transform(a, tf))
  assert_true(world.set_transform(b, tf))
  assert_true(world.set_child_of(a, b))
  assert_true(world.set_child_of(b, a))
  assert_true(world.compute_global_transform(a) is None)
}

///|
test "Query for_each matches supersets and skips empty required" {
  let world = World::new()
  let qa = world.register_cpu_component("QueryA", 4)
  let qb = world.register_cpu_component("QueryB", 4)
  let e_both = world.create_entity()
  assert_true(world.add_component_bytes(e_both, qa, bytes4(1, 2, 3, 4)))
  assert_true(world.add_component_bytes(e_both, qb, bytes4(5, 6, 7, 8)))
  let e_only_a = world.create_entity()
  assert_true(world.add_component_bytes(e_only_a, qa, bytes4(9, 10, 11, 12)))
  ignore(e_only_a)
  let hits : Array[EntityId] = []
  Query::new([qa, qb]).for_each(world, row => {
    hits.push(row.entity())
    row.read(qa, bytes => ignore(bytes))
    row.read(qb, bytes => ignore(bytes))
  })
  assert_eq(hits.length(), 1)
  assert_true(hits[0] == e_both)
  let empty_hits : Array[EntityId] = []
  Query::new([]).for_each(world, row => empty_hits.push(row.entity()))
  assert_eq(empty_hits.length(), 0)
  // Query scope has ended, so normal structural mutation should work again.
  let e_after_query = world.create_entity()
  assert_true(
    world.add_component_bytes(e_after_query, qa, bytes4(13, 14, 15, 16)),
  )
}

///|
test "Query for_each gives full GpuComponentStore row for GpuVisible" {
  let world = World::new()
  let qa = world.register_cpu_component("QueryA", 4)
  let gpu16 = world.register_gpu_component("Gpu16", @comp.GpuLayout::empty(16))
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  let empty : FixedArray[Byte] = FixedArray::make(0, (0 : Byte))
  assert_true(world.add_component_bytes(e, gpu16, empty))
  let _ = world.drain_resize_events()
  let mut got0 = -1
  let mut got1 = -1
  Query::new([qa, gpu16]).for_each(world, row => {
    row.read(qa, bytes => got0 = bytes.length())
    row.read(gpu16, bytes => got1 = bytes.length())
  })
  assert_eq(got0, 4)
  assert_eq(got1, 16)
}

///|
test "Query write queues dirty gpu row from direct query" {
  let world = World::new()
  let qa = world.register_cpu_component("QueryDirtyA", 4)
  let gpu16 = world.register_gpu_component(
    "QueryDirtyGpu16",
    @comp.GpuLayout::empty(16),
  )
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  let empty : FixedArray[Byte] = FixedArray::make(0, (0 : Byte))
  assert_true(world.add_component_bytes(e, gpu16, empty))
  let _ = world.drain_resize_events()
  let _ = world.drain_gpu_writes(gpu16)
  Query::new([qa, gpu16]).for_each(world, row => {
    row.write(gpu16, bytes => bytes[0] = (99 : Byte))
  })
  let writes = world.drain_gpu_writes(gpu16)
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, e.index * 16)
  assert_eq(writes[0].bytes.length(), 16)
  assert_eq(writes[0].bytes[0], (99 : Byte))
}

///|
test "Query for_each wraps required row iteration" {
  let world = World::new()
  let qa = world.register_cpu_component("QueryHelperA", 4)
  let qb = world.register_cpu_component("QueryHelperB", 4)
  let required : Array[ComponentTypeId] = [qa, qb]
  let query = Query::new(required)
  required[0] = qb
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  assert_true(world.add_component_bytes(e, qb, bytes4(5, 6, 7, 8)))
  let hits : Array[EntityId] = []
  let mut first_len = -1
  let mut second_first_byte = (0 : Byte)
  query.for_each(world, row => {
    hits.push(row.entity())
    row.read(qa, bytes => first_len = bytes.length())
    row.read(qb, bytes => second_first_byte = bytes[0])
  })
  assert_eq(hits.length(), 1)
  assert_true(hits[0] == e)
  assert_eq(first_len, 4)
  assert_eq(second_first_byte, (5 : Byte))
}

///|
test "Query write queues dirty gpu row from helper query" {
  let world = World::new()
  let qa = world.register_cpu_component("QueryHelperDirtyA", 4)
  let gpu16 = world.register_gpu_component(
    "QueryHelperDirtyGpu16",
    @comp.GpuLayout::empty(16),
  )
  let query = Query::new([qa, gpu16])
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  let empty : FixedArray[Byte] = FixedArray::make(0, (0 : Byte))
  assert_true(world.add_component_bytes(e, gpu16, empty))
  let _ = world.drain_resize_events()
  let _ = world.drain_gpu_writes(gpu16)
  query.for_each(world, row => row.write(gpu16, bytes => bytes[0] = (77 : Byte)))
  let writes = world.drain_gpu_writes(gpu16)
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, e.index * 16)
  assert_eq(writes[0].bytes[0], (77 : Byte))
}

///|
test "QueryRow closure access uses component ids" {
  let world = World::new()
  let qa = world.register_cpu_component("QueryRowA", 4)
  let qb = world.register_cpu_component("QueryRowB", 4)
  let query = Query::new([qa, qb])
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  assert_true(world.add_component_bytes(e, qb, bytes4(5, 6, 7, 8)))
  let hits : Array[EntityId] = []
  let mut a_first = (0 : Byte)
  let mut b_first = (0 : Byte)
  query.for_each(world, row => {
    hits.push(row.entity())
    if !row.has(qa) {
      abort("expected QueryRowA")
    }
    if !row.has(qb) {
      abort("expected QueryRowB")
    }
    row.read(qa, bytes => a_first = bytes[0])
    row.read(qb, bytes => b_first = bytes[0])
    row.write(qb, bytes => bytes[0] = (42 : Byte))
  })
  assert_eq(hits.length(), 1)
  assert_true(hits[0] == e)
  assert_eq(a_first, (1 : Byte))
  assert_eq(b_first, (5 : Byte))
  match world.component_bytes(e, qb) {
    Some(bytes) => assert_eq(bytes[0], (42 : Byte))
    None => abort("expected QueryRowB bytes")
  }
}

///|
test "RawQuery for_each_archetype exposes contiguous CPU columns" {
  let world = World::new()
  let qa = world.register_cpu_component("QueryArchA", 4)
  let qb = world.register_cpu_component("QueryArchB", 4)
  let query = RawQuery::new([qa, qb])
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(1, 2, 3, 4)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(10, 11, 12, 13)))
  assert_true(world.add_component_bytes(e1, qa, bytes4(5, 6, 7, 8)))
  assert_true(world.add_component_bytes(e1, qb, bytes4(20, 21, 22, 23)))
  let mut archetype_count = 0
  let mut row_count = 0
  let mut saw_qa = false
  let mut saw_qb = false
  let mut stride_qa = -1
  query.for_each_archetype(world, chunk => {
    archetype_count = archetype_count + 1
    saw_qa = chunk.has(qa)
    saw_qb = chunk.has(qb)
    stride_qa = chunk.component_stride(qa)
    let a = chunk.read_column(qa)
    let b = chunk.write_column(qb)
    for row = 0; row < chunk.length(); row = row + 1 {
      let base = row * 4
      b[base] = a[base]
      row_count = row_count + 1
    }
  })
  assert_eq(archetype_count, 1)
  assert_eq(row_count, 2)
  assert_true(saw_qa)
  assert_true(saw_qb)
  assert_eq(stride_qa, 4)
  match world.component_bytes(e0, qb) {
    Some(bytes) => assert_eq(bytes[0], (1 : Byte))
    None => abort("expected QueryArchB bytes")
  }
  match world.component_bytes(e1, qb) {
    Some(bytes) => assert_eq(bytes[0], (5 : Byte))
    None => abort("expected QueryArchB bytes")
  }
}

///|
test "RawQueryArchetype column views expose logical rows after column capacity growth" {
  let world = World::new()
  let qa = world.register_cpu_component("QueryArchCapacityA", 4)
  let qb = world.register_cpu_component("QueryArchCapacityB", 4)
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  let e2 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(10, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qa, bytes4(2, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qb, bytes4(20, 0, 0, 0)))
  assert_true(world.add_component_bytes(e2, qa, bytes4(3, 0, 0, 0)))
  assert_true(world.add_component_bytes(e2, qb, bytes4(30, 0, 0, 0)))
  assert_true(world.destroy_entity(e1))
  let query = RawQuery::new([qa, qb])
  let mut row_count = -1
  let mut column_len = -1
  query.for_each_archetype(world, chunk => {
    row_count = chunk.length()
    column_len = chunk.read_column(qa).length()
  })
  assert_eq(row_count, 2)
  assert_eq(column_len, 8)
}

///|
test "RawPreparedQuery rebuilds after structural changes create matching archetype" {
  let world = World::new()
  let qa = world.register_cpu_component("PreparedQueryA", 4)
  let qb = world.register_cpu_component("PreparedQueryB", 4)
  let query = RawQuery::new([qa, qb])
  let prepared = query.prepare(world)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  assert_true(world.add_component_bytes(e, qb, bytes4(5, 6, 7, 8)))
  let mut row_count = 0
  let mut first_a = (0 : Byte)
  prepared.for_each_archetype(world, chunk => {
    row_count = row_count + chunk.length()
    first_a = chunk.read_column(qa)[0]
  })
  assert_eq(row_count, 1)
  assert_eq(first_a, (1 : Byte))
}

///|
test "PreparedQuery for_each rebuilds stale row plan" {
  let world = World::new()
  let qa = world.register_cpu_component("PreparedQueryRowA", 4)
  let qb = world.register_cpu_component("PreparedQueryRowB", 4)
  let prepared = Query::new([qa, qb]).prepare(world)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(3, 0, 0, 0)))
  assert_true(world.add_component_bytes(e, qb, bytes4(4, 0, 0, 0)))
  let mut sum = 0
  prepared.for_each(world, row => {
    row.read(qa, bytes => sum = sum + bytes[0].to_int())
    row.read(qb, bytes => sum = sum + bytes[0].to_int())
  })
  assert_eq(sum, 7)
}

///|
test "World with_gpu_component_write_range marks one contiguous upload" {
  let world = World::new()
  let gpu16 = world.register_gpu_component(
    "GpuBulkRange16",
    @comp.GpuLayout::empty(16),
  )
  let ok = world.with_gpu_component_write_range(gpu16, 2, 3, range => {
    if range.first_entity_index() != 2 {
      abort("expected first entity index 2")
    }
    if range.count() != 3 {
      abort("expected range count 3")
    }
    if range.stride() != 16 {
      abort("expected stride 16")
    }
    let bytes = range.bytes()
    bytes[0] = (11 : Byte)
    bytes[16] = (22 : Byte)
    bytes[32] = (33 : Byte)
  })
  assert_true(ok)
  let writes = world.drain_gpu_writes(gpu16)
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, 2 * 16)
  assert_eq(writes[0].bytes.length(), 3 * 16)
  assert_eq(writes[0].bytes[0], (11 : Byte))
  assert_eq(writes[0].bytes[16], (22 : Byte))
  assert_eq(writes[0].bytes[32], (33 : Byte))
}

///|
test "World drain_gpu_write_views returns borrowed contiguous upload" {
  let world = World::new()
  let gpu16 = world.register_gpu_component(
    "GpuBulkView16",
    @comp.GpuLayout::empty(16),
  )
  let ok = world.with_gpu_component_write_range(gpu16, 1, 2, range => {
    let bytes = range.bytes()
    bytes[0] = (44 : Byte)
    bytes[16] = (55 : Byte)
  })
  assert_true(ok)
  let writes = world.drain_gpu_write_views(gpu16)
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, 16)
  assert_eq(writes[0].bytes.length(), 32)
  assert_eq(writes[0].bytes[0], (44 : Byte))
  assert_eq(writes[0].bytes[16], (55 : Byte))
  assert_eq(world.drain_gpu_write_views(gpu16).length(), 0)
}

///|
test "QueryRow write marks gpu rows dirty without payload indexes" {
  let world = World::new()
  let qa = world.register_cpu_component("QueryRowDirtyA", 4)
  let gpu16 = world.register_gpu_component(
    "QueryRowDirtyGpu16",
    @comp.GpuLayout::empty(16),
  )
  let query = Query::new([qa, gpu16])
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  let empty : FixedArray[Byte] = FixedArray::make(0, (0 : Byte))
  assert_true(world.add_component_bytes(e, gpu16, empty))
  let _ = world.drain_resize_events()
  let _ = world.drain_gpu_writes(gpu16)
  query.for_each(world, row => row.write(gpu16, bytes => bytes[0] = (88 : Byte)))
  let writes = world.drain_gpu_writes(gpu16)
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, e.index * 16)
  assert_eq(writes[0].bytes[0], (88 : Byte))
}

///|
test "Query write marks gpu row dirty even if bytes are unchanged" {
  let world = World::new()
  let qa = world.register_cpu_component("QueryRowAutoDirtyA", 4)
  let gpu16 = world.register_gpu_component(
    "QueryRowAutoDirtyGpu16",
    @comp.GpuLayout::empty(16),
  )
  let query = Query::new([qa, gpu16])
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  let empty : FixedArray[Byte] = FixedArray::make(0, (0 : Byte))
  assert_true(world.add_component_bytes(e, gpu16, empty))
  let _ = world.drain_resize_events()
  let _ = world.drain_gpu_writes(gpu16)
  query.for_each(world, row => row.write(gpu16, bytes => ignore(bytes)))
  let writes = world.drain_gpu_writes(gpu16)
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, e.index * 16)
  assert_eq(writes[0].bytes[0], (0 : Byte))
}

///|
test "CommandBuffer applies queued structural changes after query" {
  let world = World::new()
  let qa = world.register_cpu_component("CommandBufferA", 4)
  let qb = world.register_cpu_component("CommandBufferB", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  let query = Query::new([qa])
  let mut queued_count = 0
  let mut saw_qa_before_apply = false
  let mut saw_qb_before_apply = true
  let schedule = Schedule::new()
  schedule.add_system(
    System::new_with_structural_write(
      "queue-structural-after-query",
      Update,
      [],
      [qa, qb],
      (w, _ctx, commands) => {
        query.for_each(w, row => {
          commands.add_component_bytes(row.entity(), qb, bytes4(5, 6, 7, 8))
          commands.remove_component(row.entity(), qa)
        })
        saw_qa_before_apply = w.has_component(e, qa)
        saw_qb_before_apply = w.has_component(e, qb)
        queued_count = commands.len()
      },
    ),
  )
  assert_true(schedule.run(world, SystemContext::new((0.016 : Float), 1)))
  assert_true(saw_qa_before_apply)
  assert_true(!saw_qb_before_apply)
  assert_eq(queued_count, 2)
  assert_true(!world.has_component(e, qa))
  assert_true(world.has_component(e, qb))
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

///|
test "CommandBuffer applies queued gpu writes and reports failed commands" {
  let world = World::new()
  let gpu16 = world.register_gpu_component(
    "CommandBufferGpu16",
    @comp.GpuLayout::empty(16),
  )
  let e = world.create_entity()
  let empty : FixedArray[Byte] = FixedArray::make(0, (0 : Byte))
  assert_true(world.add_component_bytes(e, gpu16, empty))
  let missing = EntityId::new(e.index + 100, 0)
  let mut queued_count = 0
  let schedule = Schedule::new()
  schedule.add_system(
    System::new_with_structural_write(
      "queue-gpu-write-and-failed-destroy",
      Update,
      [],
      [gpu16],
      (_w, _ctx, commands) => {
        commands.set_component_bytes(e, gpu16, gpu_bytes_with_u32(33U))
        commands.destroy_entity(missing)
        queued_count = commands.len()
      },
    ),
  )
  assert_true(!schedule.run(world, SystemContext::new((0.016 : Float), 1)))
  assert_eq(queued_count, 2)
  let writes = world.drain_gpu_writes(gpu16)
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, e.index * 16)
  assert_eq(writes[0].bytes[0], (33U & 0xFFU).to_byte())
}

///|
test "Schedule permits set_component_bytes without structural write" {
  let world = World::new()
  let qa = world.register_cpu_component("ScheduleSetComponentA", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  let schedule = Schedule::new()
  schedule.add_system(
    System::new("set-a", Update, [], [qa], (_world, _ctx, commands) => {
      commands.set_component_bytes(e, qa, bytes4(8, 7, 6, 5))
    }),
  )
  assert_true(schedule.run(world, SystemContext::new((0.016 : Float), 1)))
  match world.component_bytes(e, qa) {
    Some(bytes) => assert_eq(bytes, bytes4(8, 7, 6, 5))
    None => abort("expected ScheduleSetComponentA bytes")
  }
}

///|
test "Schedule permits set_global_transform update with GlobalTransform write" {
  let world = World::new()
  let gt = world.global_transform_component()
  let e = world.create_entity()
  assert_true(world.set_global_transform(e, @m44.Matrix44F::identity()))
  let _ = world.drain_gpu_writes(gt)
  let schedule = Schedule::new()
  schedule.add_system(
    System::new("set-gt", Update, [], [gt], (w, _ctx, _commands) => {
      let m = @m44.Matrix44::new_col_major(
        (1.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (1.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (1.0 : Float),
        (0.0 : Float),
        (4.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (1.0 : Float),
      )
      if !w.set_global_transform(e, m) {
        abort("expected scheduled set_global_transform")
      }
    }),
  )
  assert_true(schedule.run(world, SystemContext::new((0.016 : Float), 1)))
  match world.get_global_transform(e) {
    Some(m) => assert_eq(m.at(0, 3), (4.0 : Float))
    None => abort("expected scheduled GlobalTransform")
  }
}

///|
test "Schedule convenience setters return false for missing components without structural write" {
  let world = World::new()
  let tf_id = world.transform_component()
  let gt_id = world.global_transform_component()
  let co_id = world.child_of_component()
  let target = world.create_entity()
  let parent = world.create_entity()
  let buf = transform3d_bytes_identity()
  let n = buf.length()
  let tf = @comp.Transform3D::from_component_mut_view(
    buf.mut_view(start=0, end=n),
  )
  let mut transform_ok = true
  let mut trs_ok = true
  let mut child_ok = true
  let mut global_ok = true
  let schedule = Schedule::new()
  schedule.add_system(
    System::new(
      "missing-convenience-setters",
      Update,
      [],
      [tf_id, gt_id, co_id],
      (w, _ctx, _commands) => {
        transform_ok = w.set_transform(target, tf)
        trs_ok = w.set_transform_trs(
          target,
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          0.0,
          0.0,
          0.0,
          1.0,
          (1.0 : Float),
          (1.0 : Float),
          (1.0 : Float),
        )
        child_ok = w.set_child_of(target, parent)
        global_ok = w.set_global_transform(target, @m44.Matrix44F::identity())
      },
    ),
  )
  assert_true(schedule.run(world, SystemContext::new((0.016 : Float), 1)))
  assert_true(!transform_ok)
  assert_true(!trs_ok)
  assert_true(!child_ok)
  assert_true(!global_ok)
  assert_true(!world.has_component(target, tf_id))
  assert_true(!world.has_component(target, co_id))
  assert_true(!world.has_component(target, gt_id))
}

///|
test "Schedule runs systems by phase and applies commands after conflict-free batches" {
  let world = World::new()
  let qa = world.register_cpu_component("ScheduleA", 4)
  let qb = world.register_cpu_component("ScheduleB", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  let order : Array[Int] = []
  let schedule = Schedule::new()
  schedule.add_system(
    System::new("post", PostUpdate, [], [], (_world, _ctx, _commands) => {
      order.push(3)
    }),
  )
  schedule.add_system(
    System::new_with_structural_write("add-b", Update, [qa], [qb], (
      system_world,
      ctx,
      commands,
    ) => {
      order.push(ctx.frame_index)
      let query = Query::new([qa])
      query.for_each(system_world, row => {
        commands.add_component_bytes(row.entity(), qb, bytes4(5, 6, 7, 8))
      })
    }),
  )
  schedule.add_system(
    System::new("see-b", Update, [qb], [], (system_world, _ctx, _commands) => {
      if system_world.has_component(e, qb) {
        order.push(2)
      } else {
        order.push(20)
      }
    }),
  )
  let ctx = SystemContext::new((0.016 : Float), 1)
  assert_eq(schedule.len(), 3)
  assert_true(schedule.run(world, ctx))
  assert_eq(order.length(), 3)
  assert_eq(order[0], 1)
  assert_eq(order[1], 2)
  assert_eq(order[2], 3)
  assert_true(world.has_component(e, qb))
}

///|
test "Schedule run temporarily locks component registration" {
  let world = World::new()
  assert_true(!world.component_registration_locked())
  let mut locked_during_run = false
  let schedule = Schedule::new()
  schedule.add_system(
    System::new("observe-lock", Update, [], [], (w, _ctx, _cmds) => {
      locked_during_run = w.component_registration_locked()
    }),
  )
  assert_true(schedule.run(world, SystemContext::new((0.016 : Float), 1)))
  assert_true(locked_during_run)
  assert_true(!world.component_registration_locked())
  let late = world.register_cpu_component("RegisteredAfterScheduleRun", 4)
  assert_true(late.index >= 0)
}

///|
test "drain_resize_events is allowed outside schedule and structural systems" {
  let world = World::new()
  let e0 = world.create_entity()
  let _ = world.drain_resize_events()
  let gpu = world.register_gpu_component(
    "ResizeDrainAccessGpu",
    @comp.global_transform_gpu_layout(),
  )
  assert_true(world.add_component(e0, gpu))
  let outside_events = world.drain_resize_events()
  assert_true(outside_events.length() > 0)
  let e1 = world.create_entity()
  assert_true(world.add_component(e1, gpu))
  let mut drained_in_system = 0
  let schedule = Schedule::new()
  schedule.add_system(
    System::new_with_structural_write(
      "drain-resize-events",
      RenderExtract,
      [],
      [],
      (w, _ctx, _cmds) => drained_in_system = w.drain_resize_events().length(),
    ),
  )
  assert_true(schedule.run(world, SystemContext::new((0.016 : Float), 1)))
  assert_true(drained_in_system > 0)
  assert_eq(world.drain_resize_events().length(), 0)
}

///|
test "transform_propagation_system updates GlobalTransform in a schedule" {
  let world = World::new()
  let e = world.create_entity()
  let buf = transform3d_bytes_translation(
    (3.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let n = buf.length()
  let tf = @comp.Transform3D::from_component_mut_view(
    buf.mut_view(start=0, end=n),
  )
  assert_true(world.set_transform(e, tf))
  assert_true(world.set_global_transform(e, @m44.Matrix44F::identity()))
  let _ = world.drain_gpu_writes(world.global_transform_component())
  let schedule = Schedule::new()
  schedule.add_system(transform_propagation_system(world))
  assert_true(schedule.run(world, SystemContext::new((0.016 : Float), 1)))
  match world.get_global_transform(e) {
    Some(m) => assert_eq(m.at(0, 3), (3.0 : Float))
    None => abort("expected Matrix44F")
  }
}

///|
test "System access arrays are copied" {
  let world = World::new()
  let qa = world.register_cpu_component("SystemAccessA", 4)
  let qb = world.register_cpu_component("SystemAccessB", 4)
  let reads : Array[ComponentTypeId] = [qa]
  let writes : Array[ComponentTypeId] = [qb]
  let system = System::new("copy-access", Update, reads, writes, (_w, _c, _b) => {
    ()
  })
  reads[0] = qb
  writes[0] = qa
  assert_eq(system.name(), "copy-access")
  assert_true(system.phase() == Update)
  assert_true(system.reads()[0] == qa)
  assert_true(system.writes()[0] == qb)
  assert_true(!system.structural_write())
}

///|
test "System conflict helpers detect same-phase access overlaps" {
  let world = World::new()
  let qa = world.register_cpu_component("SystemConflictA", 4)
  let qb = world.register_cpu_component("SystemConflictB", 4)
  let read_a = System::new("read-a", Update, [qa], [], (_w, _c, _b) => ())
  let write_a = System::new("write-a", Update, [], [qa], (_w, _c, _b) => ())
  let write_b = System::new("write-b", Update, [], [qb], (_w, _c, _b) => ())
  let later_write_a = System::new("later-write-a", PostUpdate, [], [qa], (
    _w,
    _c,
    _b,
  ) => ())
  assert_true(read_a.conflicts_with(write_a))
  assert_true(!read_a.conflicts_with(write_b))
  let same_phase = Schedule::new()
  same_phase.add_system(read_a)
  same_phase.add_system(write_a)
  assert_true(same_phase.has_parallel_access_conflicts())
  let different_phase = Schedule::new()
  different_phase.add_system(read_a)
  different_phase.add_system(later_write_a)
  assert_true(!different_phase.has_parallel_access_conflicts())
}

///|
test "System writes declaration also permits reads during schedule run" {
  let world = World::new()
  let qa = world.register_cpu_component("SystemWriteCanReadA", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  let mut saw_first = (0 : Byte)
  let schedule = Schedule::new()
  schedule.add_system(
    System::new("write-can-read", Update, [], [qa], (w, _ctx, _cmds) => {
      match w.component_bytes(e, qa) {
        Some(bytes) => saw_first = bytes[0]
        None => abort("expected SystemWriteCanReadA bytes")
      }
    }),
  )
  assert_true(schedule.run(world, SystemContext::new((0.016 : Float), 1)))
  assert_eq(saw_first, (1 : Byte))
}

///|
test "Nested Schedule::run restores outer system access declarations" {
  let world = World::new()
  let qa = world.register_cpu_component("NestedScheduleOuterA", 4)
  let qb = world.register_cpu_component("NestedScheduleInnerB", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  assert_true(world.add_component_bytes(e, qb, bytes4(5, 6, 7, 8)))
  let inner = Schedule::new()
  inner.add_system(
    System::new("inner-write-b", Update, [], [qb], (w, _ctx, _cmds) => {
      if !w.set_component_bytes(e, qb, bytes4(2, 2, 2, 2)) {
        abort("expected nested inner component write")
      }
    }),
  )
  let outer = Schedule::new()
  outer.add_system(
    System::new("outer-write-a", Update, [], [qa], (w, ctx, _cmds) => {
      if !inner.run(w, ctx) {
        abort("expected nested inner schedule to succeed")
      }
      if !w.set_component_bytes(e, qa, bytes4(3, 3, 3, 3)) {
        abort("expected nested outer component write")
      }
    }),
  )
  assert_true(outer.run(world, SystemContext::new((0.016 : Float), 1)))
  match world.component_bytes(e, qa) {
    Some(bytes) => assert_eq(bytes, bytes4(3, 3, 3, 3))
    None => abort("expected NestedScheduleOuterA bytes")
  }
}

///|
test "System Query preserves read and write access separation during schedule run" {
  let world = World::new()
  let qa = world.register_cpu_component("SystemQueryReadA", 4)
  let qb = world.register_cpu_component("SystemQueryWriteB", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  assert_true(world.add_component_bytes(e, qb, bytes4(5, 6, 7, 8)))
  let query = Query::new([qa, qb])
  let schedule = Schedule::new()
  schedule.add_system(
    System::new("query-read-write", Update, [qa], [qb], (w, _ctx, _cmds) => {
      query.for_each(w, row => {
        row.read(qa, src => row.write(qb, dst => dst[0] = src[0]))
      })
    }),
  )
  assert_true(schedule.run(world, SystemContext::new((0.016 : Float), 1)))
  match world.component_bytes(e, qb) {
    Some(bytes) => assert_eq(bytes[0], (1 : Byte))
    None => abort("expected SystemQueryWriteB bytes")
  }
}

///|
test "System structural write declaration permits entity creation" {
  let world = World::new()
  let mut spawned = EntityId::new(-1, 0)
  let schedule = Schedule::new()
  schedule.add_system(
    System::new_with_structural_write("spawn", Update, [], [], (w, _ctx, _cmds) => {
      spawned = w.create_entity()
    }),
  )
  schedule.add_system(
    System::new("observe", Update, [], [], (_w, _ctx, _cmds) => ()),
  )
  assert_true(schedule.run(world, SystemContext::new((0.016 : Float), 1)))
  assert_true(world.is_alive(spawned))
  assert_true(schedule.has_parallel_access_conflicts())
}

///|
test "CommandBuffer create_entity reserves id and applies components after query" {
  let world = World::new()
  let qa = world.register_cpu_component("CommandCreateSource", 4)
  let qb = world.register_cpu_component("CommandCreateSpawned", 4)
  let source = world.create_entity()
  assert_true(world.add_component_bytes(source, qa, bytes4(1, 2, 3, 4)))
  let query = Query::new([qa])
  let mut spawned = EntityId::new(-1, 0)
  let mut alive_before_apply = true
  let mut queued_count = 0
  let schedule = Schedule::new()
  schedule.add_system(
    System::new_with_structural_write(
      "command-create-entity",
      Update,
      [qa],
      [qb],
      (w, _ctx, commands) => {
        query.for_each(w, _row => {
          spawned = commands.create_entity()
          alive_before_apply = w.is_alive(spawned)
          commands.add_component_bytes(spawned, qb, bytes4(9, 8, 7, 6))
        })
        queued_count = commands.len()
      },
    ),
  )
  assert_true(schedule.run(world, SystemContext::new((0.016 : Float), 1)))
  assert_eq(queued_count, 2)
  assert_true(!alive_before_apply)
  assert_true(world.is_alive(spawned))
  assert_true(world.has_component(spawned, qb))
  match world.component_bytes(spawned, qb) {
    Some(bytes) => assert_eq(bytes, bytes4(9, 8, 7, 6))
    None => abort("expected CommandCreateSpawned bytes")
  }
}

///|
test "update_global_transforms_from_transforms writes hierarchy to GlobalTransform" {
  let world = World::new()
  let parent = world.create_entity()
  let child = world.create_entity()
  let buf_p = transform3d_bytes_translation(
    (10.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let np = buf_p.length()
  let tf_p = @comp.Transform3D::from_component_mut_view(
    buf_p.mut_view(start=0, end=np),
  )
  let buf_c = transform3d_bytes_translation(
    (5.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let nc = buf_c.length()
  let tf_c = @comp.Transform3D::from_component_mut_view(
    buf_c.mut_view(start=0, end=nc),
  )
  assert_true(world.set_transform(parent, tf_p))
  assert_true(world.set_transform(child, tf_c))
  assert_true(world.set_child_of(child, parent))
  let g0 = @m44.Matrix44F::identity()
  assert_true(world.set_global_transform(parent, g0))
  assert_true(world.set_global_transform(child, g0))
  let _ = world.drain_gpu_writes(world.global_transform_component())
  world.update_global_transforms_from_transforms()
  match world.get_global_transform(child) {
    Some(m) => {
      assert_eq(m.at(0, 3), (15.0 : Float))
      assert_eq(m.at(1, 3), (0.0 : Float))
      assert_eq(m.at(2, 3), (0.0 : Float))
    }
    None => abort("expected Matrix44F")
  }
}

///|
test "update_global_transforms_from_transforms applies root Transform3D only" {
  let world = World::new()
  let e = world.create_entity()
  let buf = transform3d_bytes_translation(
    (7.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let n = buf.length()
  let tf = @comp.Transform3D::from_component_mut_view(
    buf.mut_view(start=0, end=n),
  )
  assert_true(world.set_transform(e, tf))
  assert_true(world.set_global_transform(e, @m44.Matrix44F::identity()))
  let _ = world.drain_gpu_writes(world.global_transform_component())
  world.update_global_transforms_from_transforms()
  match world.get_global_transform(e) {
    Some(m) => assert_eq(m.at(0, 3), (7.0 : Float))
    None => abort("expected Matrix44F")
  }
}

///|
test "update_global_transforms_from_transforms handles mixed child and root archetypes" {
  let world = World::new()
  let parent = world.create_entity()
  let child = world.create_entity()
  let root = world.create_entity()
  let buf_p = transform3d_bytes_translation(
    (10.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let np = buf_p.length()
  let tf_p = @comp.Transform3D::from_component_mut_view(
    buf_p.mut_view(start=0, end=np),
  )
  let buf_c = transform3d_bytes_translation(
    (5.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let nc = buf_c.length()
  let tf_c = @comp.Transform3D::from_component_mut_view(
    buf_c.mut_view(start=0, end=nc),
  )
  let buf_r = transform3d_bytes_translation(
    (7.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let nr = buf_r.length()
  let tf_r = @comp.Transform3D::from_component_mut_view(
    buf_r.mut_view(start=0, end=nr),
  )
  assert_true(world.set_transform(parent, tf_p))
  assert_true(world.set_transform(child, tf_c))
  assert_true(world.set_child_of(child, parent))
  assert_true(world.set_transform(root, tf_r))
  assert_true(world.set_global_transform(parent, @m44.Matrix44F::identity()))
  assert_true(world.set_global_transform(child, @m44.Matrix44F::identity()))
  assert_true(world.set_global_transform(root, @m44.Matrix44F::identity()))
  let _ = world.drain_gpu_writes(world.global_transform_component())
  world.update_global_transforms_from_transforms()
  match world.get_global_transform(child) {
    Some(m) => assert_eq(m.at(0, 3), (15.0 : Float))
    None => abort("expected child Matrix44F")
  }
  match world.get_global_transform(root) {
    Some(m) => assert_eq(m.at(0, 3), (7.0 : Float))
    None => abort("expected root Matrix44F")
  }
}

///|
test "write_global_transforms_dense writes one contiguous upload range" {
  let world = World::new()
  let writes = world.write_global_transforms_dense(2, fn(i, row) {
    row[0] = ((10 + i) & 0xFF).to_byte()
    row[47] = ((20 + i) & 0xFF).to_byte()
  })
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, 0)
  assert_eq(writes[0].bytes.length(), 2 * 48)
  assert_eq(writes[0].bytes[0], (10 : Byte))
  assert_eq(writes[0].bytes[47], (20 : Byte))
  assert_eq(writes[0].bytes[48], (11 : Byte))
  assert_eq(writes[0].bytes[95], (21 : Byte))
  assert_eq(
    world.drain_gpu_writes(world.global_transform_component()).length(),
    0,
  )
}

///|
test "spawn_transform_global_batch creates builtin transform rows directly" {
  let world = World::new()
  let entities = world.spawn_transform_global_batch(2, fn(
    i,
    _e,
    tf_row,
    gt_row,
  ) {
    @comp.Transform3D::write_trs_to_component_mut_view(
      tf_row,
      Float::from_double((i + 1).to_double()),
      Float::from_double((i + 2).to_double()),
      Float::from_double((i + 3).to_double()),
      0.0,
      0.0,
      0.0,
      1.0,
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    )
    @comp.global_transform_write_identity_row(gt_row)
  })
  assert_eq(entities.length(), 2)
  let tf = world.transform_component()
  let gt = world.global_transform_component()
  assert_true(world.has_component(entities[0], tf))
  assert_true(world.has_component(entities[0], gt))
  match world.get_transform(entities[1]) {
    Some(t) => {
      assert_eq(t.position.x(), (2.0 : Float))
      assert_eq(t.position.y(), (3.0 : Float))
      assert_eq(t.position.z(), (4.0 : Float))
    }
    None => abort("expected Transform3D")
  }
  let writes = world.drain_gpu_write_views(gt)
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, 0)
  assert_eq(writes[0].bytes.length(), 2 * 48)
  assert_eq(
    @comp.get_gpu_f32_byte_view(writes[0].bytes[0:48], 0),
    (1.0 : Float),
  )
  assert_eq(
    @comp.get_gpu_f32_byte_view(writes[0].bytes[48:96], 40),
    (1.0 : Float),
  )
}

///|
test "spawn_batch creates arbitrary CPU and GPU components directly" {
  let world = World::new()
  let cpu = world.register_cpu_component("SpawnBatchCpu", 4)
  let gpu = world.register_gpu_component(
    "SpawnBatchGpu",
    @comp.GpuLayout::empty(16),
  )
  let entities = world.spawn_batch([gpu, cpu], 3, fn(i, _e, row) {
    row.write(cpu, c => c[0] = (10 + i).to_byte())
    row.write(gpu, g => g[0] = (20 + i).to_byte())
  })
  assert_eq(entities.length(), 3)
  for i = 0; i < entities.length(); i = i + 1 {
    assert_true(world.has_component(entities[i], cpu))
    assert_true(world.has_component(entities[i], gpu))
    match world.component_bytes(entities[i], cpu) {
      Some(bytes) => assert_eq(bytes[0], (10 + i).to_byte())
      None => abort("expected cpu bytes")
    }
  }
  let active = world.gpu_component_active_indices(gpu)
  assert_eq(active.length(), 3)
  let writes = world.drain_gpu_write_views(gpu)
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, 0)
  assert_eq(writes[0].bytes.length(), 3 * 16)
  assert_eq(writes[0].bytes[0], (20 : Byte))
  assert_eq(writes[0].bytes[16], (21 : Byte))
  assert_eq(writes[0].bytes[32], (22 : Byte))
}

///|
test "write_global_transforms_dense_range_views writes dense rows through one range callback" {
  let world = World::new()
  let writes = world.write_global_transforms_dense_range_views(2, range => {
    if range.first_entity_index() != 0 {
      abort("expected first range entity index to be 0")
    }
    if range.count() != 2 {
      abort("expected range count to be 2")
    }
    if range.stride() != 48 {
      abort("expected GlobalTransform row stride to be 48")
    }
    let bytes = range.bytes()
    @comp.put_gpu_f32_mut_view(bytes, 0, (0.5 : Double))
    @comp.put_gpu_f32_mut_view(bytes, 12, (-1.0 : Double))
    @comp.put_gpu_f32_mut_view(bytes, 44, (-1.0 : Double))
    @comp.put_gpu_f32_mut_view(bytes, 48, (0.5 : Double))
    @comp.put_gpu_f32_mut_view(bytes, 48 + 12, (1.0 : Double))
    @comp.put_gpu_f32_mut_view(bytes, 48 + 44, (-1.0 : Double))
  })
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, 0)
  assert_eq(writes[0].bytes.length(), 2 * 48)
  let row0 = writes[0].bytes[0:48]
  let row1 = writes[0].bytes[48:96]
  assert_eq(@comp.get_gpu_f32_byte_view(row0, 0), (0.5 : Float))
  assert_eq(@comp.get_gpu_f32_byte_view(row0, 12), (-1.0 : Float))
  assert_eq(@comp.get_gpu_f32_byte_view(row0, 44), (-1.0 : Float))
  assert_eq(@comp.get_gpu_f32_byte_view(row1, 0), (0.5 : Float))
  assert_eq(@comp.get_gpu_f32_byte_view(row1, 12), (1.0 : Float))
  assert_eq(@comp.get_gpu_f32_byte_view(row1, 44), (-1.0 : Float))
}
