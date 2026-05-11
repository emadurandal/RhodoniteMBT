///|
fn copy_fixed_into_array(
  dst : Array[Byte],
  offset : Int,
  src : FixedArray[Byte],
) -> Unit {
  for i = 0; i < src.length(); i = i + 1 {
    dst[offset + i] = src[i]
  }
}

///|
fn copy_array_range_to_fixed(
  src : Array[Byte],
  offset : Int,
  len : Int,
) -> FixedArray[Byte] {
  let out = FixedArray::make(len, (0 : Byte))
  for i = 0; i < len; i = i + 1 {
    out[i] = src[offset + i]
  }
  out
}

///|
fn append_zero_bytes(dst : Array[Byte], count : Int) -> Unit {
  for i = 0; i < count; i = i + 1 {
    ignore(i)
    dst.push((0 : Byte))
  }
}

///|
/// Builds an archetype table for one sorted component signature (empty archetype uses this with zero components).
fn Archetype::new(
  components : Array[ComponentTypeId],
  registry : ComponentRegistry,
) -> Archetype {
  let columns : Array[ComponentColumn] = []
  for i = 0; i < components.length(); i = i + 1 {
    let bytes : Array[Byte] = []
    columns.push({
      component: components[i],
      stride: registry.stride(components[i]),
      bytes,
    })
  }
  let entities : Array[EntityId] = []
  { components, entities, columns }
}

///|
fn Archetype::column_index(
  self : Archetype,
  component : ComponentTypeId,
) -> Int {
  for i = 0; i < self.columns.length(); i = i + 1 {
    if self.columns[i].component == component {
      return i
    }
  }
  -1
}

///|
/// Appends a zeroed component row for every column (SoA append).
fn Archetype::push_empty_row(self : Archetype, entity : EntityId) -> Int {
  let row = self.entities.length()
  self.entities.push(entity)
  for i = 0; i < self.columns.length(); i = i + 1 {
    append_zero_bytes(self.columns[i].bytes, self.columns[i].stride)
  }
  row
}

///|
/// Copies overlapping components when moving an entity row between archetypes (new row is the pending tail row).
fn Archetype::copy_row_to(self : Archetype, row : Int, dst : Archetype) -> Unit {
  for i = 0; i < self.columns.length(); i = i + 1 {
    let col = self.columns[i]
    let dst_col_index = dst.column_index(col.component)
    if dst_col_index >= 0 {
      let dst_col = dst.columns[dst_col_index]
      let dst_offset = (dst.entities.length() - 1) * dst_col.stride
      let src_offset = row * col.stride
      for b = 0; b < col.stride; b = b + 1 {
        dst_col.bytes[dst_offset + b] = col.bytes[src_offset + b]
      }
    }
  }
}

///|
fn Archetype::set_component_bytes(
  self : Archetype,
  row : Int,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Unit {
  let col_index = self.column_index(component)
  if col_index < 0 {
    abort("component is not in archetype")
  }
  let col = self.columns[col_index]
  if bytes.length() != col.stride {
    abort("component byte length does not match component stride")
  }
  copy_fixed_into_array(col.bytes, row * col.stride, bytes)
}

///|
fn Archetype::component_bytes(
  self : Archetype,
  row : Int,
  component : ComponentTypeId,
) -> FixedArray[Byte]? {
  let col_index = self.column_index(component)
  if col_index < 0 {
    None
  } else {
    let col = self.columns[col_index]
    Some(copy_array_range_to_fixed(col.bytes, row * col.stride, col.stride))
  }
}

///|
/// Zero-copy **mutable** view of one component row ([`MutArrayView`] over [`ComponentColumn::bytes`]).
fn Archetype::component_byte_mut_view(
  self : Archetype,
  row : Int,
  component : ComponentTypeId,
) -> MutArrayView[Byte]? {
  let col_index = self.column_index(component)
  if col_index < 0 {
    None
  } else {
    let col = self.columns[col_index]
    let base = row * col.stride
    let end = base + col.stride
    Some(col.bytes.mut_view(start=base, end~))
  }
}

///|
/// Dense archetype table helpers (swap-remove keeps rows packed).
fn Archetype::swap_remove_row(self : Archetype, row : Int) -> EntityId? {
  let last = self.entities.length() - 1
  if row < 0 || row > last {
    return None
  }
  let moved = if row != last { Some(self.entities[last]) } else { None }
  if row != last {
    self.entities[row] = self.entities[last]
    for ci = 0; ci < self.columns.length(); ci = ci + 1 {
      let col = self.columns[ci]
      let dst_base = row * col.stride
      let src_base = last * col.stride
      for b = 0; b < col.stride; b = b + 1 {
        col.bytes[dst_base + b] = col.bytes[src_base + b]
      }
    }
  }
  let _ = self.entities.pop()
  for ci = 0; ci < self.columns.length(); ci = ci + 1 {
    let col = self.columns[ci]
    for b = 0; b < col.stride; b = b + 1 {
      ignore(b)
      let _ = col.bytes.pop()
    }
  }
  moved
}
