///|
fn World::global_transform_gpu_layout_stride(self : World) -> Int {
  match self.global_transform_gpu_format {
    Affine3x4F32 => 48
    Affine3x4F16 => 24
  }
}

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
        @comp.matrix44f_write_global_transform_to_gpu_row(
          m,
          view,
          self.global_transform_gpu_format,
        )
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
    Some(bytes) =>
      Some(
        @comp.matrix44f_from_global_transform_gpu_bytes(
          bytes,
          self.global_transform_gpu_format,
        ),
      )
    None => None
  }
}

///|
/// Bulk-writes dense GlobalTransform rows `[0, count)` and returns the upload ranges.
pub fn World::write_global_transforms_dense(
  self : World,
  count : Int,
  write : (Int, MutArrayView[Byte]) -> Unit,
) -> Array[GpuWrite] {
  let gt = self.global_transform_component_id
  self.assert_system_component_write(gt, "World::write_global_transforms_dense")
  if count < 0 {
    abort("World::write_global_transforms_dense: count must be non-negative")
  }
  if count == 0 {
    return []
  }
  let ok = self.with_gpu_component_write_range(gt, 0, count, range => {
    let bytes = range.bytes()
    let stride = range.stride()
    if stride != self.global_transform_gpu_layout_stride() {
      abort(
        "World::write_global_transforms_dense: GlobalTransform stride mismatch",
      )
    }
    for i = 0; i < count; i = i + 1 {
      let base = i * stride
      write(i, bytes.mut_view(start=base, end=base + stride))
    }
  })
  if !ok {
    return []
  }
  self.drain_gpu_writes(gt)
}

///|
/// Bulk-writes dense GlobalTransform rows `[0, count)` and returns borrowed upload ranges.
pub fn World::write_global_transforms_dense_views(
  self : World,
  count : Int,
  write : (Int, MutArrayView[Byte]) -> Unit,
) -> Array[GpuWriteView] {
  let gt = self.global_transform_component_id
  self.assert_system_component_write(
    gt, "World::write_global_transforms_dense_views",
  )
  if count < 0 {
    abort(
      "World::write_global_transforms_dense_views: count must be non-negative",
    )
  }
  if count == 0 {
    return []
  }
  let ok = self.with_gpu_component_write_range(gt, 0, count, range => {
    let bytes = range.bytes()
    let stride = range.stride()
    if stride != self.global_transform_gpu_layout_stride() {
      abort(
        "World::write_global_transforms_dense_views: GlobalTransform stride mismatch",
      )
    }
    for i = 0; i < count; i = i + 1 {
      let base = i * stride
      write(i, bytes.mut_view(start=base, end=base + stride))
    }
  })
  if !ok {
    return []
  }
  self.drain_gpu_write_views(gt)
}

///|
/// Bulk-writes dense GlobalTransform rows `[0, count)` through one contiguous range callback.
///
/// This is the high-throughput variant of [`write_global_transforms_dense_views`]. The callback
/// receives one `GpuComponentWriteRange` with the backing bytes and row stride, so user code can run
/// its own tight loop without a callback per entity. The callback must fully update any lanes it
/// wants to change; the dirty range is the full `[0, count)` row span.
pub fn World::write_global_transforms_dense_range_views(
  self : World,
  count : Int,
  write : (GpuComponentWriteRange) -> Unit,
) -> Array[GpuWriteView] {
  let gt = self.global_transform_component_id
  self.assert_system_component_write(
    gt, "World::write_global_transforms_dense_range_views",
  )
  if count < 0 {
    abort(
      "World::write_global_transforms_dense_range_views: count must be non-negative",
    )
  }
  if count == 0 {
    return []
  }
  let ok = self.with_gpu_component_write_range(gt, 0, count, range => {
    if range.stride() != self.global_transform_gpu_layout_stride() {
      abort(
        "World::write_global_transforms_dense_range_views: GlobalTransform stride mismatch",
      )
    }
    write(range)
  })
  if !ok {
    return []
  }
  self.drain_gpu_write_views(gt)
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
  let gt = self.global_transform_component_id
  self.assert_system_component_write(
    gt, "World::write_global_transforms_dense_wasm_bytes_range",
  )
  if count < 0 {
    abort(
      "World::write_global_transforms_dense_wasm_bytes_range: count must be non-negative",
    )
  }
  if count == 0 {
    return true
  }
  match self.ensure_gpu_store_capacity(gt, count) {
    Some(store) => {
      if store.stride != self.global_transform_gpu_layout_stride() {
        abort(
          "World::write_global_transforms_dense_wasm_bytes_range: GlobalTransform stride mismatch",
        )
      }
      self.query_depth = self.query_depth + 1
      write(store.bytes, store.stride, count)
      self.query_depth = self.query_depth - 1
      self.replace_gpu_store(store)
      true
    }
    None => false
  }
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
  let gt = self.global_transform_component_id
  self.assert_system_component_read(
    gt, "World::global_transform_wasm_gpu_bytes_payload_ptr",
  )
  match self.gpu_store(gt) {
    Some(store) => store.wasm_bytes_payload_ptr()
    None => 0
  }
}

///|
/// Returns the byte length of the builtin GlobalTransform GPU store payload.
#cfg(target="wasm")
pub fn World::global_transform_wasm_gpu_bytes_len(self : World) -> Int {
  let gt = self.global_transform_component_id
  self.assert_system_component_read(
    gt, "World::global_transform_wasm_gpu_bytes_len",
  )
  match self.gpu_store(gt) {
    Some(store) => store.wasm_bytes_len()
    None => 0
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
    @comp.matrix44f_write_global_transform_to_gpu_row(
      leaf_local_matrix,
      gt_row,
      self.global_transform_gpu_format,
    )
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
            @comp.matrix44f_write_global_transform_to_gpu_row(
              world_m,
              gt_row,
              self.global_transform_gpu_format,
            )
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
  #|   if (!gtStore || gtStore.stride < 48) return false;
  #|
  #|   const archetypes = world.archetypes;
  #|   let hasChildArchetype = false;
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
  #|     if (hasTf && hasGt && hasCo) hasChildArchetype = true;
  #|   }
  #|
  #|   if (!ArrayBuffer.isView(gtStore.bytes)) {
  #|     const converted = new Uint8Array(gtStore.bytes.length);
  #|     converted.set(gtStore.bytes);
  #|     gtStore.bytes = converted;
  #|   }
  #|   const gtBytes = gtStore.bytes;
  #|   if ((gtBytes.byteOffset & 3) !== 0 || (gtBytes.byteLength & 3) !== 0) return false;
  #|   let gtF32 = gtBytes.__rhodonite_f32_view;
  #|   if (!gtF32 || gtF32.buffer !== gtBytes.buffer || gtF32.byteOffset !== gtBytes.byteOffset || gtF32.length !== (gtBytes.byteLength >> 2)) {
  #|     gtF32 = new Float32Array(gtBytes.buffer, gtBytes.byteOffset, gtBytes.byteLength >> 2);
  #|     gtBytes.__rhodonite_f32_view = gtF32;
  #|   }
  #|   const gtStride = gtStore.stride;
  #|   if ((gtStride & 3) !== 0) return false;
  #|   const gtStrideF32 = gtStride >> 2;
  #|   const capacity = Math.floor(gtBytes.length / gtStride);
  #|   const dirtyRanges = gtStore.__rhodonite_dirty_ranges ||
  #|     (gtStore.__rhodonite_dirty_ranges = []);
  #|   const pushDirtyRange = (first, last) => {
  #|     if (first < 0 || last < first) return;
  #|     const prev = dirtyRanges[dirtyRanges.length - 1];
  #|     if (prev && first <= prev.last + 1) {
  #|       if (last > prev.last) prev.last = last;
  #|     } else {
  #|       dirtyRanges.push({ first, last });
  #|     }
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
  #|     let hasCo = false;
  #|     for (let ci = 0; ci < comps.length; ci++) {
  #|       if (comps[ci].index === coIndex) {
  #|         hasCo = true;
  #|         break;
  #|       }
  #|     }
  #|     if (hasCo) continue;
  #|
  #|     let tfBytes = tfColumn.bytes;
  #|     if (!ArrayBuffer.isView(tfBytes)) {
  #|       const converted = new Uint8Array(tfBytes.length);
  #|       converted.set(tfBytes);
  #|       tfBytes = converted;
  #|     }
  #|     const tfStride = tfColumn.stride;
  #|     if ((tfBytes.byteOffset & 3) !== 0 || (tfBytes.byteLength & 3) !== 0 || (tfStride & 3) !== 0) return false;
  #|     let tfF32 = tfBytes.__rhodonite_f32_view;
  #|     if (!tfF32 || tfF32.buffer !== tfBytes.buffer || tfF32.byteOffset !== tfBytes.byteOffset || tfF32.length !== (tfBytes.byteLength >> 2)) {
  #|       tfF32 = new Float32Array(tfBytes.buffer, tfBytes.byteOffset, tfBytes.byteLength >> 2);
  #|       tfBytes.__rhodonite_f32_view = tfF32;
  #|     }
  #|     const tfStrideF32 = tfStride >> 2;
  #|     const entities = arch.entities;
  #|     let rangeFirst = -1;
  #|     let rangePrev = -1;
  #|     for (let row = 0; row < entities.length; row++) {
  #|       const entityIndex = entities[row].index;
  #|       if (entityIndex < 0 || entityIndex >= capacity) return false;
  #|       const b = row * tfStrideF32;
  #|       const px = tfF32[b];
  #|       const py = tfF32[b + 1];
  #|       const pz = tfF32[b + 2];
  #|       const qx = tfF32[b + 3];
  #|       const qy = tfF32[b + 4];
  #|       const qz = tfF32[b + 5];
  #|       const qw = tfF32[b + 6];
  #|       const sx = tfF32[b + 7];
  #|       const sy = tfF32[b + 8];
  #|       const sz = tfF32[b + 9];
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
  #|       const out = entityIndex * gtStrideF32;
  #|       gtF32[out] = Math.fround(r00 * sx);
  #|       gtF32[out + 1] = Math.fround(r01 * sy);
  #|       gtF32[out + 2] = Math.fround(r02 * sz);
  #|       gtF32[out + 3] = px;
  #|       gtF32[out + 4] = Math.fround(r10 * sx);
  #|       gtF32[out + 5] = Math.fround(r11 * sy);
  #|       gtF32[out + 6] = Math.fround(r12 * sz);
  #|       gtF32[out + 7] = py;
  #|       gtF32[out + 8] = Math.fround(r20 * sx);
  #|       gtF32[out + 9] = Math.fround(r21 * sy);
  #|       gtF32[out + 10] = Math.fround(r22 * sz);
  #|       gtF32[out + 11] = pz;
  #|
  #|       if (rangeFirst < 0) {
  #|         rangeFirst = entityIndex;
  #|         rangePrev = entityIndex;
  #|       } else if (entityIndex === rangePrev + 1) {
  #|         rangePrev = entityIndex;
  #|       } else {
  #|         pushDirtyRange(rangeFirst, rangePrev);
  #|         rangeFirst = entityIndex;
  #|         rangePrev = entityIndex;
  #|       }
  #|     }
  #|     pushDirtyRange(rangeFirst, rangePrev);
  #|   }
  #|   return !hasChildArchetype;
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
fn get_f32_array_le(bytes : Array[Byte], off : Int) -> Float {
  Float::reinterpret_from_uint(
    bytes[off].to_uint() |
    (bytes[off + 1].to_uint() << 8) |
    (bytes[off + 2].to_uint() << 16) |
    (bytes[off + 3].to_uint() << 24),
  )
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
#cfg(not(target="js"))
fn put_f32_fixed_le(bytes : FixedArray[Byte], off : Int, v : Float) -> Unit {
  let u = v.reinterpret_as_uint()
  bytes[off] = (u & 0xFFU).to_byte()
  bytes[off + 1] = ((u >> 8) & 0xFFU).to_byte()
  bytes[off + 2] = ((u >> 16) & 0xFFU).to_byte()
  bytes[off + 3] = ((u >> 24) & 0xFFU).to_byte()
}

///|
#cfg(not(target="js"))
fn World::try_update_global_transforms_no_child_fast_path(
  self : World,
  tf : ComponentTypeId,
  gt : ComponentTypeId,
  co : ComponentTypeId,
) -> Bool {
  let gt_store = match self.gpu_store(gt) {
    Some(store) => store
    None => return false
  }
  if gt_store.stride < 48 {
    return false
  }
  let mut has_child_archetype = false
  for ai = 0; ai < self.archetypes.length(); ai = ai + 1 {
    let comps = self.archetypes[ai].components
    let has_tf = component_array_contains(comps, tf)
    let has_gt = component_array_contains(comps, gt)
    if has_tf && has_gt && component_array_contains(comps, co) {
      has_child_archetype = true
    }
  }
  let capacity = gt_store.capacity()
  for ai = 0; ai < self.archetypes.length(); ai = ai + 1 {
    let arch = self.archetypes[ai]
    let comps = arch.components
    if !component_array_contains(comps, tf) ||
      !component_array_contains(comps, gt) {
      continue
    }
    if component_array_contains(comps, co) {
      continue
    }
    let tf_col_index = arch.column_index(tf)
    if tf_col_index < 0 {
      return false
    }
    let tf_col = arch.columns[tf_col_index]
    let tf_bytes = tf_col.bytes
    let tf_stride = tf_col.stride
    if tf_stride < 40 {
      return false
    }
    let mut dirty_first = -1
    let mut dirty_prev = -1
    for row = 0; row < arch.entities.length(); row = row + 1 {
      let entity_index = arch.entities[row].index
      if entity_index < 0 || entity_index >= capacity {
        return false
      }
      let b = row * tf_stride
      let px = get_f32_array_le(tf_bytes, b)
      let py = get_f32_array_le(tf_bytes, b + 4)
      let pz = get_f32_array_le(tf_bytes, b + 8)
      let qx = get_f32_array_le(tf_bytes, b + 12)
      let qy = get_f32_array_le(tf_bytes, b + 16)
      let qz = get_f32_array_le(tf_bytes, b + 20)
      let qw = get_f32_array_le(tf_bytes, b + 24)
      let sx = get_f32_array_le(tf_bytes, b + 28)
      let sy = get_f32_array_le(tf_bytes, b + 32)
      let sz = get_f32_array_le(tf_bytes, b + 36)

      let xx = qx * qx
      let yy = qy * qy
      let zz = qz * qz
      let xy = qx * qy
      let xz = qx * qz
      let yz = qy * qz
      let wx = qw * qx
      let wy = qw * qy
      let wz = qw * qz
      let r00 = (1.0 : Float) - (2.0 : Float) * (yy + zz)
      let r01 = (2.0 : Float) * (xy - wz)
      let r02 = (2.0 : Float) * (xz + wy)
      let r10 = (2.0 : Float) * (xy + wz)
      let r11 = (1.0 : Float) - (2.0 : Float) * (xx + zz)
      let r12 = (2.0 : Float) * (yz - wx)
      let r20 = (2.0 : Float) * (xz - wy)
      let r21 = (2.0 : Float) * (yz + wx)
      let r22 = (1.0 : Float) - (2.0 : Float) * (xx + yy)

      let out = entity_index * gt_store.stride
      put_f32_fixed_le(gt_store.bytes, out, r00 * sx)
      put_f32_fixed_le(gt_store.bytes, out + 4, r01 * sy)
      put_f32_fixed_le(gt_store.bytes, out + 8, r02 * sz)
      put_f32_fixed_le(gt_store.bytes, out + 12, px)
      put_f32_fixed_le(gt_store.bytes, out + 16, r10 * sx)
      put_f32_fixed_le(gt_store.bytes, out + 20, r11 * sy)
      put_f32_fixed_le(gt_store.bytes, out + 24, r12 * sz)
      put_f32_fixed_le(gt_store.bytes, out + 28, py)
      put_f32_fixed_le(gt_store.bytes, out + 32, r20 * sx)
      put_f32_fixed_le(gt_store.bytes, out + 36, r21 * sy)
      put_f32_fixed_le(gt_store.bytes, out + 40, r22 * sz)
      put_f32_fixed_le(gt_store.bytes, out + 44, pz)
      if dirty_first < 0 {
        dirty_first = entity_index
        dirty_prev = entity_index
      } else if entity_index == dirty_prev + 1 {
        dirty_prev = entity_index
      } else {
        gt_store.mark_dirty_range(dirty_first, dirty_prev)
        dirty_first = entity_index
        dirty_prev = entity_index
      }
    }
    gt_store.mark_dirty_range(dirty_first, dirty_prev)
  }
  self.replace_gpu_store(gt_store)
  !has_child_archetype
}

///|
/// Fallback for hierarchy-capable transform propagation that still walks archetypes directly.
/// It only handles archetypes that actually carry [`ChildOf`]; no-child archetypes are handled by
/// the fast path above even when the world contains a mix of hierarchical and flat transforms.
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
    if !component_array_contains(comps, co) {
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
  let gt_store = match
    self.ensure_gpu_store_capacity(gt, self.locations.length()) {
    Some(store) => store
    None => return false
  }
  let gt_stride = self.global_transform_gpu_layout_stride()
  if gt_store.stride != gt_stride {
    return false
  }
  for ai = 0; ai < self.archetypes.length(); ai = ai + 1 {
    let arch = self.archetypes[ai]
    let comps = arch.components
    if !component_array_contains(comps, tf) ||
      !component_array_contains(comps, gt) {
      continue
    }
    if !component_array_contains(comps, co) {
      continue
    }
    let tf_col = arch.columns[arch.column_index(tf)]
    let tf_bytes = tf_col.bytes
    let tf_stride = tf_col.stride
    let mut dirty_first = -1
    let mut dirty_prev = -1
    for row = 0; row < arch.entities.length(); row = row + 1 {
      let e = arch.entities[row]
      let tf_base = row * tf_stride
      let local_m = @comp.Transform3D::local_matrix_from_component_view(
        tf_bytes[tf_base:tf_base + tf_stride],
      )
      let gt_base = e.index * gt_store.stride
      ignore(
        self.compute_global_transform_for_tf_gt_bulk_row(
          e,
          true,
          local_m,
          gt_store.bytes.mut_view(start=gt_base, end=gt_base + gt_stride),
        ),
      )
      if dirty_first < 0 {
        dirty_first = e.index
        dirty_prev = e.index
      } else if e.index == dirty_prev + 1 {
        dirty_prev = e.index
      } else {
        gt_store.mark_dirty_range(dirty_first, dirty_prev)
        dirty_first = e.index
        dirty_prev = e.index
      }
    }
    gt_store.mark_dirty_range(dirty_first, dirty_prev)
  }
  self.replace_gpu_store(gt_store)
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
  if self.try_update_global_transforms_no_child_fast_path(tf, gt, co) {
    return
  }
  if self.try_update_global_transforms_from_transforms_archetype_path(
      tf, gt, co,
    ) {
    return
  }
  let required : Array[ComponentTypeId] = [tf, gt]
  let query = Query::new(required)
  query.for_each(self, row => {
    let e = row.entity()
    let local_m = row.read_transform3d().local_matrix()
    row.write(gt, gt_row => {
      ignore(
        self.compute_global_transform_for_tf_gt_bulk_row(
          e,
          self.has_component(e, co),
          local_m,
          gt_row,
        ),
      )
    })
  })
}
