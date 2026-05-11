///|
/// Assigns builtin [`Transform3D`] for `entity` in archetype SoA (`cpu_stride` = layout stride).
pub fn World::set_transform(
  self : World,
  entity : EntityId,
  t : @comp.Transform3D,
) -> Bool {
  self.add_component_bytes(
    entity,
    self.transform_component_id,
    t.to_component_bytes(),
  )
}

///|
pub fn World::get_transform(
  self : World,
  entity : EntityId,
) -> @comp.Transform3D? {
  let tf = self.transform_component_id
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
