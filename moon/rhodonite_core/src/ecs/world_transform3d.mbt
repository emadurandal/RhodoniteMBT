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
  self.add_component_bytes(
    entity,
    self.transform_component_id,
    @comp.transform3d_trs_bytes(px, py, pz, qx, qy, qz, qw, sx, sy, sz),
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
