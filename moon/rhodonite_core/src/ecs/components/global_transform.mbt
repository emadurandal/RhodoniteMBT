///|
/// World-space matrix for rendering; stored in flat [`GpuComponentStore`] (column-major `f32`, matches WGSL `mat4x4<f32>`).

///|
/// ECS bulk paths use [`GlobalTransform::view_std140_gpu_row`] so [`matrix`] aliases the GPU row
/// returned by [`QueryRow::write_view`] with **no** separate float storage.
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
  // Hot path: do not call global_transform_gpu_layout() (avoids per-row Array alloc).
  let stride = 64
  if row.length() != stride {
    abort("GlobalTransform::view_std140_gpu_row: length mismatch")
  }
  { matrix: @m44ref.Matrix44RefF::view_std140_mat4x4_le_gpu_row(row) }
}

///|
/// std140: one `mat4x4<f32>` (64-byte stride).
pub fn global_transform_gpu_layout() -> GpuLayout {
  {
    fields: [
      { name: "world_matrix", kind: Mat4x4F32, offset: 0, size: 64, align: 16 },
    ],
    stride: 64,
    align: 16,
  }
}

///|
/// Decodes one GPU std140 `mat4x4<f32>` row into an owned [`@m44.Matrix44F`].
pub fn matrix44f_from_std140_gpu_bytes(
  bytes : FixedArray[Byte],
) -> @m44.Matrix44F {
  let stride = 64
  if bytes.length() != stride {
    abort("matrix44f_from_std140_gpu_bytes: length mismatch")
  }
  let base = 0
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
  // Hot path: fixed std140 mat4 row (must match global_transform_gpu_layout).
  if buf.length() != 64 {
    abort("matrix44f_write_std140_mat4_to_gpu_row: length mismatch")
  }
  let base = 0
  let d = m.data
  for i = 0; i < 16; i = i + 1 {
    @writes.put_u32_le_mut_view(buf, base + i * 4, d[i].reinterpret_as_uint())
  }
}
