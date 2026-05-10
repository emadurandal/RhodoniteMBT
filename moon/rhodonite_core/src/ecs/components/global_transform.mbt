///|
/// World-space matrix for rendering; stored in flat [`GpuComponentStore`] (column-major `f32`, matches WGSL `mat4x4<f32>`).

///|
/// `matrix` is a column-major view over [`backing`] (16 [`Float`]s). For CPU-owned values use
/// [`GlobalTransform::from_local_matrix`]; for GPU row bulk paths use [`GlobalTransform::from_gpu_row_mut_view`]
/// then [`GlobalTransform::commit_gpu_row`]; for decode-only snapshots use [`GlobalTransform::from_gpu_bytes`].
pub(all) struct GlobalTransform {
  backing : Array[Float]
  matrix : @m44ref.Matrix44RefF
  gpu_row : MutArrayView[Byte]?
}

///|
/// Owned world matrix (no GPU sink); used by [`World::compute_global_transform`] and tests.
pub fn GlobalTransform::from_local_matrix(
  m : @m44.Matrix44F,
) -> GlobalTransform {
  let backing = Array::make(16, (0.0 : Float))
  for i = 0; i < 16; i = i + 1 {
    backing[i] = m.data[i]
  }
  let matrix = @m44ref.Matrix44Ref::from_mut_view(
    backing.mut_view(start=0, end=16),
  )
  { backing, matrix, gpu_row: None }
}

///|
/// Binds `row` as the GPU write target: [`matrix`] reads/writes [`backing`] initialized from `row`;
/// call [`commit_gpu_row`] after updating [`matrix`] to push column-major `f32` into `row`.
pub fn GlobalTransform::from_gpu_row_mut_view(
  row : MutArrayView[Byte],
) -> GlobalTransform {
  let layout = global_transform_gpu_layout()
  if row.length() != layout.stride {
    abort("GlobalTransform::from_gpu_row_mut_view: length mismatch")
  }
  if layout.fields.length() != 1 {
    abort("global_transform_gpu_layout: expected 1 field")
  }
  let base = layout.fields[0].offset
  let backing = Array::make(16, (0.0 : Float))
  for i = 0; i < 16; i = i + 1 {
    backing[i] = get_gpu_f32_mut_view(row, base + i * 4)
  }
  let matrix = @m44ref.Matrix44Ref::from_mut_view(
    backing.mut_view(start=0, end=16),
  )
  { backing, matrix, gpu_row: Some(row) }
}

///|
/// Writes [`backing`] / [`matrix`] into the bound GPU row when [`from_gpu_row_mut_view`] was used.
pub fn GlobalTransform::commit_gpu_row(self : GlobalTransform) -> Unit {
  match self.gpu_row {
    Some(row) => self.write_to_gpu_mut_view(row)
    None => ()
  }
}

///|
/// std140: one `mat4x4<f32>` (64-byte stride).
pub fn global_transform_gpu_layout() -> GpuLayout {
  let fields : Array[(String, GpuFieldKind)] = [("world_matrix", Mat4x4F32)]
  GpuLayout::std140(fields)
}

///|
/// Writes [`@m44.Matrix44::data`] column-major into one GPU row (same order as WGSL `mat4x4`).
pub fn GlobalTransform::to_gpu_bytes(
  self : GlobalTransform,
) -> FixedArray[Byte] {
  let layout = global_transform_gpu_layout()
  if layout.fields.length() != 1 {
    abort("global_transform_gpu_layout: expected 1 field")
  }
  let buf = gpu_component_bytes(layout.stride)
  let base = layout.fields[0].offset
  let m = self.matrix.data()
  for i = 0; i < 16; i = i + 1 {
    put_gpu_f32(buf, base + i * 4, m[i].to_double())
  }
  buf
}

///|
/// Writes [`to_gpu_bytes`] layout directly into one flat GPU backing row (no intermediate [`FixedArray`]).
pub fn GlobalTransform::write_to_gpu_mut_view(
  self : GlobalTransform,
  buf : MutArrayView[Byte],
) -> Unit {
  let layout = global_transform_gpu_layout()
  if layout.fields.length() != 1 {
    abort("global_transform_gpu_layout: expected 1 field")
  }
  if buf.length() != layout.stride {
    abort("GlobalTransform::write_to_gpu_mut_view: length mismatch")
  }
  let base = layout.fields[0].offset
  let m = self.matrix.data()
  for i = 0; i < 16; i = i + 1 {
    put_gpu_f32_mut_view(buf, base + i * 4, m[i].to_double())
  }
}

///|
pub fn GlobalTransform::from_gpu_bytes(
  bytes : FixedArray[Byte],
) -> GlobalTransform {
  let layout = global_transform_gpu_layout()
  if bytes.length() != layout.stride {
    abort("GlobalTransform::from_gpu_bytes: length mismatch")
  }
  if layout.fields.length() != 1 {
    abort("global_transform_gpu_layout: expected 1 field")
  }
  let base = layout.fields[0].offset
  let backing = Array::make(16, (0.0 : Float))
  for i = 0; i < 16; i = i + 1 {
    backing[i] = get_gpu_f32(bytes, base + i * 4)
  }
  let matrix = @m44ref.Matrix44Ref::from_mut_view(
    backing.mut_view(start=0, end=16),
  )
  { backing, matrix, gpu_row: None }
}
