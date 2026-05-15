///|
/// CPU-side payload for the builtin Camera component. Camera matrices live in the
/// world's packed u32 camera blob; this row only stores the blob word offset.
pub fn camera_ref_cpu_layout() -> GpuLayout {
  GpuLayout::storage([("word_offset", U32)])
}

///|
pub fn camera_gpu_word_count() -> Int {
  72
}

///|
pub fn camera_gpu_byte_stride() -> Int {
  camera_gpu_word_count() * 4
}

///|
pub fn camera_ref_bytes(word_offset : Int) -> FixedArray[Byte] {
  let bytes = FixedArray::make(4, (0 : Byte))
  @writes.put_u32_le(bytes, 0, word_offset.reinterpret_as_uint())
  bytes
}

///|
pub fn camera_ref_from_component_bytes(bytes : FixedArray[Byte]) -> Int {
  if bytes.length() != 4 {
    abort("camera_ref_from_component_bytes: length mismatch")
  }
  @writes.get_u32_le(bytes, 0).reinterpret_as_int()
}

///|
pub fn camera_ref_from_component_view(bytes : ArrayView[Byte]) -> Int {
  if bytes.length() != 4 {
    abort("camera_ref_from_component_view: length mismatch")
  }
  @writes.get_u32_le_byte_view(bytes, 0).reinterpret_as_int()
}

///|
pub fn camera_write_ref_mut_view(
  bytes : MutArrayView[Byte],
  word_offset : Int,
) -> Unit {
  if bytes.length() != 4 {
    abort("camera_write_ref_mut_view: length mismatch")
  }
  @writes.put_u32_le_mut_view(bytes, 0, word_offset.reinterpret_as_uint())
}

///|
fn matrix44f_write_std140_at(
  row : MutArrayView[Byte],
  offset : Int,
  m : @m44.Matrix44F,
) -> Unit {
  matrix44f_write_std140_mat4_to_gpu_row(
    m,
    row.mut_view(start=offset, end=offset + 64),
  )
}

///|
fn camera_world_position_from_view(
  view : @m44.Matrix44F,
) -> (Float, Float, Float) {
  let inv_view = match view.inverse() {
    Some(m) => m
    None => @m44.Matrix44F::identity()
  }
  (inv_view.at(0, 3), inv_view.at(1, 3), inv_view.at(2, 3))
}

///|
/// Writes one packed Camera GPU row:
///
/// - 0: `view_proj`
/// - 64: `view`
/// - 128: `proj`
/// - 192: `inv_view_proj`
/// - 256: `world_pos.xyz`, `near`
/// - 272: `far`, `aspect`, `projection_kind`, `flags`
pub fn camera_write_gpu_row(
  row : MutArrayView[Byte],
  view : @m44.Matrix44F,
  proj : @m44.Matrix44F,
  near : Float,
  far : Float,
  aspect : Float,
  projection_kind : Float,
  flags : Float,
) -> Unit {
  if row.length() != camera_gpu_byte_stride() {
    abort("camera_write_gpu_row: length mismatch")
  }
  let view_proj = proj.mat_mul(view)
  let inv_view_proj = match view_proj.inverse() {
    Some(m) => m
    None => @m44.Matrix44F::identity()
  }
  matrix44f_write_std140_at(row, 0, view_proj)
  matrix44f_write_std140_at(row, 64, view)
  matrix44f_write_std140_at(row, 128, proj)
  matrix44f_write_std140_at(row, 192, inv_view_proj)
  let (wx, wy, wz) = camera_world_position_from_view(view)
  put_gpu_f32_mut_view(row, 256, wx.to_double())
  put_gpu_f32_mut_view(row, 260, wy.to_double())
  put_gpu_f32_mut_view(row, 264, wz.to_double())
  put_gpu_f32_mut_view(row, 268, near.to_double())
  put_gpu_f32_mut_view(row, 272, far.to_double())
  put_gpu_f32_mut_view(row, 276, aspect.to_double())
  put_gpu_f32_mut_view(row, 280, projection_kind.to_double())
  put_gpu_f32_mut_view(row, 284, flags.to_double())
}

///|
pub fn camera_gpu_bytes(
  view : @m44.Matrix44F,
  proj : @m44.Matrix44F,
  near : Float,
  far : Float,
  aspect : Float,
  projection_kind : Float,
  flags : Float,
) -> FixedArray[Byte] {
  let bytes = FixedArray::make(camera_gpu_byte_stride(), (0 : Byte))
  camera_write_gpu_row(
    bytes.mut_view(start=0, end=bytes.length()),
    view,
    proj,
    near,
    far,
    aspect,
    projection_kind,
    flags,
  )
  bytes
}

///|
pub fn camera_view_proj_from_gpu_bytes(
  bytes : FixedArray[Byte],
) -> @m44.Matrix44F {
  if bytes.length() != camera_gpu_byte_stride() {
    abort("camera_view_proj_from_gpu_bytes: length mismatch")
  }
  @m44.Matrix44F::{
    data: (
      [
        get_gpu_f32(bytes, 0),
        get_gpu_f32(bytes, 4),
        get_gpu_f32(bytes, 8),
        get_gpu_f32(bytes, 12),
        get_gpu_f32(bytes, 16),
        get_gpu_f32(bytes, 20),
        get_gpu_f32(bytes, 24),
        get_gpu_f32(bytes, 28),
        get_gpu_f32(bytes, 32),
        get_gpu_f32(bytes, 36),
        get_gpu_f32(bytes, 40),
        get_gpu_f32(bytes, 44),
        get_gpu_f32(bytes, 48),
        get_gpu_f32(bytes, 52),
        get_gpu_f32(bytes, 56),
        get_gpu_f32(bytes, 60),
      ] : FixedArray[Float]),
  }
}
