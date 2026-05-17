///|
/// World-space affine matrix view for legacy row callbacks. The builtin ECS component now stores
/// only an 8-byte packed-blob reference; matrix payloads live in the world's u32 transform blob.

///|
/// Compatibility helpers use [`GlobalTransform::view_affine3x4_gpu_row`] so [`matrix`] aliases a
/// temporary affine row with **no** separate float storage.
/// Encode/decode owned [`@m44.Matrix44F`] values with [`matrix44f_write_affine3x4_to_gpu_row`] /
/// [`matrix44f_from_affine3x4_gpu_bytes`].
pub(all) struct GlobalTransform {
  matrix : @m44ref.Matrix44RefF
}

///|
/// GPU row format for builtin [`GlobalTransform`].
pub(all) enum GlobalTransformGpuFormat {
  Affine3x4F32
  Affine3x4F16
} derive(Eq)

///|
/// CPU-side payload for the builtin GlobalTransform component. The matrix bytes live in the
/// world's packed u32 blob; this row only stores the blob reference.
pub fn global_transform_ref_cpu_layout() -> GpuLayout {
  GpuLayout::storage([("format", U32), ("word_offset", U32)])
}

///|
/// Implements `global_transform_word_count`.
pub fn global_transform_word_count(format : GlobalTransformGpuFormat) -> Int {
  match format {
    Affine3x4F32 => 12
    Affine3x4F16 => 6
  }
}

///|
/// Implements `global_transform_format_code`.
pub fn global_transform_format_code(format : GlobalTransformGpuFormat) -> UInt {
  match format {
    Affine3x4F32 => 0U
    Affine3x4F16 => 1U
  }
}

///|
/// Implements `global_transform_format_from_code`.
pub fn global_transform_format_from_code(
  code : UInt,
) -> GlobalTransformGpuFormat {
  if code == 1U {
    Affine3x4F16
  } else {
    Affine3x4F32
  }
}

///|
/// Implements `global_transform_ref_bytes`.
pub fn global_transform_ref_bytes(
  format : GlobalTransformGpuFormat,
  word_offset : Int,
) -> FixedArray[Byte] {
  let bytes = FixedArray::make(8, (0 : Byte))
  @writes.put_u32_le(bytes, 0, global_transform_format_code(format))
  @writes.put_u32_le(bytes, 4, word_offset.reinterpret_as_uint())
  bytes
}

///|
/// Implements `global_transform_ref_from_component_bytes`.
pub fn global_transform_ref_from_component_bytes(
  bytes : FixedArray[Byte],
) -> (GlobalTransformGpuFormat, Int) {
  if bytes.length() != 8 {
    abort("global_transform_ref_from_component_bytes: length mismatch")
  }
  (
    global_transform_format_from_code(@writes.get_u32_le(bytes, 0)),
    @writes.get_u32_le(bytes, 4).reinterpret_as_int(),
  )
}

///|
/// Implements `global_transform_ref_from_component_view`.
pub fn global_transform_ref_from_component_view(
  bytes : ArrayView[Byte],
) -> (GlobalTransformGpuFormat, Int) {
  if bytes.length() != 8 {
    abort("global_transform_ref_from_component_view: length mismatch")
  }
  (
    global_transform_format_from_code(@writes.get_u32_le_byte_view(bytes, 0)),
    @writes.get_u32_le_byte_view(bytes, 4).reinterpret_as_int(),
  )
}

///|
/// Implements `global_transform_write_ref_mut_view`.
pub fn global_transform_write_ref_mut_view(
  bytes : MutArrayView[Byte],
  format : GlobalTransformGpuFormat,
  word_offset : Int,
) -> Unit {
  if bytes.length() != 8 {
    abort("global_transform_write_ref_mut_view: length mismatch")
  }
  @writes.put_u32_le_mut_view(bytes, 0, global_transform_format_code(format))
  @writes.put_u32_le_mut_view(bytes, 4, word_offset.reinterpret_as_uint())
}

///|
/// Mutable typed view over one packed GPU GlobalTransform row.
pub struct GlobalTransformGpuMutRow {
  priv view : MutArrayView[Byte]
  priv format : GlobalTransformGpuFormat
}

///|
/// `row` must be exactly [`global_transform_gpu_layout`].stride bytes (affine 3x4, 48 bytes).
pub fn GlobalTransform::view_affine3x4_gpu_row(
  row : MutArrayView[Byte],
) -> GlobalTransform {
  // Hot path: do not call global_transform_gpu_layout() (avoids per-row Array alloc).
  let stride = 48
  if row.length() != stride {
    abort("GlobalTransform::view_affine3x4_gpu_row: length mismatch")
  }
  { matrix: @m44ref.Matrix44RefF::view_affine3x4_le_gpu_row(row) }
}

///|
/// Implements `GlobalTransformGpuMutRow::from_gpu_row`.
pub fn GlobalTransformGpuMutRow::from_gpu_row(
  row : MutArrayView[Byte],
) -> GlobalTransformGpuMutRow {
  if row.length() != 48 {
    abort("GlobalTransformGpuMutRow::from_gpu_row: length mismatch")
  }
  { view: row, format: Affine3x4F32 }
}

///|
/// Implements `GlobalTransformGpuMutRow::from_gpu_row_format`.
pub fn GlobalTransformGpuMutRow::from_gpu_row_format(
  row : MutArrayView[Byte],
  format : GlobalTransformGpuFormat,
) -> GlobalTransformGpuMutRow {
  let expected = match format {
    Affine3x4F32 => 48
    Affine3x4F16 => 24
  }
  if row.length() != expected {
    abort("GlobalTransformGpuMutRow::from_gpu_row_format: length mismatch")
  }
  { view: row, format }
}

///|
/// Implements `GlobalTransformGpuMutRow::view`.
pub fn GlobalTransformGpuMutRow::view(
  self : GlobalTransformGpuMutRow,
) -> GlobalTransform {
  if self.format != Affine3x4F32 {
    abort(
      "GlobalTransformGpuMutRow::view: fp16 rows do not expose Matrix44RefF",
    )
  }
  GlobalTransform::view_affine3x4_gpu_row(self.view)
}

///|
/// Implements `GlobalTransformGpuMutRow::write_matrix`.
pub fn GlobalTransformGpuMutRow::write_matrix(
  self : GlobalTransformGpuMutRow,
  m : @m44.Matrix44F,
) -> Unit {
  matrix44f_write_global_transform_to_gpu_row(m, self.view, self.format)
}

///|
/// Implements `GlobalTransformGpuMutRow::write_identity`.
pub fn GlobalTransformGpuMutRow::write_identity(
  self : GlobalTransformGpuMutRow,
) -> Unit {
  global_transform_write_identity_row_format(self.view, self.format)
}

///|
/// Compatibility alias for older call sites. The backing row is now affine 3x4, not std140 mat4.
pub fn GlobalTransform::view_std140_gpu_row(
  row : MutArrayView[Byte],
) -> GlobalTransform {
  if row.length() == 64 {
    { matrix: @m44ref.Matrix44RefF::view_std140_mat4x4_le_gpu_row(row) }
  } else {
    GlobalTransform::view_affine3x4_gpu_row(row)
  }
}

///|
/// Three `vec4<f32>` rows: `row0`, `row1`, `row2` (48-byte stride).
pub fn global_transform_gpu_layout() -> GpuLayout {
  {
    fields: [
      { name: "world_row0", kind: Vec4F32, offset: 0, size: 16, align: 16 },
      { name: "world_row1", kind: Vec4F32, offset: 16, size: 16, align: 16 },
      { name: "world_row2", kind: Vec4F32, offset: 32, size: 16, align: 16 },
    ],
    stride: 48,
    align: 16,
  }
}

///|
/// Three `vec4<f16>` rows: `row0`, `row1`, `row2` (24-byte stride).
pub fn global_transform_gpu_layout_f16() -> GpuLayout {
  {
    fields: [
      { name: "world_row0", kind: Vec4F16, offset: 0, size: 8, align: 8 },
      { name: "world_row1", kind: Vec4F16, offset: 8, size: 8, align: 8 },
      { name: "world_row2", kind: Vec4F16, offset: 16, size: 8, align: 8 },
    ],
    stride: 24,
    align: 8,
  }
}

///|
/// Decodes one GPU affine 3x4 row into an owned [`@m44.Matrix44F`].
pub fn matrix44f_from_affine3x4_gpu_bytes(
  bytes : FixedArray[Byte],
) -> @m44.Matrix44F {
  let stride = 48
  if bytes.length() != stride {
    abort("matrix44f_from_affine3x4_gpu_bytes: length mismatch")
  }
  let base = 0
  @m44.Matrix44F::{
    data: (
      [
        get_gpu_f32(bytes, base + 0),
        get_gpu_f32(bytes, base + 16),
        get_gpu_f32(bytes, base + 32),
        (0.0 : Float),
        get_gpu_f32(bytes, base + 4),
        get_gpu_f32(bytes, base + 20),
        get_gpu_f32(bytes, base + 36),
        (0.0 : Float),
        get_gpu_f32(bytes, base + 8),
        get_gpu_f32(bytes, base + 24),
        get_gpu_f32(bytes, base + 40),
        (0.0 : Float),
        get_gpu_f32(bytes, base + 12),
        get_gpu_f32(bytes, base + 28),
        get_gpu_f32(bytes, base + 44),
        (1.0 : Float),
      ] : FixedArray[Float]),
  }
}

///|
/// Implements `get_gpu_u16`.
fn get_gpu_u16(buf : FixedArray[Byte], offset : Int) -> UInt {
  buf[offset].to_uint() | (buf[offset + 1].to_uint() << 8)
}

///|
/// Implements `put_gpu_u16_mut_view`.
fn put_gpu_u16_mut_view(
  buf : MutArrayView[Byte],
  offset : Int,
  value : UInt,
) -> Unit {
  @writes.put_u16_le_mut_view(buf, offset, value)
}

///|
/// Implements `global_transform_f32_to_f16_bits`.
#cfg(target="native")
pub extern "C" fn global_transform_f32_to_f16_bits(value : Float) -> UInt = "rhodonite_global_transform_f32_to_f16_bits"

///|
/// Implements `global_transform_f32_to_f16_bits`.
#cfg(not(target="native"))
pub fn global_transform_f32_to_f16_bits(value : Float) -> UInt {
  let bits = value.reinterpret_as_uint()
  let sign = (bits >> 16) & 0x8000U
  let exp = ((bits >> 23) & 0xFFU).reinterpret_as_int()
  let mant = bits & 0x7FFFFFU
  if exp == 255 {
    if mant == 0U {
      return sign | 0x7C00U
    }
    return sign | 0x7E00U
  }
  let half_exp = exp - 127 + 15
  if half_exp >= 31 {
    return sign | 0x7C00U
  }
  if half_exp <= 0 {
    if half_exp < -10 {
      return sign
    }
    let mantissa = mant | 0x800000U
    let shift = 14 - half_exp
    let mut half_mant = mantissa >> shift
    if ((mantissa >> (shift - 1)) & 1U) != 0U {
      half_mant = half_mant + 1U
    }
    return sign | half_mant
  }
  let mut half = sign | (half_exp.reinterpret_as_uint() << 10) | (mant >> 13)
  if ((mant >> 12) & 1U) != 0U {
    half = half + 1U
  }
  half
}

///|
/// Writes a f32 value as little-endian fp16 bits into a byte view.
#cfg(target="native")
#borrow(buf)
pub extern "C" fn global_transform_put_f16_le_mut_view(
  buf : MutArrayView[Byte],
  offset : Int,
  value : Float,
) -> Unit = "rhodonite_global_transform_put_f16_le_mut_view"

///|
/// Writes a f32 value as little-endian fp16 bits into a byte view.
#cfg(not(target="native"))
pub fn global_transform_put_f16_le_mut_view(
  buf : MutArrayView[Byte],
  offset : Int,
  value : Float,
) -> Unit {
  @writes.put_u16_le_mut_view(
    buf,
    offset,
    global_transform_f32_to_f16_bits(value),
  )
}

///|
/// Implements `f16_bits_to_f32`.
fn f16_bits_to_f32(bits16 : UInt) -> Float {
  let sign = (bits16 & 0x8000U) << 16
  let exp = (bits16 >> 10) & 0x1FU
  let mant = bits16 & 0x03FFU
  let bits32 = if exp == 0U {
    if mant == 0U {
      sign
    } else {
      let mut m = mant
      let mut e = -14
      while (m & 0x0400U) == 0U {
        m = m << 1
        e = e - 1
      }
      m = m & 0x03FFU
      sign | ((e + 127).reinterpret_as_uint() << 23) | (m << 13)
    }
  } else if exp == 0x1FU {
    sign | 0x7F800000U | (mant << 13)
  } else {
    sign |
    ((exp.reinterpret_as_int() - 15 + 127).reinterpret_as_uint() << 23) |
    (mant << 13)
  }
  Float::reinterpret_from_uint(bits32)
}

///|
/// Decodes one GPU affine 3x4 fp16 row into an owned [`@m44.Matrix44F`].
pub fn matrix44f_from_affine3x4_f16_gpu_bytes(
  bytes : FixedArray[Byte],
) -> @m44.Matrix44F {
  let stride = 24
  if bytes.length() != stride {
    abort("matrix44f_from_affine3x4_f16_gpu_bytes: length mismatch")
  }
  let base = 0
  @m44.Matrix44F::{
    data: (
      [
        f16_bits_to_f32(get_gpu_u16(bytes, base + 0)),
        f16_bits_to_f32(get_gpu_u16(bytes, base + 8)),
        f16_bits_to_f32(get_gpu_u16(bytes, base + 16)),
        (0.0 : Float),
        f16_bits_to_f32(get_gpu_u16(bytes, base + 2)),
        f16_bits_to_f32(get_gpu_u16(bytes, base + 10)),
        f16_bits_to_f32(get_gpu_u16(bytes, base + 18)),
        (0.0 : Float),
        f16_bits_to_f32(get_gpu_u16(bytes, base + 4)),
        f16_bits_to_f32(get_gpu_u16(bytes, base + 12)),
        f16_bits_to_f32(get_gpu_u16(bytes, base + 20)),
        (0.0 : Float),
        f16_bits_to_f32(get_gpu_u16(bytes, base + 6)),
        f16_bits_to_f32(get_gpu_u16(bytes, base + 14)),
        f16_bits_to_f32(get_gpu_u16(bytes, base + 22)),
        (1.0 : Float),
      ] : FixedArray[Float]),
  }
}

///|
/// Implements `matrix44f_from_global_transform_gpu_bytes`.
pub fn matrix44f_from_global_transform_gpu_bytes(
  bytes : FixedArray[Byte],
  format : GlobalTransformGpuFormat,
) -> @m44.Matrix44F {
  match format {
    Affine3x4F32 => matrix44f_from_affine3x4_gpu_bytes(bytes)
    Affine3x4F16 => matrix44f_from_affine3x4_f16_gpu_bytes(bytes)
  }
}

///|
/// Compatibility alias for older call sites. The backing row is now affine 3x4.
pub fn matrix44f_from_std140_gpu_bytes(
  bytes : FixedArray[Byte],
) -> @m44.Matrix44F {
  if bytes.length() == 64 {
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
  } else {
    matrix44f_from_affine3x4_gpu_bytes(bytes)
  }
}

///|
/// Writes column-major [`@m44.Matrix44F`] into one affine 3x4 GPU row.
#cfg(target="js")
extern "js" fn write_affine3x4_to_gpu_row_js(
  data : FixedArray[Float],
  buf : MutArrayView[Byte],
) -> Unit =
  #| (data, buf) => {
  #|   const bytes = buf.buf;
  #|   let o = buf.start;
  #|   const scratch = globalThis.__rhodonite_f32_scratch ||
  #|     (globalThis.__rhodonite_f32_scratch = {
  #|       u32: new Uint32Array(1),
  #|       f32: null,
  #|     });
  #|   if (!scratch.f32) scratch.f32 = new Float32Array(scratch.u32.buffer);
  #|   const indices = [0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14];
  #|   for (let i = 0; i < 12; i++) {
  #|     scratch.f32[0] = Math.fround(data[indices[i]]);
  #|     const u = scratch.u32[0];
  #|     bytes[o] = u & 0xff;
  #|     bytes[o + 1] = (u >>> 8) & 0xff;
  #|     bytes[o + 2] = (u >>> 16) & 0xff;
  #|     bytes[o + 3] = (u >>> 24) & 0xff;
  #|     o += 4;
  #|   }
  #| }

///|
/// Writes column-major [`@m44.Matrix44F`] into one affine 3x4 GPU row.

///|
/// Implements `matrix44f_write_affine3x4_to_gpu_row`.
#cfg(target="js")
pub fn matrix44f_write_affine3x4_to_gpu_row(
  m : @m44.Matrix44F,
  buf : MutArrayView[Byte],
) -> Unit {
  // Hot path: fixed affine row (must match global_transform_gpu_layout).
  if buf.length() != 48 {
    abort("matrix44f_write_affine3x4_to_gpu_row: length mismatch")
  }
  write_affine3x4_to_gpu_row_js(m.data, buf)
}

///|
/// Writes an identity matrix into one affine 3x4 GlobalTransform row.
pub fn global_transform_write_identity_row(buf : MutArrayView[Byte]) -> Unit {
  if buf.length() != 48 {
    abort("global_transform_write_identity_row: length mismatch")
  }
  put_gpu_f32_mut_view(buf, 0, 1.0)
  put_gpu_f32_mut_view(buf, 4, 0.0)
  put_gpu_f32_mut_view(buf, 8, 0.0)
  put_gpu_f32_mut_view(buf, 12, 0.0)
  put_gpu_f32_mut_view(buf, 16, 0.0)
  put_gpu_f32_mut_view(buf, 20, 1.0)
  put_gpu_f32_mut_view(buf, 24, 0.0)
  put_gpu_f32_mut_view(buf, 28, 0.0)
  put_gpu_f32_mut_view(buf, 32, 0.0)
  put_gpu_f32_mut_view(buf, 36, 0.0)
  put_gpu_f32_mut_view(buf, 40, 1.0)
  put_gpu_f32_mut_view(buf, 44, 0.0)
}

///|
/// Writes an identity matrix into one fp16 affine 3x4 GlobalTransform row.
pub fn global_transform_write_identity_row_f16(
  buf : MutArrayView[Byte],
) -> Unit {
  if buf.length() != 24 {
    abort("global_transform_write_identity_row_f16: length mismatch")
  }
  put_gpu_u16_mut_view(buf, 0, global_transform_f32_to_f16_bits(1.0))
  put_gpu_u16_mut_view(buf, 2, global_transform_f32_to_f16_bits(0.0))
  put_gpu_u16_mut_view(buf, 4, global_transform_f32_to_f16_bits(0.0))
  put_gpu_u16_mut_view(buf, 6, global_transform_f32_to_f16_bits(0.0))
  put_gpu_u16_mut_view(buf, 8, global_transform_f32_to_f16_bits(0.0))
  put_gpu_u16_mut_view(buf, 10, global_transform_f32_to_f16_bits(1.0))
  put_gpu_u16_mut_view(buf, 12, global_transform_f32_to_f16_bits(0.0))
  put_gpu_u16_mut_view(buf, 14, global_transform_f32_to_f16_bits(0.0))
  put_gpu_u16_mut_view(buf, 16, global_transform_f32_to_f16_bits(0.0))
  put_gpu_u16_mut_view(buf, 18, global_transform_f32_to_f16_bits(0.0))
  put_gpu_u16_mut_view(buf, 20, global_transform_f32_to_f16_bits(1.0))
  put_gpu_u16_mut_view(buf, 22, global_transform_f32_to_f16_bits(0.0))
}

///|
/// Implements `global_transform_write_identity_row_format`.
pub fn global_transform_write_identity_row_format(
  buf : MutArrayView[Byte],
  format : GlobalTransformGpuFormat,
) -> Unit {
  match format {
    Affine3x4F32 => global_transform_write_identity_row(buf)
    Affine3x4F16 => global_transform_write_identity_row_f16(buf)
  }
}

///|
/// Writes column-major [`@m44.Matrix44F`] into one affine 3x4 GPU row.

///|
/// Implements `matrix44f_write_affine3x4_to_gpu_row`.
#cfg(not(target="js"))
pub fn matrix44f_write_affine3x4_to_gpu_row(
  m : @m44.Matrix44F,
  buf : MutArrayView[Byte],
) -> Unit {
  // Hot path: fixed affine row (must match global_transform_gpu_layout).
  if buf.length() != 48 {
    abort("matrix44f_write_affine3x4_to_gpu_row: length mismatch")
  }
  let base = 0
  let d = m.data
  @writes.put_u32_le_mut_view(buf, base + 0, d[0].reinterpret_as_uint())
  @writes.put_u32_le_mut_view(buf, base + 4, d[4].reinterpret_as_uint())
  @writes.put_u32_le_mut_view(buf, base + 8, d[8].reinterpret_as_uint())
  @writes.put_u32_le_mut_view(buf, base + 12, d[12].reinterpret_as_uint())
  @writes.put_u32_le_mut_view(buf, base + 16, d[1].reinterpret_as_uint())
  @writes.put_u32_le_mut_view(buf, base + 20, d[5].reinterpret_as_uint())
  @writes.put_u32_le_mut_view(buf, base + 24, d[9].reinterpret_as_uint())
  @writes.put_u32_le_mut_view(buf, base + 28, d[13].reinterpret_as_uint())
  @writes.put_u32_le_mut_view(buf, base + 32, d[2].reinterpret_as_uint())
  @writes.put_u32_le_mut_view(buf, base + 36, d[6].reinterpret_as_uint())
  @writes.put_u32_le_mut_view(buf, base + 40, d[10].reinterpret_as_uint())
  @writes.put_u32_le_mut_view(buf, base + 44, d[14].reinterpret_as_uint())
}

///|
/// Writes column-major [`@m44.Matrix44F`] into one affine 3x4 fp16 GPU row.
pub fn matrix44f_write_affine3x4_f16_to_gpu_row(
  m : @m44.Matrix44F,
  buf : MutArrayView[Byte],
) -> Unit {
  if buf.length() != 24 {
    abort("matrix44f_write_affine3x4_f16_to_gpu_row: length mismatch")
  }
  let d = m.data
  put_gpu_u16_mut_view(buf, 0, global_transform_f32_to_f16_bits(d[0]))
  put_gpu_u16_mut_view(buf, 2, global_transform_f32_to_f16_bits(d[4]))
  put_gpu_u16_mut_view(buf, 4, global_transform_f32_to_f16_bits(d[8]))
  put_gpu_u16_mut_view(buf, 6, global_transform_f32_to_f16_bits(d[12]))
  put_gpu_u16_mut_view(buf, 8, global_transform_f32_to_f16_bits(d[1]))
  put_gpu_u16_mut_view(buf, 10, global_transform_f32_to_f16_bits(d[5]))
  put_gpu_u16_mut_view(buf, 12, global_transform_f32_to_f16_bits(d[9]))
  put_gpu_u16_mut_view(buf, 14, global_transform_f32_to_f16_bits(d[13]))
  put_gpu_u16_mut_view(buf, 16, global_transform_f32_to_f16_bits(d[2]))
  put_gpu_u16_mut_view(buf, 18, global_transform_f32_to_f16_bits(d[6]))
  put_gpu_u16_mut_view(buf, 20, global_transform_f32_to_f16_bits(d[10]))
  put_gpu_u16_mut_view(buf, 22, global_transform_f32_to_f16_bits(d[14]))
}

///|
/// Implements `matrix44f_write_global_transform_to_gpu_row`.
pub fn matrix44f_write_global_transform_to_gpu_row(
  m : @m44.Matrix44F,
  buf : MutArrayView[Byte],
  format : GlobalTransformGpuFormat,
) -> Unit {
  match format {
    Affine3x4F32 => matrix44f_write_affine3x4_to_gpu_row(m, buf)
    Affine3x4F16 => matrix44f_write_affine3x4_f16_to_gpu_row(m, buf)
  }
}

///|
/// Implements `put_packed_f16x2_mut_view`.
fn put_packed_f16x2_mut_view(
  buf : MutArrayView[Byte],
  byte_offset : Int,
  x : Float,
  y : Float,
) -> Unit {
  let packed = global_transform_f32_to_f16_bits(x) |
    (global_transform_f32_to_f16_bits(y) << 16)
  @writes.put_u32_le_mut_view(buf, byte_offset, packed)
}

///|
/// Implements `get_packed_f16x2_low`.
fn get_packed_f16x2_low(bits : UInt) -> Float {
  f16_bits_to_f32(bits & 0xFFFFU)
}

///|
/// Implements `get_packed_f16x2_high`.
fn get_packed_f16x2_high(bits : UInt) -> Float {
  f16_bits_to_f32((bits >> 16) & 0xFFFFU)
}

///|
/// Writes column-major [`@m44.Matrix44F`] into the packed u32 GlobalTransform blob.
pub fn matrix44f_write_global_transform_to_word_blob(
  m : @m44.Matrix44F,
  blob : MutArrayView[Byte],
  word_offset : Int,
  format : GlobalTransformGpuFormat,
) -> Unit {
  let words = global_transform_word_count(format)
  let byte_offset = word_offset * 4
  if word_offset < 0 || byte_offset + words * 4 > blob.length() {
    abort("matrix44f_write_global_transform_to_word_blob: range mismatch")
  }
  let d = m.data
  match format {
    Affine3x4F32 => {
      @writes.put_u32_le_mut_view(
        blob,
        byte_offset + 0,
        d[0].reinterpret_as_uint(),
      )
      @writes.put_u32_le_mut_view(
        blob,
        byte_offset + 4,
        d[4].reinterpret_as_uint(),
      )
      @writes.put_u32_le_mut_view(
        blob,
        byte_offset + 8,
        d[8].reinterpret_as_uint(),
      )
      @writes.put_u32_le_mut_view(
        blob,
        byte_offset + 12,
        d[12].reinterpret_as_uint(),
      )
      @writes.put_u32_le_mut_view(
        blob,
        byte_offset + 16,
        d[1].reinterpret_as_uint(),
      )
      @writes.put_u32_le_mut_view(
        blob,
        byte_offset + 20,
        d[5].reinterpret_as_uint(),
      )
      @writes.put_u32_le_mut_view(
        blob,
        byte_offset + 24,
        d[9].reinterpret_as_uint(),
      )
      @writes.put_u32_le_mut_view(
        blob,
        byte_offset + 28,
        d[13].reinterpret_as_uint(),
      )
      @writes.put_u32_le_mut_view(
        blob,
        byte_offset + 32,
        d[2].reinterpret_as_uint(),
      )
      @writes.put_u32_le_mut_view(
        blob,
        byte_offset + 36,
        d[6].reinterpret_as_uint(),
      )
      @writes.put_u32_le_mut_view(
        blob,
        byte_offset + 40,
        d[10].reinterpret_as_uint(),
      )
      @writes.put_u32_le_mut_view(
        blob,
        byte_offset + 44,
        d[14].reinterpret_as_uint(),
      )
    }
    Affine3x4F16 => {
      put_packed_f16x2_mut_view(blob, byte_offset + 0, d[0], d[4])
      put_packed_f16x2_mut_view(blob, byte_offset + 4, d[8], d[12])
      put_packed_f16x2_mut_view(blob, byte_offset + 8, d[1], d[5])
      put_packed_f16x2_mut_view(blob, byte_offset + 12, d[9], d[13])
      put_packed_f16x2_mut_view(blob, byte_offset + 16, d[2], d[6])
      put_packed_f16x2_mut_view(blob, byte_offset + 20, d[10], d[14])
    }
  }
}

///|
/// Decodes one matrix from the packed u32 GlobalTransform blob.
pub fn matrix44f_from_global_transform_word_blob(
  blob : FixedArray[Byte],
  word_offset : Int,
  format : GlobalTransformGpuFormat,
) -> @m44.Matrix44F {
  let words = global_transform_word_count(format)
  let byte_offset = word_offset * 4
  if word_offset < 0 || byte_offset + words * 4 > blob.length() {
    abort("matrix44f_from_global_transform_word_blob: range mismatch")
  }
  match format {
    Affine3x4F32 =>
      @m44.Matrix44F::{
        data: (
          [
            Float::reinterpret_from_uint(
              @writes.get_u32_le(blob, byte_offset + 0),
            ),
            Float::reinterpret_from_uint(
              @writes.get_u32_le(blob, byte_offset + 16),
            ),
            Float::reinterpret_from_uint(
              @writes.get_u32_le(blob, byte_offset + 32),
            ),
            (0.0 : Float),
            Float::reinterpret_from_uint(
              @writes.get_u32_le(blob, byte_offset + 4),
            ),
            Float::reinterpret_from_uint(
              @writes.get_u32_le(blob, byte_offset + 20),
            ),
            Float::reinterpret_from_uint(
              @writes.get_u32_le(blob, byte_offset + 36),
            ),
            (0.0 : Float),
            Float::reinterpret_from_uint(
              @writes.get_u32_le(blob, byte_offset + 8),
            ),
            Float::reinterpret_from_uint(
              @writes.get_u32_le(blob, byte_offset + 24),
            ),
            Float::reinterpret_from_uint(
              @writes.get_u32_le(blob, byte_offset + 40),
            ),
            (0.0 : Float),
            Float::reinterpret_from_uint(
              @writes.get_u32_le(blob, byte_offset + 12),
            ),
            Float::reinterpret_from_uint(
              @writes.get_u32_le(blob, byte_offset + 28),
            ),
            Float::reinterpret_from_uint(
              @writes.get_u32_le(blob, byte_offset + 44),
            ),
            (1.0 : Float),
          ] : FixedArray[Float]),
      }
    Affine3x4F16 => {
      let w0 = @writes.get_u32_le(blob, byte_offset + 0)
      let w1 = @writes.get_u32_le(blob, byte_offset + 4)
      let w2 = @writes.get_u32_le(blob, byte_offset + 8)
      let w3 = @writes.get_u32_le(blob, byte_offset + 12)
      let w4 = @writes.get_u32_le(blob, byte_offset + 16)
      let w5 = @writes.get_u32_le(blob, byte_offset + 20)
      @m44.Matrix44F::{
        data: (
          [
            get_packed_f16x2_low(w0),
            get_packed_f16x2_low(w2),
            get_packed_f16x2_low(w4),
            (0.0 : Float),
            get_packed_f16x2_high(w0),
            get_packed_f16x2_high(w2),
            get_packed_f16x2_high(w4),
            (0.0 : Float),
            get_packed_f16x2_low(w1),
            get_packed_f16x2_low(w3),
            get_packed_f16x2_low(w5),
            (0.0 : Float),
            get_packed_f16x2_high(w1),
            get_packed_f16x2_high(w3),
            get_packed_f16x2_high(w5),
            (1.0 : Float),
          ] : FixedArray[Float]),
      }
    }
  }
}

///|
/// Compatibility alias for older call sites. The backing row is now affine 3x4.
pub fn matrix44f_write_std140_mat4_to_gpu_row(
  m : @m44.Matrix44F,
  buf : MutArrayView[Byte],
) -> Unit {
  if buf.length() == 64 {
    let d = m.data
    for i = 0; i < 16; i = i + 1 {
      @writes.put_u32_le_mut_view(buf, i * 4, d[i].reinterpret_as_uint())
    }
  } else {
    matrix44f_write_affine3x4_to_gpu_row(m, buf)
  }
}
