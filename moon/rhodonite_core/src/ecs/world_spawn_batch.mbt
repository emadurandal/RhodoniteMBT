///|
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
fn mark_gpu_component_batch_dirty(
  store : GpuComponentStore,
  entities : Array[EntityId],
  min_index : Int,
  max_index : Int,
) -> Unit {
  if entities.length() == 0 {
    return
  }
  if max_index - min_index + 1 == entities.length() {
    store.mark_dirty_range(min_index, max_index)
  } else {
    for i = 0; i < entities.length(); i = i + 1 {
      store.mark_dirty(entities[i].index)
    }
  }
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
  let gpu_components : Array[ComponentTypeId] = []
  for i = 0; i < signature.length(); i = i + 1 {
    let component = signature[i]
    self.assert_system_component_write(component, "World::spawn_batch")
    match self.registry.get(component) {
      Some(rc) =>
        match rc.kind {
          CpuOnly => ()
          GpuVisible => gpu_components.push(component)
        }
      None => return []
    }
  }
  let entities : Array[EntityId] = []
  if count == 0 {
    return entities
  }
  let arch_index = self.ensure_archetype(signature)
  let arch = self.archetypes[arch_index]
  let mut max_index = -1
  let mut min_index = 2147483647
  for i = 0; i < count; i = i + 1 {
    ignore(i)
    let entity = self.allocate_entity_slot_for_batch()
    if entity.index > max_index {
      max_index = entity.index
    }
    if entity.index < min_index {
      min_index = entity.index
    }
    entities.push(entity)
  }
  self.ensure_gpu_capacity(max_index + 1)
  arch.ensure_row_capacity(arch.entities.length() + entities.length())
  self.query_depth = self.query_depth + 1
  for i = 0; i < entities.length(); i = i + 1 {
    let entity = entities[i]
    let row = arch.push_empty_row(entity)
    self.locations[entity.index] = Some({ archetype_index: arch_index, row })
    for gi = 0; gi < gpu_components.length(); gi = gi + 1 {
      match
        self.ensure_gpu_store_capacity(gpu_components[gi], entity.index + 1) {
        Some(store) => {
          store.activate_slot(entity.index)
          self.replace_gpu_store(store)
        }
        None => ()
      }
    }
    write(i, entity, { world: self, entity, archetype_index: arch_index, row })
  }
  self.query_depth = self.query_depth - 1
  for gi = 0; gi < gpu_components.length(); gi = gi + 1 {
    match self.gpu_store(gpu_components[gi]) {
      Some(store) => {
        mark_gpu_component_batch_dirty(store, entities, min_index, max_index)
        self.replace_gpu_store(store)
      }
      None => ()
    }
  }
  entities
}

///|
pub fn SpawnBatchRow::entity(self : SpawnBatchRow) -> EntityId {
  self.entity
}

///|
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
    Some(rc) =>
      match rc.kind {
        CpuOnly => {
          let col_index = arch.column_index(component)
          if col_index < 0 {
            abort("SpawnBatchRow::write_view: missing CPU column")
          }
          let col = arch.columns[col_index]
          let base = self.row * col.stride
          col.bytes.mut_view(start=base, end=base + col.stride)
        }
        GpuVisible =>
          match
            self.world.ensure_gpu_store_capacity(
              component,
              self.entity.index + 1,
            ) {
            Some(store) => {
              let base = self.entity.index * store.stride
              store.bytes.mut_view(start=base, end=base + store.stride)
            }
            None => abort("SpawnBatchRow::write_view: missing GPU store")
          }
      }
    None => abort("SpawnBatchRow::write_view: unknown component")
  }
}
