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
    Vec3F32Packed => 12
    Vec3F32 => 16
    Vec4F32 => 16
    Vec4F16 => 8
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
    Vec3F32Packed => 4
    Vec3F32 => 16
    Vec4F32 => 16
    Vec4F16 => 8
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
/// Builds a storage-buffer layout using each field's WGSL host-shareable size/alignment.
pub fn GpuLayout::storage(fields : Array[(String, GpuFieldKind)]) -> GpuLayout {
  let out : Array[GpuField] = []
  let mut offset = 0
  let mut max_align = 4
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
  { fields: out, stride: align_up(offset, max_align), align: max_align }
}

///|
/// Untyped blob layout: no logical fields, only a padded stride (e.g. opaque packed structs written elsewhere).
pub fn GpuLayout::empty(stride : Int) -> GpuLayout {
  let fields : Array[GpuField] = []
  { fields, stride: align_up(stride, 16), align: 16 }
}

///|
/// Validates a host-shareable storage layout and that each field lies inside `[0, stride)` with correct alignment.
pub fn GpuLayout::is_valid(self : GpuLayout) -> Bool {
  if self.stride <= 0 ||
    self.align <= 0 ||
    self.stride % self.align != 0 ||
    self.stride % 4 != 0 {
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
/// Same as [`put_gpu_f32`] but writes into a [`MutArrayView`] for packed GPU rows.
pub fn put_gpu_f32_mut_view(
  buf : MutArrayView[Byte],
  offset : Int,
  value : Double,
) -> Unit {
  @writes.put_f32_le_mut_view(buf, offset, value)
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
#cfg(target="js")
extern "js" fn get_f32_from_byte_view_js(
  buf : ArrayView[Byte],
  offset : Int,
) -> Float =
  #| (buf, offset) => {
  #|   const bytes = buf.buf;
  #|   const byteIndex = buf.start + offset;
  #|   if (ArrayBuffer.isView(bytes) && bytes.buffer instanceof ArrayBuffer) {
  #|     if (((bytes.byteOffset | bytes.byteLength | byteIndex) & 3) === 0) {
  #|       let f32 = bytes.__rhodonite_f32_view;
  #|       if (!f32 || f32.buffer !== bytes.buffer || f32.byteOffset !== bytes.byteOffset) {
  #|         f32 = new Float32Array(bytes.buffer, bytes.byteOffset, bytes.byteLength >> 2);
  #|         bytes.__rhodonite_f32_view = f32;
  #|       }
  #|       return f32[byteIndex >> 2];
  #|     }
  #|     return new DataView(bytes.buffer, bytes.byteOffset + byteIndex, 4).getFloat32(0, true);
  #|   }
  #|   const bits =
  #|     (bytes[byteIndex] & 0xff) |
  #|     ((bytes[byteIndex + 1] & 0xff) << 8) |
  #|     ((bytes[byteIndex + 2] & 0xff) << 16) |
  #|     ((bytes[byteIndex + 3] & 0xff) << 24);
  #|   const scratch = globalThis.__rhodonite_f32_scratch ||
  #|     (globalThis.__rhodonite_f32_scratch = {
  #|       u32: new Uint32Array(1),
  #|       f32: null,
  #|     });
  #|   if (!scratch.f32) scratch.f32 = new Float32Array(scratch.u32.buffer);
  #|   scratch.u32[0] = bits >>> 0;
  #|   return scratch.f32[0];
  #| }

///|
#cfg(target="js")
extern "js" fn get_f32_from_mut_view_js(
  buf : MutArrayView[Byte],
  offset : Int,
) -> Float =
  #| (buf, offset) => {
  #|   const bytes = buf.buf;
  #|   const byteIndex = buf.start + offset;
  #|   if (ArrayBuffer.isView(bytes) && bytes.buffer instanceof ArrayBuffer) {
  #|     if (((bytes.byteOffset | bytes.byteLength | byteIndex) & 3) === 0) {
  #|       let f32 = bytes.__rhodonite_f32_view;
  #|       if (!f32 || f32.buffer !== bytes.buffer || f32.byteOffset !== bytes.byteOffset) {
  #|         f32 = new Float32Array(bytes.buffer, bytes.byteOffset, bytes.byteLength >> 2);
  #|         bytes.__rhodonite_f32_view = f32;
  #|       }
  #|       return f32[byteIndex >> 2];
  #|     }
  #|     return new DataView(bytes.buffer, bytes.byteOffset + byteIndex, 4).getFloat32(0, true);
  #|   }
  #|   const bits =
  #|     (bytes[byteIndex] & 0xff) |
  #|     ((bytes[byteIndex + 1] & 0xff) << 8) |
  #|     ((bytes[byteIndex + 2] & 0xff) << 16) |
  #|     ((bytes[byteIndex + 3] & 0xff) << 24);
  #|   const scratch = globalThis.__rhodonite_f32_scratch ||
  #|     (globalThis.__rhodonite_f32_scratch = {
  #|       u32: new Uint32Array(1),
  #|       f32: null,
  #|     });
  #|   if (!scratch.f32) scratch.f32 = new Float32Array(scratch.u32.buffer);
  #|   scratch.u32[0] = bits >>> 0;
  #|   return scratch.f32[0];
  #| }

///|
/// Same as [`get_gpu_f32`] but reads through a zero-copy [`ArrayView`] (MoonBit `array[start:end]` view).

///|
/// Implements `get_gpu_f32_byte_view`.
#cfg(target="js")
pub fn get_gpu_f32_byte_view(buf : ArrayView[Byte], offset : Int) -> Float {
  get_f32_from_byte_view_js(buf, offset)
}

///|
/// Same as [`get_gpu_f32`] but reads through a zero-copy [`ArrayView`] (MoonBit `array[start:end]` view).

///|
/// Implements `get_gpu_f32_byte_view`.
#cfg(not(target="js"))
pub fn get_gpu_f32_byte_view(buf : ArrayView[Byte], offset : Int) -> Float {
  Float::reinterpret_from_uint(@writes.get_u32_le_byte_view(buf, offset))
}

///|
/// Same as [`get_gpu_f32`] but reads through a [`MutArrayView`] (e.g. SoA row slice).

///|
/// Implements `get_gpu_f32_mut_view`.
#cfg(target="js")
pub fn get_gpu_f32_mut_view(buf : MutArrayView[Byte], offset : Int) -> Float {
  get_f32_from_mut_view_js(buf, offset)
}

///|
/// Same as [`get_gpu_f32`] but reads through a [`MutArrayView`] (e.g. SoA row slice).

///|
/// Implements `get_gpu_f32_mut_view`.
#cfg(not(target="js"))
pub fn get_gpu_f32_mut_view(buf : MutArrayView[Byte], offset : Int) -> Float {
  Float::reinterpret_from_uint(@writes.get_u32_le_mut_view(buf, offset))
}
