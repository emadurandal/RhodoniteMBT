///|
/// World-space matrix for rendering; stored in flat [`GpuComponentStore`] (column-major `f32`, matches WGSL `mat4x4<f32>`).

///|
/// ECS bulk paths use [`GlobalTransform::view_std140_gpu_row`] so [`matrix`] aliases the GPU row
/// (`payloads[1]` in [`World::update_global_transforms_from_transforms`]) with **no** separate float storage.
/// Encode/decode owned [`@m44.Matrix44F`] values with [`matrix44f_write_std140_mat4_to_gpu_row`] /
/// [`matrix44f_from_std140_gpu_bytes`].
pub(all) struct GlobalTransform {
  matrix : @m44ref.Matrix44RefF
}

///|
/// `row` must be exactly [`global_transform_gpu_layout`].stride bytes (std140 `mat4x4<f32>`).
pub fn GlobalTransform::view_std140_gpu_row(
  row : MutArrayView[Byte],
) -> GlobalTransform {
  let stride = global_transform_gpu_layout().stride
  if row.length() != stride {
    abort("GlobalTransform::view_std140_gpu_row: length mismatch")
  }
  { matrix: @m44ref.Matrix44RefF::view_std140_mat4x4_le_gpu_row(row) }
}

///|
/// std140: one `mat4x4<f32>` (64-byte stride).
pub fn global_transform_gpu_layout() -> GpuLayout {
  let fields : Array[(String, GpuFieldKind)] = [("world_matrix", Mat4x4F32)]
  GpuLayout::std140(fields)
}

///|
/// Decodes one GPU std140 `mat4x4<f32>` row into an owned [`@m44.Matrix44F`].
pub fn matrix44f_from_std140_gpu_bytes(
  bytes : FixedArray[Byte],
) -> @m44.Matrix44F {
  let layout = global_transform_gpu_layout()
  if bytes.length() != layout.stride {
    abort("matrix44f_from_std140_gpu_bytes: length mismatch")
  }
  if layout.fields.length() != 1 {
    abort("global_transform_gpu_layout: expected 1 field")
  }
  let base = layout.fields[0].offset
  @m44.Matrix44F::{
    data: (
      [
        get_gpu_f32(bytes, base + 0),
        get_gpu_f32(bytes, base + 4),
        get_gpu_f32(bytes, base + 8),
        get_gpu_f32(bytes, base + 12),
        get_gpu_f32(bytes, base + 16),
        get_gpu_f32(bytes, base + 20),
        get_gpu_f32(bytes, base + 24),
        get_gpu_f32(bytes, base + 28),
        get_gpu_f32(bytes, base + 32),
        get_gpu_f32(bytes, base + 36),
        get_gpu_f32(bytes, base + 40),
        get_gpu_f32(bytes, base + 44),
        get_gpu_f32(bytes, base + 48),
        get_gpu_f32(bytes, base + 52),
        get_gpu_f32(bytes, base + 56),
        get_gpu_f32(bytes, base + 60),
      ] : FixedArray[Float]),
  }
}

///|
/// Writes column-major [`@m44.Matrix44F`] into one std140 GPU row (same packing as WGSL `mat4x4`).
pub fn matrix44f_write_std140_mat4_to_gpu_row(
  m : @m44.Matrix44F,
  buf : MutArrayView[Byte],
) -> Unit {
  let layout = global_transform_gpu_layout()
  if layout.fields.length() != 1 {
    abort("global_transform_gpu_layout: expected 1 field")
  }
  if buf.length() != layout.stride {
    abort("matrix44f_write_std140_mat4_to_gpu_row: length mismatch")
  }
  let base = layout.fields[0].offset
  let d = m.data
  for i = 0; i < 16; i = i + 1 {
    put_gpu_f32_mut_view(buf, base + i * 4, d[i].to_double())
  }
}
