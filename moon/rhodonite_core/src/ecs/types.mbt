///| Stable slot index for dense arrays (GPU buffers index by `index`; shaders use it as the array subscript).

///|
/// `generation` bumps on destroy/reuse so stale `EntityId` handles are rejected.
pub(all) struct EntityId {
  index : Int
  generation : Int
} derive(Eq)

///|
pub fn EntityId::new(index : Int, generation : Int) -> EntityId {
  { index, generation }
}

///|
/// Same as `index`; WGSL can use this value to index flat storage-buffer arrays.
pub fn EntityId::gpu_index(self : EntityId) -> Int {
  self.index
}

///|
/// Opaque handle returned by `ComponentRegistry`; indexes into the world's registration tables.
pub(all) struct ComponentTypeId {
  index : Int
} derive(Eq)

///|
pub fn ComponentTypeId::new(index : Int) -> ComponentTypeId {
  { index, }
}

///|
/// CpuOnly: archetype SoA only (`cpu_stride` bytes per row).
/// GpuVisible: payload only in flat `GpuComponentStore` (`cpu_stride` is always `0` here; layout stride is `gpu_layout.stride`).
pub(all) enum ComponentKind {
  CpuOnly
  GpuVisible
} derive(Eq)

///|
/// Metadata for one registered component: `cpu_stride` is `0` for `GpuVisible` (payload lives only in `GpuComponentStore`).
pub(all) struct RegisteredComponent {
  id : ComponentTypeId
  name : String
  kind : ComponentKind
  cpu_stride : Int
  gpu_layout : @comp.GpuLayout?
}

///|
/// Issues monotonic `ComponentTypeId`s; CPU stride and optional GPU layout are fixed at registration time (no runtime reflection).
pub struct ComponentRegistry {
  components : Array[RegisteredComponent]
}

///|
/// Maps an entity to its dense row inside one archetype table (SoA columns live there).
pub(all) struct EntityLocation {
  archetype_index : Int
  row : Int
}

///|
/// One SoA column: packed `stride`-byte rows for a single component type inside an archetype.
priv struct ComponentColumn {
  component : ComponentTypeId
  stride : Int
  bytes : Array[Byte]
}

///|
/// Archetype = entities sharing the same sorted component signature; rows are dense and moved on add/remove/swap-remove.
struct Archetype {
  components : Array[ComponentTypeId]
  entities : Array[EntityId]
  columns : Array[ComponentColumn]
}

///|
/// Flat storage indexed by `EntityId.index * stride`, independent of archetype rows so GPU layout stays stable when entities move.
struct GpuComponentStore {
  component : ComponentTypeId
  stride : Int
  bytes : Array[Byte]
  dirty_flags : Array[Bool]
  dirty_indices : Array[Int]
}

///|
/// One contiguous slice for `GPUQueue.writeBuffer` / `write_buffer_from_fixed_array` (byte_offset + payload).
pub(all) struct GpuWrite {
  byte_offset : Int
  bytes : FixedArray[Byte]
}

///|
/// Emitted when the flat GPU backing store grows; callers may need to recreate GPU buffers and optionally full-upload.
pub(all) struct GpuResizeEvent {
  component : ComponentTypeId
  required_capacity : Int
  needs_full_upload : Bool
}

///|
/// Thin query descriptor for system-style iteration over a fixed `required` component set.
pub struct Query {
  required : Array[ComponentTypeId]
}

///|
/// One row yielded by [`Query`], with component-id based access to the same zero-copy payload
/// views used by the lower-level world query.
pub struct QueryRow {
  world : World
  entity : EntityId
  components : Array[ComponentTypeId]
  payloads : Array[MutArrayView[Byte]]
}

///|
/// Deferred structural or GPU mutation command applied after query/system iteration.
pub(all) enum WorldCommand {
  DestroyEntity(EntityId)
  AddComponentBytes(EntityId, ComponentTypeId, FixedArray[Byte])
  RemoveComponent(EntityId, ComponentTypeId)
  SetGpuComponentBytes(EntityId, ComponentTypeId, FixedArray[Byte])
  ClearGpuComponent(EntityId, ComponentTypeId)
}

///|
/// FIFO command buffer for changes that must not run while ECS component views are being queried.
pub struct CommandBuffer {
  commands : Array[WorldCommand]
}

///|
/// Per-run data passed to systems by [`Schedule`].
pub(all) struct SystemContext {
  delta_seconds : Float
  frame_index : Int
}

///|
/// Coarse single-thread execution phase. Schedules run phases in declaration order.
pub(all) enum SystemPhase {
  PreUpdate
  Update
  PostUpdate
  PreRender
  RenderExtract
} derive(Eq)

///|
/// Function-backed ECS system metadata plus declared component access.
pub struct System {
  name : String
  phase : SystemPhase
  reads : Array[ComponentTypeId]
  writes : Array[ComponentTypeId]
  structural_write : Bool
  run : (World, SystemContext, CommandBuffer) -> Unit
}

///|
/// External system list. `World` stays focused on ECS storage and mutation.
pub struct Schedule {
  systems : Array[System]
}

///|
/// CPU archetypes for cache-friendly iteration + separate flat GPU stores per GPU-visible component type.
pub struct World {
  registry : ComponentRegistry
  generations : Array[Int]
  alive : Array[Bool]
  free_indices : Array[Int]
  locations : Array[EntityLocation?]
  archetypes : Array[Archetype]
  gpu_stores : Array[GpuComponentStore?]
  resize_events : Array[GpuResizeEvent]
  /// Query nesting depth; nonzero means callback code is currently iterating component views.
  mut query_depth : Int
  /// Schedule execution depth; component registration is closed while this is nonzero.
  mut component_registration_lock_depth : Int
  /// Active system access guard; nonzero means component reads/writes are checked against declarations.
  mut system_access_depth : Int
  mut system_access_reads : Array[ComponentTypeId]
  mut system_access_writes : Array[ComponentTypeId]
  mut system_access_structural_write : Bool
  transform_component_id : ComponentTypeId
  global_transform_component_id : ComponentTypeId
  child_of_component_id : ComponentTypeId
}
