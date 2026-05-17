///|
/// Implements `copy_fixed_into_fixed`.
fn copy_fixed_into_fixed(
  dst : FixedArray[Byte],
  offset : Int,
  src : FixedArray[Byte],
) -> Unit {
  for i = 0; i < src.length(); i = i + 1 {
    dst[offset + i] = src[i]
  }
}

///|
/// Implements `copy_fixed_range_to_fixed_array`.
fn copy_fixed_range_to_fixed_array(
  src : FixedArray[Byte],
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
/// Implements `copy_fixed_range_to_fixed`.
fn copy_fixed_range_to_fixed(
  src : FixedArray[Byte],
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
/// Implements `ComponentColumn::ensure_row_capacity`.
fn ComponentColumn::ensure_row_capacity(
  self : ComponentColumn,
  required_rows : Int,
) -> Unit {
  if required_rows <= self.row_capacity {
    return
  }
  let mut next = if self.row_capacity > 0 { self.row_capacity * 2 } else { 1 }
  while next < required_rows {
    next = next * 2
  }
  let next_bytes = FixedArray::make(next * self.stride, (0 : Byte))
  for i = 0; i < self.row_capacity * self.stride; i = i + 1 {
    next_bytes[i] = self.bytes[i]
  }
  self.bytes = next_bytes
  self.row_capacity = next
}

///|
/// Implements `ComponentColumn::clear_row`.
fn ComponentColumn::clear_row(self : ComponentColumn, row : Int) -> Unit {
  let base = row * self.stride
  for b = 0; b < self.stride; b = b + 1 {
    self.bytes[base + b] = (0 : Byte)
  }
}

///|
/// Implements `Archetype::ensure_row_capacity`.
fn Archetype::ensure_row_capacity(
  self : Archetype,
  required_rows : Int,
) -> Unit {
  for i = 0; i < self.columns.length(); i = i + 1 {
    self.columns[i].ensure_row_capacity(required_rows)
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
    let bytes = FixedArray::make(0, (0 : Byte))
    columns.push({
      component: components[i],
      stride: registry.stride(components[i]),
      bytes,
      row_capacity: 0,
    })
  }
  let entities : Array[EntityId] = []
  { components, entities, columns }
}

///|
/// Implements `Archetype::column_index`.
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
    self.columns[i].ensure_row_capacity(row + 1)
    self.columns[i].clear_row(row)
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
/// Implements `Archetype::set_component_bytes`.
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
  copy_fixed_into_fixed(col.bytes, row * col.stride, bytes)
}

///|
/// Implements `Archetype::component_bytes`.
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
    Some(
      copy_fixed_range_to_fixed_array(col.bytes, row * col.stride, col.stride),
    )
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
  moved
}
