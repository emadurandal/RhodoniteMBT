///|
/// World-space affine matrix for rendering; stored in flat [`GpuComponentStore`] as three
/// row-major `vec4<f32>` rows. The implicit bottom row is `[0, 0, 0, 1]`.

///|
/// ECS bulk paths use [`GlobalTransform::view_affine3x4_gpu_row`] so [`matrix`] aliases the GPU row
/// returned by raw or bulk write paths with **no** separate float storage.
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
/// Mutable typed view over one flat GPU GlobalTransform row.
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
pub fn GlobalTransformGpuMutRow::from_gpu_row(
  row : MutArrayView[Byte],
) -> GlobalTransformGpuMutRow {
  if row.length() != 48 {
    abort("GlobalTransformGpuMutRow::from_gpu_row: length mismatch")
  }
  { view: row, format: Affine3x4F32 }
}

///|
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
pub fn GlobalTransformGpuMutRow::write_matrix(
  self : GlobalTransformGpuMutRow,
  m : @m44.Matrix44F,
) -> Unit {
  matrix44f_write_global_transform_to_gpu_row(m, self.view, self.format)
}

///|
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
fn get_gpu_u16(buf : FixedArray[Byte], offset : Int) -> UInt {
  buf[offset].to_uint() | (buf[offset + 1].to_uint() << 8)
}

///|
fn put_gpu_u16_mut_view(
  buf : MutArrayView[Byte],
  offset : Int,
  value : UInt,
) -> Unit {
  buf[offset] = (value & 0xFFU).to_byte()
  buf[offset + 1] = ((value >> 8) & 0xFFU).to_byte()
}

///|
fn f32_to_f16_bits(value : Float) -> UInt {
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
  put_gpu_u16_mut_view(buf, 0, f32_to_f16_bits(1.0))
  put_gpu_u16_mut_view(buf, 2, f32_to_f16_bits(0.0))
  put_gpu_u16_mut_view(buf, 4, f32_to_f16_bits(0.0))
  put_gpu_u16_mut_view(buf, 6, f32_to_f16_bits(0.0))
  put_gpu_u16_mut_view(buf, 8, f32_to_f16_bits(0.0))
  put_gpu_u16_mut_view(buf, 10, f32_to_f16_bits(1.0))
  put_gpu_u16_mut_view(buf, 12, f32_to_f16_bits(0.0))
  put_gpu_u16_mut_view(buf, 14, f32_to_f16_bits(0.0))
  put_gpu_u16_mut_view(buf, 16, f32_to_f16_bits(0.0))
  put_gpu_u16_mut_view(buf, 18, f32_to_f16_bits(0.0))
  put_gpu_u16_mut_view(buf, 20, f32_to_f16_bits(1.0))
  put_gpu_u16_mut_view(buf, 22, f32_to_f16_bits(0.0))
}

///|
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
  put_gpu_u16_mut_view(buf, 0, f32_to_f16_bits(d[0]))
  put_gpu_u16_mut_view(buf, 2, f32_to_f16_bits(d[4]))
  put_gpu_u16_mut_view(buf, 4, f32_to_f16_bits(d[8]))
  put_gpu_u16_mut_view(buf, 6, f32_to_f16_bits(d[12]))
  put_gpu_u16_mut_view(buf, 8, f32_to_f16_bits(d[1]))
  put_gpu_u16_mut_view(buf, 10, f32_to_f16_bits(d[5]))
  put_gpu_u16_mut_view(buf, 12, f32_to_f16_bits(d[9]))
  put_gpu_u16_mut_view(buf, 14, f32_to_f16_bits(d[13]))
  put_gpu_u16_mut_view(buf, 16, f32_to_f16_bits(d[2]))
  put_gpu_u16_mut_view(buf, 18, f32_to_f16_bits(d[6]))
  put_gpu_u16_mut_view(buf, 20, f32_to_f16_bits(d[10]))
  put_gpu_u16_mut_view(buf, 22, f32_to_f16_bits(d[14]))
}

///|
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
