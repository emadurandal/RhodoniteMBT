///|
/// Assigns builtin [`ChildOf`] for `entity` (CPU archetype SoA only).
pub fn World::set_child_of(
  self : World,
  entity : EntityId,
  parent : EntityId,
) -> Bool {
  let c = @comp.ChildOf::new(parent.index, parent.generation)
  let bytes = c.to_component_bytes()
  if self.has_component(entity, self.child_of_component_id) {
    self.set_component_bytes(entity, self.child_of_component_id, bytes)
  } else {
    self.add_component_bytes(entity, self.child_of_component_id, bytes)
  }
}

///|
pub fn World::get_child_of(self : World, entity : EntityId) -> EntityId? {
  let id = self.child_of_component_id
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
    match self.get_child_of(cur) {
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
