///|
/// Rounds `value` up to the next multiple of `align` (used for WGSL struct stride alignment).
fn align_up(value : Int, align : Int) -> Int {
  let r = value % align
  if r == 0 {
    value
  } else {
    value + align - r
  }
}

///|
/// Wire size in bytes for std140-style packing (Vec3 occupies 16 bytes including padding).
pub fn GpuFieldKind::size(self : GpuFieldKind) -> Int {
  match self {
    F32 => 4
    U32 => 4
    Vec2F32 => 8
    Vec3F32 => 16
    Vec4F32 => 16
    Mat4x4F32 => 64
  }
}

///|
/// Base alignment for placing this kind at its starting offset.
pub fn GpuFieldKind::align(self : GpuFieldKind) -> Int {
  match self {
    F32 => 4
    U32 => 4
    Vec2F32 => 8
    Vec3F32 => 16
    Vec4F32 => 16
    Mat4x4F32 => 16
  }
}

///|
/// Builds a scalar/vector layout matching OpenGL std140 rules (including vec3 -> 16-byte column slots).
pub fn GpuLayout::std140(fields : Array[(String, GpuFieldKind)]) -> GpuLayout {
  let out : Array[GpuField] = []
  let mut offset = 0
  let mut max_align = 16
  for i = 0; i < fields.length(); i = i + 1 {
    let (name, kind) = fields[i]
    let align = kind.align()
    let size = kind.size()
    offset = align_up(offset, align)
    out.push({ name, kind, offset, size, align })
    offset = offset + size
    if align > max_align {
      max_align = align
    }
  }
  { fields: out, stride: align_up(offset, 16), align: max_align }
}

///|
/// Untyped blob layout: no logical fields, only a padded stride (e.g. opaque packed structs written elsewhere).
pub fn GpuLayout::empty(stride : Int) -> GpuLayout {
  let fields : Array[GpuField] = []
  { fields, stride: align_up(stride, 16), align: 16 }
}

///|
/// Validates stride multiple of 16 and that each field lies inside `[0, stride)` with correct alignment.
pub fn GpuLayout::is_valid(self : GpuLayout) -> Bool {
  if self.stride <= 0 || self.stride % 16 != 0 {
    return false
  }
  for i = 0; i < self.fields.length(); i = i + 1 {
    let field = self.fields[i]
    if field.offset < 0 || field.offset % field.align != 0 {
      return false
    }
    if field.offset + field.size > self.stride {
      return false
    }
  }
  true
}

///|
/// Allocates a zeroed FixedArray sized for one GPU struct row (stride padded to 16 bytes).
pub fn gpu_component_bytes(stride : Int) -> FixedArray[Byte] {
  FixedArray::make(align_up(stride, 16), (0 : Byte))
}

///|
/// Writes little-endian f32 at `offset` (matches WGSL `f32` storage representation).
pub fn put_gpu_f32(
  buf : FixedArray[Byte],
  offset : Int,
  value : Double,
) -> Unit {
  @writes.put_f32_le(buf, offset, value)
}

///|
/// Same as [`put_gpu_f32`] but writes into a [`MutArrayView`] (flat GPU store rows).
pub fn put_gpu_f32_mut_view(
  buf : MutArrayView[Byte],
  offset : Int,
  value : Double,
) -> Unit {
  let u = Float::from_double(value).reinterpret_as_uint()
  buf[offset] = (u & 0xFFU).to_byte()
  buf[offset + 1] = ((u >> 8) & 0xFFU).to_byte()
  buf[offset + 2] = ((u >> 16) & 0xFFU).to_byte()
  buf[offset + 3] = ((u >> 24) & 0xFFU).to_byte()
}

///|
/// Writes little-endian u32 at `offset`.
pub fn put_gpu_u32(buf : FixedArray[Byte], offset : Int, value : UInt) -> Unit {
  @writes.put_u32_le(buf, offset, value)
}

///|
/// Reads little-endian f32 at `offset` as [`Float`] (no `Double` round-trip).
pub fn get_gpu_f32(buf : FixedArray[Byte], offset : Int) -> Float {
  Float::reinterpret_from_uint(@writes.get_u32_le(buf, offset))
}

///|
/// Same as [`get_gpu_f32`] but reads through a zero-copy [`ArrayView`] (MoonBit `array[start:end]` view).
pub fn get_gpu_f32_byte_view(buf : ArrayView[Byte], offset : Int) -> Float {
  let u = buf[offset].to_uint() |
    (buf[offset + 1].to_uint() << 8) |
    (buf[offset + 2].to_uint() << 16) |
    (buf[offset + 3].to_uint() << 24)
  Float::reinterpret_from_uint(u)
}
