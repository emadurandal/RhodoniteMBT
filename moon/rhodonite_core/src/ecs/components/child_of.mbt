///|
/// CPU-only parent link: stores the parent's dense slot index and generation (same logical fields as [`EntityId`] in `ecs`).

///|
pub(all) struct ChildOf {
  parent_index : Int
  parent_generation : Int
}

///|
pub fn ChildOf::new(parent_index : Int, parent_generation : Int) -> ChildOf {
  { parent_index, parent_generation }
}

///|
/// std140: two `u32` fields at offsets 0 and 4; stride 16 bytes (matches archetype SoA row size for builtin CPU components).
pub fn child_of_cpu_layout() -> GpuLayout {
  let fields : Array[(String, GpuFieldKind)] = [
    ("parent_index", U32),
    ("parent_generation", U32),
  ]
  GpuLayout::std140(fields)
}

///|
pub fn ChildOf::to_component_bytes(self : ChildOf) -> FixedArray[Byte] {
  let layout = child_of_cpu_layout()
  if layout.fields.length() != 2 {
    abort("child_of_cpu_layout: expected 2 fields")
  }
  let buf = gpu_component_bytes(layout.stride)
  put_gpu_u32(
    buf,
    layout.fields[0].offset,
    self.parent_index.reinterpret_as_uint(),
  )
  put_gpu_u32(
    buf,
    layout.fields[1].offset,
    self.parent_generation.reinterpret_as_uint(),
  )
  buf
}

///|
pub fn ChildOf::from_component_bytes(bytes : FixedArray[Byte]) -> ChildOf {
  let layout = child_of_cpu_layout()
  if bytes.length() != layout.stride {
    abort("ChildOf::from_component_bytes: length mismatch")
  }
  if layout.fields.length() != 2 {
    abort("child_of_cpu_layout: expected 2 fields")
  }
  let idx = @writes.get_u32_le(bytes, layout.fields[0].offset).reinterpret_as_int()
  let gen = @writes.get_u32_le(bytes, layout.fields[1].offset).reinterpret_as_int()
  { parent_index: idx, parent_generation: gen }
}
