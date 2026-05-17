///|
/// Implements `sorted_component_signature`.
fn sorted_component_signature(
  components : Array[ComponentTypeId],
) -> Array[ComponentTypeId] {
  let mut out : Array[ComponentTypeId] = []
  for i = 0; i < components.length(); i = i + 1 {
    out = sorted_with_added(out, components[i])
  }
  out
}

///|
/// Implements `World::allocate_entity_slot_for_batch`.
fn World::allocate_entity_slot_for_batch(self : World) -> EntityId {
  if self.free_indices.length() > 0 {
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
}

///|
/// Reserves CPU SoA row capacity for appending entities with the given component signature.
///
/// This does not create entities. It only ensures the matching archetype and its component
/// columns are large enough for `additional_rows` more rows, so a following spawn path can
/// avoid capacity growth and existing payload copies.
pub fn World::reserve_batch_capacity(
  self : World,
  components : Array[ComponentTypeId],
  additional_rows : Int,
) -> Bool {
  self.assert_not_querying("World::reserve_batch_capacity")
  self.assert_system_structural_write("World::reserve_batch_capacity")
  if additional_rows < 0 {
    abort("World::reserve_batch_capacity: additional_rows must be non-negative")
  }
  if component_array_has_duplicates(components) {
    abort("World::reserve_batch_capacity: duplicate component")
  }
  let signature = sorted_component_signature(components)
  for i = 0; i < signature.length(); i = i + 1 {
    let component = signature[i]
    self.assert_system_component_write(
      component, "World::reserve_batch_capacity",
    )
    match self.registry.get(component) {
      Some(_) => ()
      None => return false
    }
  }
  if additional_rows == 0 {
    return true
  }
  let arch_index = self.ensure_archetype(signature)
  let arch = self.archetypes[arch_index]
  arch.ensure_row_capacity(arch.entities.length() + additional_rows)
  true
}

///|
/// Creates `count` entities directly in the archetype described by `components`.
///
/// This avoids spawning into the empty archetype and then migrating once per added component.
/// The callback must initialize any component rows it cares about through [`SpawnBatchRow::write_view`].
pub fn World::spawn_batch(
  self : World,
  components : Array[ComponentTypeId],
  count : Int,
  write : (Int, EntityId, SpawnBatchRow) -> Unit,
) -> Array[EntityId] {
  self.assert_not_querying("World::spawn_batch")
  self.assert_system_structural_write("World::spawn_batch")
  if count < 0 {
    abort("World::spawn_batch: count must be non-negative")
  }
  if component_array_has_duplicates(components) {
    abort("World::spawn_batch: duplicate component")
  }
  let signature = sorted_component_signature(components)
  let spawn_global_transform = component_array_contains(
    signature,
    self.global_transform_component_id,
  )
  for i = 0; i < signature.length(); i = i + 1 {
    let component = signature[i]
    self.assert_system_component_write(component, "World::spawn_batch")
    match self.registry.get(component) {
      Some(_) => ()
      None => return []
    }
  }
  let entities : Array[EntityId] = []
  if count == 0 {
    return entities
  }
  let arch_index = self.ensure_archetype(signature)
  let arch = self.archetypes[arch_index]
  for i = 0; i < count; i = i + 1 {
    ignore(i)
    let entity = self.allocate_entity_slot_for_batch()
    entities.push(entity)
  }
  arch.ensure_row_capacity(arch.entities.length() + entities.length())
  self.query_depth = self.query_depth + 1
  for i = 0; i < entities.length(); i = i + 1 {
    let entity = entities[i]
    let row = arch.push_empty_row(entity)
    self.locations[entity.index] = Some({ archetype_index: arch_index, row })
    if spawn_global_transform {
      let gt_ref = self.alloc_global_transform_ref(
        self.global_transform_default_format,
        @m44.Matrix44F::identity(),
      )
      arch.set_component_bytes(
        row,
        self.global_transform_component_id,
        @comp.global_transform_ref_bytes(gt_ref.format, gt_ref.word_offset),
      )
    }
    write(i, entity, { world: self, entity, archetype_index: arch_index, row })
  }
  self.query_depth = self.query_depth - 1
  entities
}

///|
/// Implements `SpawnBatchRow::entity`.
pub fn SpawnBatchRow::entity(self : SpawnBatchRow) -> EntityId {
  self.entity
}

///|
/// Implements `SpawnBatchRow::write`.
pub fn SpawnBatchRow::write(
  self : SpawnBatchRow,
  component : ComponentTypeId,
  f : (MutArrayView[Byte]) -> Unit,
) -> Unit {
  f(self.write_view(component))
}

///|
/// Implements `SpawnBatchRow::write_view`.
pub fn SpawnBatchRow::write_view(
  self : SpawnBatchRow,
  component : ComponentTypeId,
) -> MutArrayView[Byte] {
  self.world.assert_system_component_write(
    component, "SpawnBatchRow::write_view",
  )
  let arch = self.world.archetypes[self.archetype_index]
  if !component_array_contains(arch.components, component) {
    abort("SpawnBatchRow::write_view: component is not part of this batch")
  }
  match self.world.registry.get(component) {
    Some(_) => {
      let col_index = arch.column_index(component)
      if col_index < 0 {
        abort("SpawnBatchRow::write_view: missing CPU column")
      }
      let col = arch.columns[col_index]
      let base = self.row * col.stride
      col.bytes.mut_view(start=base, end=base + col.stride)
    }
    None => abort("SpawnBatchRow::write_view: unknown component")
  }
}
