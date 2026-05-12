///|
/// Assigns builtin [`Transform3D`] for `entity` in archetype SoA (`cpu_stride` = layout stride).
pub fn World::set_transform(
  self : World,
  entity : EntityId,
  t : @comp.Transform3D,
) -> Bool {
  let id = self.transform_component_id
  let bytes = t.to_component_bytes()
  if self.has_component(entity, id) {
    self.set_component_bytes(entity, id, bytes)
  } else if !self.can_add_missing_component_from_setter(
      id, "World::set_transform",
    ) {
    false
  } else {
    self.add_cpu_component_bytes(entity, id, bytes)
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
    self.add_cpu_component_bytes(entity, id, bytes)
  }
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
