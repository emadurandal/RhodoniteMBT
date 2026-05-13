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
/// Native hot path for bulk-updating builtin `Transform3D.position` without constructing `QueryRow`
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
