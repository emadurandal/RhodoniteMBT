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
#cfg(target="js")
extern "js" fn World::update_global_transforms_no_child_fast_path_js(
  self : World,
  tf : ComponentTypeId,
  gt : ComponentTypeId,
  co : ComponentTypeId,
) -> Bool =
  #| (world, tf, gt, co) => {
  #|   const tfIndex = tf.index;
  #|   const gtIndex = gt.index;
  #|   const coIndex = co.index;
  #|   const gtStore = world.gpu_stores[gtIndex];
  #|   if (!gtStore || gtStore.stride < 64) return false;
  #|
  #|   const archetypes = world.archetypes;
  #|   for (let ai = 0; ai < archetypes.length; ai++) {
  #|     const arch = archetypes[ai];
  #|     const comps = arch.components;
  #|     let hasTf = false, hasGt = false, hasCo = false;
  #|     for (let ci = 0; ci < comps.length; ci++) {
  #|       const idx = comps[ci].index;
  #|       if (idx === tfIndex) hasTf = true;
  #|       else if (idx === gtIndex) hasGt = true;
  #|       else if (idx === coIndex) hasCo = true;
  #|     }
  #|     if (hasTf && hasGt && hasCo) return false;
  #|   }
  #|
  #|   if (!ArrayBuffer.isView(gtStore.bytes)) {
  #|     const converted = new Uint8Array(gtStore.bytes.length);
  #|     converted.set(gtStore.bytes);
  #|     gtStore.bytes = converted;
  #|   }
  #|   const gtBytes = gtStore.bytes;
  #|   const gtView = new DataView(gtBytes.buffer, gtBytes.byteOffset, gtBytes.byteLength);
  #|   const gtStride = gtStore.stride;
  #|   const capacity = Math.floor(gtBytes.length / gtStride);
  #|   const dirtyFlags = gtStore.dirty_flags;
  #|   const dirtyIndices = gtStore.dirty_indices;
  #|
  #|   const scratch = globalThis.__rhodonite_f32_scratch ||
  #|     (globalThis.__rhodonite_f32_scratch = { u32: new Uint32Array(1), f32: null });
  #|   if (!scratch.f32) scratch.f32 = new Float32Array(scratch.u32.buffer);
  #|   const u32 = scratch.u32;
  #|   const f32buf = scratch.f32;
  #|   const readF32 = (bytes, i) => {
  #|     u32[0] = (
  #|       (bytes[i] & 0xff) |
  #|       ((bytes[i + 1] & 0xff) << 8) |
  #|       ((bytes[i + 2] & 0xff) << 16) |
  #|       ((bytes[i + 3] & 0xff) << 24)
  #|     ) >>> 0;
  #|     return f32buf[0];
  #|   };
  #|   const writeF32 = (offset, value) => {
  #|     gtView.setFloat32(offset, Math.fround(value), true);
  #|   };
  #|
  #|   for (let ai = 0; ai < archetypes.length; ai++) {
  #|     const arch = archetypes[ai];
  #|     const comps = arch.components;
  #|     let hasGt = false;
  #|     let tfColumn = null;
  #|     for (let ci = 0; ci < arch.columns.length; ci++) {
  #|       const col = arch.columns[ci];
  #|       const idx = col.component.index;
  #|       if (idx === tfIndex) tfColumn = col;
  #|       else if (idx === gtIndex) hasGt = true;
  #|     }
  #|     if (!tfColumn) continue;
  #|     if (!hasGt) {
  #|       for (let ci = 0; ci < comps.length; ci++) {
  #|         if (comps[ci].index === gtIndex) {
  #|           hasGt = true;
  #|           break;
  #|         }
  #|       }
  #|     }
  #|     if (!hasGt) continue;
  #|
  #|     const tfBytes = tfColumn.bytes;
  #|     const tfStride = tfColumn.stride;
  #|     const entities = arch.entities;
  #|     for (let row = 0; row < entities.length; row++) {
  #|       const entityIndex = entities[row].index;
  #|       if (entityIndex < 0 || entityIndex >= capacity) return false;
  #|       const b = row * tfStride;
  #|       const px = readF32(tfBytes, b);
  #|       const py = readF32(tfBytes, b + 4);
  #|       const pz = readF32(tfBytes, b + 8);
  #|       const qx = readF32(tfBytes, b + 12);
  #|       const qy = readF32(tfBytes, b + 16);
  #|       const qz = readF32(tfBytes, b + 20);
  #|       const qw = readF32(tfBytes, b + 24);
  #|       const sx = readF32(tfBytes, b + 28);
  #|       const sy = readF32(tfBytes, b + 32);
  #|       const sz = readF32(tfBytes, b + 36);
  #|
  #|       const xx = Math.fround(qx * qx);
  #|       const yy = Math.fround(qy * qy);
  #|       const zz = Math.fround(qz * qz);
  #|       const xy = Math.fround(qx * qy);
  #|       const xz = Math.fround(qx * qz);
  #|       const yz = Math.fround(qy * qz);
  #|       const wx = Math.fround(qw * qx);
  #|       const wy = Math.fround(qw * qy);
  #|       const wz = Math.fround(qw * qz);
  #|       const r00 = Math.fround(1 - Math.fround(2 * Math.fround(yy + zz)));
  #|       const r01 = Math.fround(2 * Math.fround(xy - wz));
  #|       const r02 = Math.fround(2 * Math.fround(xz + wy));
  #|       const r10 = Math.fround(2 * Math.fround(xy + wz));
  #|       const r11 = Math.fround(1 - Math.fround(2 * Math.fround(xx + zz)));
  #|       const r12 = Math.fround(2 * Math.fround(yz - wx));
  #|       const r20 = Math.fround(2 * Math.fround(xz - wy));
  #|       const r21 = Math.fround(2 * Math.fround(yz + wx));
  #|       const r22 = Math.fround(1 - Math.fround(2 * Math.fround(xx + yy)));
  #|
  #|       const out = entityIndex * gtStride;
  #|       writeF32(out, Math.fround(r00 * sx));
  #|       writeF32(out + 4, Math.fround(r10 * sx));
  #|       writeF32(out + 8, Math.fround(r20 * sx));
  #|       writeF32(out + 12, 0);
  #|       writeF32(out + 16, Math.fround(r01 * sy));
  #|       writeF32(out + 20, Math.fround(r11 * sy));
  #|       writeF32(out + 24, Math.fround(r21 * sy));
  #|       writeF32(out + 28, 0);
  #|       writeF32(out + 32, Math.fround(r02 * sz));
  #|       writeF32(out + 36, Math.fround(r12 * sz));
  #|       writeF32(out + 40, Math.fround(r22 * sz));
  #|       writeF32(out + 44, 0);
  #|       writeF32(out + 48, px);
  #|       writeF32(out + 52, py);
  #|       writeF32(out + 56, pz);
  #|       writeF32(out + 60, 1);
  #|
  #|       if (!dirtyFlags[entityIndex]) {
  #|         dirtyFlags[entityIndex] = true;
  #|         dirtyIndices.push(entityIndex);
  #|       }
  #|     }
  #|   }
  #|   return true;
  #| }

///|
#cfg(target="js")
fn World::try_update_global_transforms_no_child_fast_path(
  self : World,
  tf : ComponentTypeId,
  gt : ComponentTypeId,
  co : ComponentTypeId,
) -> Bool {
  self.update_global_transforms_no_child_fast_path_js(tf, gt, co)
}

///|
#cfg(not(target="js"))
fn World::try_update_global_transforms_no_child_fast_path(
  self : World,
  tf : ComponentTypeId,
  gt : ComponentTypeId,
  co : ComponentTypeId,
) -> Bool {
  ignore(self)
  ignore(tf)
  ignore(gt)
  ignore(co)
  false
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
  if self.try_update_global_transforms_no_child_fast_path(tf, gt, co) {
    return
  }
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
