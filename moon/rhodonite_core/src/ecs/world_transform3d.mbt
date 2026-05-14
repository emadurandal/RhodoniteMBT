///|
/// Assigns builtin [`Transform3D`] for `entity` in archetype SoA (`cpu_stride` = layout stride).
pub fn World::set_transform(
  self : World,
  entity : EntityId,
  t : @comp.Transform3D,
) -> Bool {
  let id = self.transform_component_id
  self.assert_system_component_write(id, "World::set_transform")
  let bytes = t.to_component_bytes()
  if self.has_component(entity, id) {
    self.set_component_bytes(entity, id, bytes)
  } else if !self.can_add_missing_component_from_setter(
      id, "World::set_transform",
    ) {
    false
  } else {
    self.add_component_bytes(entity, id, bytes)
  }
}

///|
/// Assigns builtin [`Transform3D`] for `entity` in archetype SoA (`cpu_stride` = layout stride).
pub fn World::set_transform_trs(
  self : World,
  entity : EntityId,
  px : Float,
  py : Float,
  pz : Float,
  qx : Double,
  qy : Double,
  qz : Double,
  qw : Double,
  sx : Float,
  sy : Float,
  sz : Float,
) -> Bool {
  let id = self.transform_component_id
  self.assert_system_component_write(id, "World::set_transform_trs")
  let bytes = @comp.transform3d_trs_bytes(
    px, py, pz, qx, qy, qz, qw, sx, sy, sz,
  )
  if self.has_component(entity, id) {
    self.set_component_bytes(entity, id, bytes)
  } else if !self.can_add_missing_component_from_setter(
      id, "World::set_transform_trs",
    ) {
    false
  } else {
    self.add_component_bytes(entity, id, bytes)
  }
}

///|
/// Creates `count` entities directly in the builtin Transform3D + GlobalTransform archetype.
///
/// The callback must fully initialize both rows. This avoids per-entity empty-archetype insertion,
/// component migration, and intermediate FixedArray allocation in mass-spawn paths.
pub fn World::spawn_transform_global_batch(
  self : World,
  count : Int,
  write : (Int, EntityId, MutArrayView[Byte], MutArrayView[Byte]) -> Unit,
) -> Array[EntityId] {
  self.assert_not_querying("World::spawn_transform_global_batch")
  self.assert_system_structural_write("World::spawn_transform_global_batch")
  let tf = self.transform_component_id
  let gt = self.global_transform_component_id
  self.assert_system_component_write(tf, "World::spawn_transform_global_batch")
  self.assert_system_component_write(gt, "World::spawn_transform_global_batch")
  if count < 0 {
    abort("World::spawn_transform_global_batch: count must be non-negative")
  }
  let entities : Array[EntityId] = []
  if count == 0 {
    return entities
  }
  let components : Array[ComponentTypeId] = [tf, gt]
  let arch_index = self.ensure_archetype(components)
  let arch = self.archetypes[arch_index]
  let tf_col_index = arch.column_index(tf)
  if tf_col_index < 0 {
    abort("World::spawn_transform_global_batch: missing Transform3D column")
  }
  let tf_col = arch.columns[tf_col_index]
  if tf_col.stride != 48 {
    abort("World::spawn_transform_global_batch: Transform3D stride mismatch")
  }
  let mut max_index = -1
  let mut min_index = 2147483647
  for i = 0; i < count; i = i + 1 {
    let entity = if self.free_indices.length() > 0 {
      let last = self.free_indices.length() - 1
      let index = self.free_indices[last]
      let _ = self.free_indices.pop()
      self.alive[index] = true
      self.reserved[index] = false
      EntityId::new(index, self.generations[index])
    } else {
      let index = self.generations.length()
      self.generations.push(0)
      self.alive.push(true)
      self.reserved.push(false)
      self.locations.push(None)
      EntityId::new(index, 0)
    }
    if entity.index > max_index {
      max_index = entity.index
    }
    if entity.index < min_index {
      min_index = entity.index
    }
    entities.push(entity)
  }
  let gt_store = match self.ensure_gpu_store_capacity(gt, max_index + 1) {
    Some(store) => store
    None => return []
  }
  if gt_store.stride != 48 {
    abort(
      "World::spawn_transform_global_batch: GlobalTransform stride mismatch",
    )
  }
  let start_row = arch.entities.length()
  arch.ensure_row_capacity(start_row + entities.length())
  for i = 0; i < entities.length(); i = i + 1 {
    let entity = entities[i]
    let row = start_row + i
    arch.entities.push(entity)
    self.locations[entity.index] = Some({ archetype_index: arch_index, row })
    if !gt_store.active_flags[entity.index] {
      gt_store.active_flags[entity.index] = true
      gt_store.active_positions[entity.index] = gt_store.active_indices.length()
      gt_store.active_indices.push(entity.index)
    }
    let tf_base = row * tf_col.stride
    let gt_base = entity.index * gt_store.stride
    write(
      i,
      entity,
      tf_col.bytes.mut_view(start=tf_base, end=tf_base + tf_col.stride),
      gt_store.bytes.mut_view(start=gt_base, end=gt_base + gt_store.stride),
    )
  }
  if max_index - min_index + 1 == count {
    gt_store.mark_dirty_range(min_index, max_index)
  } else {
    for i = 0; i < entities.length(); i = i + 1 {
      gt_store.mark_dirty(entities[i].index)
    }
  }
  self.replace_gpu_store(gt_store)
  entities
}

///|
pub fn World::get_transform(
  self : World,
  entity : EntityId,
) -> @comp.Transform3D? {
  let tf = self.transform_component_id
  self.assert_system_component_read(tf, "World::get_transform")
  if !self.is_alive(entity) || !self.has_component(entity, tf) {
    return None
  }
  match self.component_bytes(entity, tf) {
    Some(bytes) => {
      let n = bytes.length()
      Some(
        @comp.Transform3D::from_component_mut_view(
          bytes.mut_view(start=0, end=n),
        ),
      )
    }
    None => None
  }
}

///|
/// JS hot path for bulk-updating builtin `Transform3D.position` without constructing `QueryRow`.
/// It uses the archetype column API so browser builds have the same official bulk path as native.
#cfg(target="js")
pub fn World::update_transform3d_positions(
  self : World,
  f : (EntityId) -> (Float, Float, Float),
) -> Unit {
  let tf = self.transform_component_id
  self.assert_system_component_write(tf, "World::update_transform3d_positions")
  RawQuery::new([tf]).for_each_archetype(self, arch => {
    let stride = arch.component_stride(tf)
    if stride != 48 {
      abort("World::update_transform3d_positions: Transform3D stride mismatch")
    }
    let col = arch.write_column(tf)
    for row = 0; row < arch.length(); row = row + 1 {
      let entity = arch.entity(row)
      let (x, y, z) = f(entity)
      let base = row * stride
      @comp.Transform3D::write_position_to_component_mut_view(
        col.mut_view(start=base, end=base + 48),
        x,
        y,
        z,
      )
    }
  })
}

///|
/// Native/Wasm hot path for bulk-updating builtin `Transform3D.position` without constructing `QueryRow`
/// or `Vector3Ref` wrappers per entity.
#cfg(not(target="js"))
pub fn World::update_transform3d_positions(
  self : World,
  f : (EntityId) -> (Float, Float, Float),
) -> Unit {
  let tf = self.transform_component_id
  self.assert_system_component_write(tf, "World::update_transform3d_positions")
  for ai = 0; ai < self.archetypes.length(); ai = ai + 1 {
    let arch = self.archetypes[ai]
    let tf_col_index = arch.column_index(tf)
    if tf_col_index < 0 {
      continue
    }
    let col = arch.columns[tf_col_index]
    if col.stride < 12 {
      abort("World::update_transform3d_positions: Transform3D stride mismatch")
    }
    for row = 0; row < arch.entities.length(); row = row + 1 {
      let entity = arch.entities[row]
      let (x, y, z) = f(entity)
      let base = row * col.stride
      put_f32_array_le(col.bytes, base, x)
      put_f32_array_le(col.bytes, base + 4, y)
      put_f32_array_le(col.bytes, base + 8, z)
    }
  }
}
