///|
/// Assigns builtin [`ChildOf`] for `entity` (CPU archetype SoA only).
pub fn World::set_child_of(
  self : World,
  entity : EntityId,
  parent : EntityId,
) -> Bool {
  let id = self.child_of_component_id
  self.assert_system_component_write(id, "World::set_child_of")
  let c = @comp.ChildOf::new(parent.index, parent.generation)
  let bytes = c.to_component_bytes()
  if self.has_component(entity, id) {
    self.set_component_bytes(entity, id, bytes)
  } else if !self.can_add_missing_component_from_setter(
      id, "World::set_child_of",
    ) {
    false
  } else {
    self.add_component_bytes(entity, id, bytes)
  }
}

///|
pub fn World::get_child_of(self : World, entity : EntityId) -> EntityId? {
  let id = self.child_of_component_id
  self.assert_system_component_read(id, "World::get_child_of")
  if !self.is_alive(entity) || !self.has_component(entity, id) {
    return None
  }
  match self.component_bytes(entity, id) {
    Some(bytes) => {
      let c = @comp.ChildOf::from_component_bytes(bytes)
      Some(EntityId::new(c.parent_index, c.parent_generation))
    }
    None => None
  }
}

///|
fn get_u32_array_le(bytes : Array[Byte], off : Int) -> UInt {
  bytes[off].to_uint() |
  (bytes[off + 1].to_uint() << 8) |
  (bytes[off + 2].to_uint() << 16) |
  (bytes[off + 3].to_uint() << 24)
}

///|
fn World::child_of_parent_direct(self : World, entity : EntityId) -> EntityId? {
  if !self.is_alive(entity) {
    return None
  }
  let loc = match self.locations[entity.index] {
    Some(loc) => loc
    None => return None
  }
  let arch = self.archetypes[loc.archetype_index]
  let col_index = arch.column_index(self.child_of_component_id)
  if col_index < 0 {
    return None
  }
  let col = arch.columns[col_index]
  if col.stride < 8 {
    return None
  }
  let base = loc.row * col.stride
  Some(
    EntityId::new(
      get_u32_array_le(col.bytes, base).reinterpret_as_int(),
      get_u32_array_le(col.bytes, base + 4).reinterpret_as_int(),
    ),
  )
}

///|
/// Walks [`ChildOf`] links upward from `start` (includes `start`). Returns [`None`] on cycle,
/// out-of-range indices, or missing/dead parent link.
fn World::build_child_of_ancestor_chain(
  self : World,
  start : EntityId,
) -> Array[EntityId]? {
  let chain : Array[EntityId] = []
  let slot_count = self.generations.length()
  let visited = FixedArray::make(slot_count, false)
  let mut cur = start
  let mut walking = true
  while walking {
    if cur.index < 0 || cur.index >= slot_count {
      return None
    }
    if visited[cur.index] {
      return None
    }
    visited[cur.index] = true
    chain.push(cur)
    match self.child_of_parent_direct(cur) {
      None => walking = false
      Some(parent) =>
        if !self.is_alive(parent) {
          return None
        } else {
          cur = parent
        }
    }
  }
  Some(chain)
}
