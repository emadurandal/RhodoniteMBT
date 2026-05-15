///|
fn World::global_transform_ref_from_bytes(
  self : World,
  bytes : FixedArray[Byte],
) -> GlobalTransformRef {
  ignore(self)
  let (format, word_offset) = @comp.global_transform_ref_from_component_bytes(
    bytes,
  )
  { format, word_offset }
}

///|
fn World::global_transform_ref_unchecked(
  self : World,
  entity : EntityId,
) -> GlobalTransformRef? {
  let id = self.global_transform_component_id
  if !self.is_alive(entity) {
    return None
  }
  let loc = match self.locations[entity.index] {
    Some(loc) => loc
    None => return None
  }
  if !component_array_contains(
      self.archetypes[loc.archetype_index].components,
      id,
    ) {
    return None
  }
  match self.archetypes[loc.archetype_index].component_bytes(loc.row, id) {
    Some(bytes) => Some(self.global_transform_ref_from_bytes(bytes))
    None => None
  }
}

///|
pub fn World::global_transform_ref(
  self : World,
  entity : EntityId,
) -> GlobalTransformRef? {
  let id = self.global_transform_component_id
  self.assert_system_component_read(id, "World::global_transform_ref")
  self.global_transform_ref_unchecked(entity)
}

///|
fn World::alloc_global_transform_ref(
  self : World,
  format : @comp.GlobalTransformGpuFormat,
  matrix : @m44.Matrix44F,
) -> GlobalTransformRef {
  let word_offset = self.global_transform_blob.alloc(format)
  self.global_transform_blob.write_matrix(format, word_offset, matrix)
  { format, word_offset }
}

///|
fn World::write_global_transform_ref_component(
  self : World,
  entity : EntityId,
  gt_ref : GlobalTransformRef,
) -> Bool {
  self.set_component_bytes(
    entity,
    self.global_transform_component_id,
    @comp.global_transform_ref_bytes(gt_ref.format, gt_ref.word_offset),
  )
}

///|
fn World::release_global_transform_ref(self : World, entity : EntityId) -> Unit {
  match self.global_transform_ref_unchecked(entity) {
    Some(gt_ref) =>
      self.global_transform_blob.free(gt_ref.format, gt_ref.word_offset)
    None => ()
  }
}

///|
/// Assigns builtin [`GlobalTransform`] for `entity`; payload is stored in the packed u32 blob.
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
    let gt_ref = self.alloc_global_transform_ref(
      self.global_transform_default_format,
      m,
    )
    self.add_component_bytes(
      entity,
      id,
      @comp.global_transform_ref_bytes(gt_ref.format, gt_ref.word_offset),
    )
  } else {
    match self.global_transform_ref(entity) {
      Some(gt_ref) => {
        self.global_transform_blob.write_matrix(
          gt_ref.format,
          gt_ref.word_offset,
          m,
        )
        true
      }
      None => false
    }
  }
}

///|
pub fn World::set_global_transform_format(
  self : World,
  entity : EntityId,
  format : @comp.GlobalTransformGpuFormat,
) -> Bool {
  let id = self.global_transform_component_id
  self.assert_system_component_write(id, "World::set_global_transform_format")
  if !self.is_alive(entity) {
    return false
  }
  let matrix = match self.get_global_transform(entity) {
    Some(m) => m
    None => @m44.Matrix44F::identity()
  }
  match self.global_transform_ref(entity) {
    Some(old_ref) => {
      if old_ref.format == format {
        return true
      }
      self.global_transform_blob.free(old_ref.format, old_ref.word_offset)
    }
    None =>
      if !self.can_add_missing_component_from_setter(
          id, "World::set_global_transform_format",
        ) {
        return false
      }
  }
  let new_ref = self.alloc_global_transform_ref(format, matrix)
  if self.has_component(entity, id) {
    self.write_global_transform_ref_component(entity, new_ref)
  } else {
    self.add_component_bytes(
      entity,
      id,
      @comp.global_transform_ref_bytes(new_ref.format, new_ref.word_offset),
    )
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
  match self.global_transform_ref(entity) {
    Some(gt_ref) =>
      Some(
        self.global_transform_blob.read_matrix(
          gt_ref.format,
          gt_ref.word_offset,
        ),
      )
    None => None
  }
}

///|
pub fn World::drain_global_transform_blob_write_views(
  self : World,
) -> Array[GpuWriteView] {
  let gt = self.global_transform_component_id
  self.assert_system_component_write(
    gt, "World::drain_global_transform_blob_write_views",
  )
  self.global_transform_blob.drain_write_views()
}

///|
pub fn World::write_global_transform_blob_range_views(
  self : World,
  first_word : Int,
  word_count : Int,
  write : (MutArrayView[Byte]) -> Unit,
) -> Array[GpuWriteView] {
  let gt = self.global_transform_component_id
  self.assert_system_component_write(
    gt, "World::write_global_transform_blob_range_views",
  )
  self.global_transform_blob.write_word_range_views(
    first_word, word_count, write,
  )
}

///|
pub fn World::drain_global_transform_blob_resize_events(
  self : World,
) -> Array[GlobalTransformBlobResizeEvent] {
  self.assert_system_structural_write(
    "World::drain_global_transform_blob_resize_events",
  )
  self.global_transform_blob.drain_resize_events()
}

///|
pub fn World::global_transform_blob_word_capacity(self : World) -> Int {
  self.global_transform_blob.word_capacity()
}

///|
pub fn World::extract_global_transform_refs(
  self : World,
  entities : Array[EntityId],
) -> FixedArray[Byte] {
  let stride = 8
  let out = FixedArray::make(entities.length() * stride, (0 : Byte))
  for i = 0; i < entities.length(); i = i + 1 {
    match self.global_transform_ref(entities[i]) {
      Some(gt_ref) => {
        @writes.put_u32_le(
          out,
          i * stride,
          @comp.global_transform_format_code(gt_ref.format),
        )
        @writes.put_u32_le(
          out,
          i * stride + 4,
          gt_ref.word_offset.reinterpret_as_uint(),
        )
      }
      None => ()
    }
  }
  out
}

///|
pub fn World::write_global_transform_refs_into(
  self : World,
  entities : Array[EntityId],
  dst : FixedArray[Byte],
  stride : Int,
  offset : Int,
) -> Unit {
  if stride < offset + 8 {
    abort("World::write_global_transform_refs_into: stride too small")
  }
  if dst.length() < entities.length() * stride {
    abort("World::write_global_transform_refs_into: dst too small")
  }
  for i = 0; i < entities.length(); i = i + 1 {
    match self.global_transform_ref(entities[i]) {
      Some(gt_ref) => {
        @writes.put_u32_le(
          dst,
          i * stride + offset,
          @comp.global_transform_format_code(gt_ref.format),
        )
        @writes.put_u32_le(
          dst,
          i * stride + offset + 4,
          gt_ref.word_offset.reinterpret_as_uint(),
        )
      }
      None => ()
    }
  }
}

///|
/// Removed dense row API. Use blob refs plus `drain_global_transform_blob_write_views`.
pub fn World::write_global_transforms_dense(
  self : World,
  count : Int,
  write : (Int, MutArrayView[Byte]) -> Unit,
) -> Array[GpuWrite] {
  ignore(self)
  ignore(count)
  ignore(write)
  abort(
    "World::write_global_transforms_dense: removed; use packed GlobalTransform blob APIs",
  )
}

///|
/// Bulk-writes dense GlobalTransform rows `[0, count)` and returns borrowed upload ranges.
pub fn World::write_global_transforms_dense_views(
  self : World,
  count : Int,
  write : (Int, MutArrayView[Byte]) -> Unit,
) -> Array[GpuWriteView] {
  ignore(self)
  ignore(count)
  ignore(write)
  abort(
    "World::write_global_transforms_dense_views: removed; use packed GlobalTransform blob APIs",
  )
}

///|
/// Removed dense row API. Use blob refs plus `drain_global_transform_blob_write_views`.
pub fn World::write_global_transforms_dense_range_views(
  self : World,
  count : Int,
  write : (MutArrayView[Byte]) -> Unit,
) -> Array[GpuWriteView] {
  ignore(self)
  ignore(count)
  ignore(write)
  abort(
    "World::write_global_transforms_dense_range_views: removed; use packed GlobalTransform blob APIs",
  )
}

///|
/// Bulk-writes dense GlobalTransform rows into the raw wasm backing store.
///
/// This non-GC wasm fast path lets a host upload the same linear-memory buffer
/// returned by `global_transform_wasm_gpu_bytes_payload_ptr`, avoiding both
/// `MutArrayView` wrapper traffic and host-side transform recomputation. It is
/// intended for immediate full-buffer host upload and does not enqueue drain
/// ranges.
#cfg(target="wasm")
pub fn World::write_global_transforms_dense_wasm_bytes_range(
  self : World,
  count : Int,
  write : (FixedArray[Byte], Int, Int) -> Unit,
) -> Bool {
  ignore(self)
  ignore(count)
  ignore(write)
  abort(
    "World::write_global_transforms_dense_wasm_bytes_range: removed; use packed GlobalTransform blob APIs",
  )
}

///|
/// Returns the linear-memory payload pointer for the builtin GlobalTransform GPU store.
///
/// This is only available on the non-GC wasm backend, where JavaScript can create
/// a `Uint8Array` view over the exported wasm memory and upload the ECS GPU store
/// without recomputing the transform data on the host side. The pointer is valid
/// until the GlobalTransform GPU store grows and reallocates.
#cfg(target="wasm")
pub fn World::global_transform_wasm_gpu_bytes_payload_ptr(self : World) -> Int {
  ignore(self)
  0
}

///|
/// Returns the byte length of the builtin GlobalTransform GPU store payload.
#cfg(target="wasm")
pub fn World::global_transform_wasm_gpu_bytes_len(self : World) -> Int {
  ignore(self)
  0
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
/// Writes the world matrix into the entity's packed GlobalTransform blob slot.
fn World::compute_global_transform_for_tf_gt_bulk_row(
  self : World,
  entity : EntityId,
  has_child_of : Bool,
  leaf_local_matrix : @m44.Matrix44F,
) -> Bool {
  let world_m = if !has_child_of {
    Some(leaf_local_matrix)
  } else {
    match self.build_child_of_ancestor_chain(entity) {
      None => None
      Some(chain) =>
        self.multiply_world_chain_matrix(entity, chain, Some(leaf_local_matrix))
    }
  }
  match world_m {
    Some(m) =>
      match self.global_transform_ref(entity) {
        Some(gt_ref) => {
          self.global_transform_blob.write_matrix(
            gt_ref.format,
            gt_ref.word_offset,
            m,
          )
          true
        }
        None => false
      }
    None => false
  }
}

///|
#cfg(not(target="js"))
fn put_f32_array_le(bytes : Array[Byte], off : Int, v : Float) -> Unit {
  let u = v.reinterpret_as_uint()
  bytes[off] = (u & 0xFFU).to_byte()
  bytes[off + 1] = ((u >> 8) & 0xFFU).to_byte()
  bytes[off + 2] = ((u >> 16) & 0xFFU).to_byte()
  bytes[off + 3] = ((u >> 24) & 0xFFU).to_byte()
}

///|
/// Fallback for transform propagation that walks archetypes directly and writes packed blob slots.
fn World::try_update_global_transforms_from_transforms_archetype_path(
  self : World,
  tf : ComponentTypeId,
  gt : ComponentTypeId,
  co : ComponentTypeId,
) -> Bool {
  let mut matched = false
  for ai = 0; ai < self.archetypes.length(); ai = ai + 1 {
    let arch = self.archetypes[ai]
    let comps = arch.components
    if !component_array_contains(comps, tf) ||
      !component_array_contains(comps, gt) {
      continue
    }
    matched = true
    let tf_col_index = arch.column_index(tf)
    if tf_col_index < 0 {
      return false
    }
    if arch.columns[tf_col_index].stride != 48 {
      return false
    }
  }
  if !matched {
    return false
  }
  for ai = 0; ai < self.archetypes.length(); ai = ai + 1 {
    let arch = self.archetypes[ai]
    let comps = arch.components
    if !component_array_contains(comps, tf) ||
      !component_array_contains(comps, gt) {
      continue
    }
    let has_co = component_array_contains(comps, co)
    let tf_col = arch.columns[arch.column_index(tf)]
    let tf_bytes = tf_col.bytes
    let tf_stride = tf_col.stride
    for row = 0; row < arch.entities.length(); row = row + 1 {
      let e = arch.entities[row]
      let tf_base = row * tf_stride
      let local_m = @comp.Transform3D::local_matrix_from_component_view(
        tf_bytes[tf_base:tf_base + tf_stride],
      )
      ignore(
        self.compute_global_transform_for_tf_gt_bulk_row(e, has_co, local_m),
      )
    }
  }
  true
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
  if self.try_update_global_transforms_from_transforms_archetype_path(
      tf, gt, co,
    ) {
    return
  }
  abort(
    "World::update_global_transforms_from_transforms: archetype path unavailable",
  )
}
