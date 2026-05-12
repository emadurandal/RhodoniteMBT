///|
/// Assigns builtin [`GlobalTransform`] for `entity`: archetype signature uses zero-byte SoA row; payload is flat GPU only.
pub fn World::set_global_transform(
  self : World,
  entity : EntityId,
  m : @m44.Matrix44F,
) -> Bool {
  let id = self.global_transform_component_id
  self.assert_system_component_write(id, "World::set_global_transform")
  if !self.has_component(entity, id) {
    if !self.can_add_missing_component_from_setter(
        id, "World::set_global_transform",
      ) {
      return false
    }
    if !self.add_component(entity, id) {
      return false
    }
  }
  match self.ensure_gpu_store_capacity(id, entity.index + 1) {
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
  self.assert_system_component_read(id, "World::get_global_transform")
  if !self.is_alive(entity) || !self.has_component(entity, id) {
    return None
  }
  match self.component_bytes(entity, id) {
    Some(bytes) => Some(@comp.matrix44f_from_std140_gpu_bytes(bytes))
    None => None
  }
}

///|
/// `leaf_local_matrix`: when [`Some`], used for `leaf` instead of [`get_transform`] (TF+GT bulk row path).
fn World::multiply_world_chain_matrix(
  self : World,
  leaf : EntityId,
  chain : Array[EntityId],
  leaf_local_matrix : @m44.Matrix44F?,
) -> @m44.Matrix44F? {
  let mut world_m = @m44.Matrix44F::identity()
  let mut i = chain.length() - 1
  while i >= 0 {
    let e = chain[i]
    let local_m : @m44.Matrix44F = if e == leaf {
      match leaf_local_matrix {
        Some(m) => m
        None =>
          match self.get_transform(e) {
            Some(t) => t.to_local_matrix()
            None => return None
          }
      }
    } else {
      match self.get_transform(e) {
        Some(t) => t.to_local_matrix()
        None => return None
      }
    }
    world_m = world_m.mat_mul(local_m)
    i = i - 1
  }
  Some(world_m)
}

///|
/// Computes world-space matrix from [`Transform3D`] along [`ChildOf`] ancestors (root → entity).
/// Returns [`None`] when `entity` is dead, lacks [`Transform3D`], an ancestor lacks [`Transform3D`],
/// a [`ChildOf`] parent is not alive, or a parent cycle is detected.
pub fn World::compute_global_transform(
  self : World,
  entity : EntityId,
) -> @m44.Matrix44F? {
  self.assert_system_component_read(
    self.transform_component_id,
    "World::compute_global_transform",
  )
  self.assert_system_component_read(
    self.child_of_component_id,
    "World::compute_global_transform",
  )
  if !self.is_alive(entity) {
    return None
  }
  match self.locations[entity.index] {
    None => None
    Some(loc) => {
      let sig = self.archetypes[loc.archetype_index].components
      let tf_id = self.transform_component_id
      if !component_array_contains(sig, tf_id) {
        return None
      }
      let co_id = self.child_of_component_id
      if !component_array_contains(sig, co_id) {
        match self.get_transform(entity) {
          None => None
          Some(tf) => Some(tf.to_local_matrix())
        }
      } else {
        match self.build_child_of_ancestor_chain(entity) {
          None => None
          Some(chain) => self.multiply_world_chain_matrix(entity, chain, None)
        }
      }
    }
  }
}

///|
/// Used only by [`update_global_transforms_from_transforms`]: entity comes from a TF+GT query row and
/// `leaf_local_matrix` was decoded from that row's Transform SoA view (no [`get_transform`] on the leaf).
/// Writes the world matrix into `gt_row` (one std140 GPU row) and returns whether a matrix was written.
fn World::compute_global_transform_for_tf_gt_bulk_row(
  self : World,
  entity : EntityId,
  has_child_of : Bool,
  leaf_local_matrix : @m44.Matrix44F,
  gt_row : MutArrayView[Byte],
) -> Bool {
  if !has_child_of {
    @comp.matrix44f_write_std140_mat4_to_gpu_row(leaf_local_matrix, gt_row)
    true
  } else {
    match self.build_child_of_ancestor_chain(entity) {
      None => false
      Some(chain) =>
        match
          self.multiply_world_chain_matrix(
            entity,
            chain,
            Some(leaf_local_matrix),
          ) {
          None => false
          Some(world_m) => {
            @comp.matrix44f_write_std140_mat4_to_gpu_row(world_m, gt_row)
            true
          }
        }
    }
  }
}

///|
/// Recomputes [`GlobalTransform`] GPU payloads from [`Transform3D`] (and optional [`ChildOf`] hierarchy)
/// for every entity that currently has **both** builtin transforms.
pub fn World::update_global_transforms_from_transforms(self : World) -> Unit {
  let tf = self.transform_component_id
  let gt = self.global_transform_component_id
  let co = self.child_of_component_id
  self.assert_system_component_read(
    tf, "World::update_global_transforms_from_transforms",
  )
  self.assert_system_component_read(
    co, "World::update_global_transforms_from_transforms",
  )
  self.assert_system_component_write(
    gt, "World::update_global_transforms_from_transforms",
  )
  let required : Array[ComponentTypeId] = [tf, gt]
  let query = Query::new(required)
  query.for_each(self, row => {
    let e = row.entity()
    let local_m = @comp.Transform3D::local_matrix_from_component_view(
      row.read_view(tf),
    )
    let gt_row = row.write_view(gt)
    ignore(
      self.compute_global_transform_for_tf_gt_bulk_row(
        e,
        self.has_component(e, co),
        local_m,
        gt_row,
      ),
    )
  })
}
