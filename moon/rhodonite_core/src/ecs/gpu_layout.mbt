///|
fn align_up(value : Int, align : Int) -> Int {
  let r = value % align
  if r == 0 {
    value
  } else {
    value + align - r
  }
}

///|
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
pub fn GpuLayout::empty(stride : Int) -> GpuLayout {
  let fields : Array[GpuField] = []
  { fields, stride: align_up(stride, 16), align: 16 }
}

///|
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
pub fn gpu_component_bytes(stride : Int) -> FixedArray[Byte] {
  FixedArray::make(align_up(stride, 16), (0 : Byte))
}

///|
pub fn put_gpu_f32(
  buf : FixedArray[Byte],
  offset : Int,
  value : Double,
) -> Unit {
  @writes.put_f32_le(buf, offset, value)
}

///|
pub fn put_gpu_u32(buf : FixedArray[Byte], offset : Int, value : UInt) -> Unit {
  @writes.put_u32_le(buf, offset, value)
}
