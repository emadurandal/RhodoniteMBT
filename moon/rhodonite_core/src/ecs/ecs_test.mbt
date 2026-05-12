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
test "for_each_entity_with_components matches supersets and skips empty required" {
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
  world.for_each_entity_with_components([qa, qb], (ent, _sig, payloads) => {
    hits.push(ent)
    ignore(payloads)
  })
  assert_eq(hits.length(), 1)
  assert_true(hits[0] == e_both)
  let empty_hits : Array[EntityId] = []
  world.for_each_entity_with_components([], (ent, _sig, _pay) => {
    empty_hits.push(ent)
  })
  assert_eq(empty_hits.length(), 0)
  // Query scope has ended, so normal structural mutation should work again.
  let e_after_query = world.create_entity()
  assert_true(
    world.add_component_bytes(e_after_query, qa, bytes4(13, 14, 15, 16)),
  )
}

///|
test "for_each_entity_with_components gives full GpuComponentStore row for GpuVisible" {
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
  world.for_each_entity_with_components([qa, gpu16], (_ent, _sig, payloads) => {
    got0 = payloads[0].length()
    got1 = payloads[1].length()
  })
  assert_eq(got0, 4)
  assert_eq(got1, 16)
}

///|
test "for_each_entity_with_components_marking_gpu_dirty queues written gpu rows" {
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
  world.for_each_entity_with_components_marking_gpu_dirty(
    [qa, gpu16],
    [gpu16],
    (_ent, _sig, payloads) => payloads[1][0] = (99 : Byte),
  )
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
    first_len = row.view(qa).length()
    second_first_byte = row.view(qb)[0]
  })
  assert_eq(hits.length(), 1)
  assert_true(hits[0] == e)
  assert_eq(first_len, 4)
  assert_eq(second_first_byte, (5 : Byte))
}

///|
test "Query for_each_marking_gpu_dirty queues written gpu rows" {
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
  query.for_each_marking_gpu_dirty(world, [gpu16], row => {
    row.view(gpu16)[0] = (77 : Byte)
  })
  let writes = world.drain_gpu_writes(gpu16)
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, e.index * 16)
  assert_eq(writes[0].bytes[0], (77 : Byte))
}

///|
test "QueryRow view accesses payloads by component id" {
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
    a_first = row.view(qa)[0]
    b_first = row.view(qb)[0]
    row.view(qb)[0] = (42 : Byte)
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
test "QueryRow view and mark_dirty update gpu rows without payload indexes" {
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
  query.for_each(world, row => {
    row.view(gpu16)[0] = (88 : Byte)
    if !row.mark_dirty(gpu16) {
      abort("expected QueryRow dirty mark")
    }
  })
  let writes = world.drain_gpu_writes(gpu16)
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, e.index * 16)
  assert_eq(writes[0].bytes[0], (88 : Byte))
}

///|
test "Query for_each_marking_gpu_dirty queues written gpu rows with rows" {
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
  query.for_each_marking_gpu_dirty(world, [gpu16], row => {
    row.view(gpu16)[0] = (66 : Byte)
  })
  let writes = world.drain_gpu_writes(gpu16)
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, e.index * 16)
  assert_eq(writes[0].bytes[0], (66 : Byte))
}

///|
test "CommandBuffer applies queued structural changes after query" {
  let world = World::new()
  let qa = world.register_cpu_component("CommandBufferA", 4)
  let qb = world.register_cpu_component("CommandBufferB", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  let query = Query::new([qa])
  let commands = CommandBuffer::new()
  query.for_each(world, row => {
    commands.add_component_bytes(row.entity(), qb, bytes4(5, 6, 7, 8))
    commands.remove_component(row.entity(), qa)
  })
  assert_true(world.has_component(e, qa))
  assert_true(!world.has_component(e, qb))
  assert_eq(commands.len(), 2)
  assert_true(commands.apply(world))
  assert_true(!world.has_component(e, qa))
  assert_true(world.has_component(e, qb))
  assert_true(commands.is_empty())
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
  let missing = EntityId::new(e.index + 100, 0)
  let commands = CommandBuffer::new()
  commands.set_gpu_component_bytes(e, gpu16, gpu_bytes_with_u32(33U))
  commands.destroy_entity(missing)
  assert_true(!commands.apply(world))
  let writes = world.drain_gpu_writes(gpu16)
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, e.index * 16)
  assert_eq(writes[0].bytes[0], (33U & 0xFFU).to_byte())
  assert_true(commands.is_empty())
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
test "Schedule runs systems by phase and applies commands after each system" {
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
