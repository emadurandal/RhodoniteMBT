///|
/// CPU-only parent link: stores the parent's dense slot index and generation (same logical fields as [`EntityId`] in `ecs`).

///|
/// Defines `ChildOf`.
pub(all) struct ChildOf {
  parent_index : Int
  parent_generation : Int
}

///|
/// Read-only typed view over one ChildOf component row.
pub struct ChildOfRow {
  priv view : ArrayView[Byte]
}

///|
/// Mutable typed view over one ChildOf component row.
pub struct ChildOfMutRow {
  priv view : MutArrayView[Byte]
}

///|
/// Implements `ChildOf::new`.
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
/// Implements `ChildOf::to_component_bytes`.
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
/// Implements `ChildOf::from_component_bytes`.
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

///|
/// Implements `ChildOf::from_component_view`.
pub fn ChildOf::from_component_view(bytes : ArrayView[Byte]) -> ChildOf {
  let layout = child_of_cpu_layout()
  if bytes.length() != layout.stride {
    abort("ChildOf::from_component_view: length mismatch")
  }
  if layout.fields.length() != 2 {
    abort("child_of_cpu_layout: expected 2 fields")
  }
  let idx = @writes.get_u32_le_byte_view(bytes, layout.fields[0].offset).reinterpret_as_int()
  let gen = @writes.get_u32_le_byte_view(bytes, layout.fields[1].offset).reinterpret_as_int()
  { parent_index: idx, parent_generation: gen }
}

///|
/// Implements `ChildOfRow::from_component_view`.
pub fn ChildOfRow::from_component_view(row : ArrayView[Byte]) -> ChildOfRow {
  let layout = child_of_cpu_layout()
  if row.length() != layout.stride {
    abort("ChildOfRow::from_component_view: length mismatch")
  }
  { view: row }
}

///|
/// Implements `ChildOfMutRow::from_component_mut_view`.
pub fn ChildOfMutRow::from_component_mut_view(
  row : MutArrayView[Byte],
) -> ChildOfMutRow {
  let layout = child_of_cpu_layout()
  if row.length() != layout.stride {
    abort("ChildOfMutRow::from_component_mut_view: length mismatch")
  }
  { view: row }
}

///|
/// Implements `ChildOfRow::to_child_of`.
pub fn ChildOfRow::to_child_of(self : ChildOfRow) -> ChildOf {
  ChildOf::from_component_view(self.view)
}

///|
/// Implements `ChildOfRow::parent_index`.
pub fn ChildOfRow::parent_index(self : ChildOfRow) -> Int {
  self.to_child_of().parent_index
}

///|
/// Implements `ChildOfRow::parent_generation`.
pub fn ChildOfRow::parent_generation(self : ChildOfRow) -> Int {
  self.to_child_of().parent_generation
}

///|
/// Implements `ChildOfMutRow::write_parent`.
pub fn ChildOfMutRow::write_parent(
  self : ChildOfMutRow,
  parent_index : Int,
  parent_generation : Int,
) -> Unit {
  let layout = child_of_cpu_layout()
  if layout.fields.length() != 2 {
    abort("child_of_cpu_layout: expected 2 fields")
  }
  @writes.put_u32_le_mut_view(
    self.view,
    layout.fields[0].offset,
    parent_index.reinterpret_as_uint(),
  )
  @writes.put_u32_le_mut_view(
    self.view,
    layout.fields[1].offset,
    parent_generation.reinterpret_as_uint(),
  )
}
