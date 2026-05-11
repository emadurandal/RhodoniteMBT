///|
/// Assigns builtin [`GlobalTransform`] for `entity`: archetype signature uses zero-byte SoA row; payload is flat GPU only.
pub fn World::set_global_transform(
  self : World,
  entity : EntityId,
  m : @m44.Matrix44F,
) -> Bool {
  let id = self.global_transform_component_id
  if !self.has_component(entity, id) {
    let empty : FixedArray[Byte] = FixedArray::make(0, (0 : Byte))
    if !self.add_component_bytes(entity, id, empty) {
      return false
    }
  }
  match self.gpu_store(id) {
    Some(store) => {
      store.mut_entity_row(entity.index, fn(view) {
        @comp.matrix44f_write_std140_mat4_to_gpu_row(m, view)
      })
      self.replace_gpu_store(store)
      true
    }
    None => false
  }
}

///|
pub fn World::get_global_transform(
  self : World,
  entity : EntityId,
) -> @m44.Matrix44F? {
  let id = self.global_transform_component_id
  if !self.is_alive(entity) || !self.has_component(entity, id) {
    return None
  }
  match self.gpu_component_bytes(entity, id) {
    Some(bytes) => Some(@comp.matrix44f_from_std140_gpu_bytes(bytes))
    None => None
  }
}
