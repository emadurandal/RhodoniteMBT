///|
pub(all) struct EntityId {
  index : Int
  generation : Int
} derive(Eq)

///|
pub fn EntityId::new(index : Int, generation : Int) -> EntityId {
  { index, generation }
}

///|
pub fn EntityId::gpu_index(self : EntityId) -> Int {
  self.index
}

///|
pub(all) struct ComponentTypeId {
  index : Int
} derive(Eq)

///|
pub fn ComponentTypeId::new(index : Int) -> ComponentTypeId {
  { index, }
}

///|
pub(all) enum ComponentKind {
  CpuOnly
  GpuVisible
} derive(Eq)

///|
pub(all) enum GpuFieldKind {
  F32
  U32
  Vec2F32
  Vec3F32
  Vec4F32
  Mat4x4F32
} derive(Eq)

///|
pub(all) struct GpuField {
  name : String
  kind : GpuFieldKind
  offset : Int
  size : Int
  align : Int
}

///|
pub(all) struct GpuLayout {
  fields : Array[GpuField]
  stride : Int
  align : Int
}

///|
pub(all) struct RegisteredComponent {
  id : ComponentTypeId
  name : String
  kind : ComponentKind
  cpu_stride : Int
  gpu_layout : GpuLayout?
}

///|
pub struct ComponentRegistry {
  components : Array[RegisteredComponent]
}

///|
pub(all) struct EntityLocation {
  archetype_index : Int
  row : Int
}

///|
priv struct ComponentColumn {
  component : ComponentTypeId
  stride : Int
  bytes : Array[Byte]
}

///|
struct Archetype {
  components : Array[ComponentTypeId]
  entities : Array[EntityId]
  columns : Array[ComponentColumn]
}

///|
struct GpuComponentStore {
  component : ComponentTypeId
  stride : Int
  bytes : Array[Byte]
  dirty_flags : Array[Bool]
  dirty_indices : Array[Int]
}

///|
pub(all) struct GpuWrite {
  byte_offset : Int
  bytes : FixedArray[Byte]
}

///|
pub(all) struct GpuResizeEvent {
  component : ComponentTypeId
  required_capacity : Int
  needs_full_upload : Bool
}

///|
pub struct World {
  registry : ComponentRegistry
  generations : Array[Int]
  alive : Array[Bool]
  free_indices : Array[Int]
  locations : Array[EntityLocation?]
  archetypes : Array[Archetype]
  gpu_stores : Array[GpuComponentStore?]
  resize_events : Array[GpuResizeEvent]
}
