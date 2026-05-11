///|
/// Assigns builtin [`ChildOf`] for `entity` (CPU archetype SoA only).
pub fn World::set_child_of(
  self : World,
  entity : EntityId,
  parent : EntityId,
) -> Bool {
  let c = @comp.ChildOf::new(parent.index, parent.generation)
  self.add_component_bytes(
    entity,
    self.child_of_component_id,
    c.to_component_bytes(),
  )
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
