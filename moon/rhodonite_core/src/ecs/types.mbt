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
priv struct ComponentRegistry {
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
///
/// `row_capacity` is the backing-capacity watermark used by append helpers. It keeps column growth
/// policy explicit without exposing storage details to query hot paths.
priv struct ComponentColumn {
  component : ComponentTypeId
  stride : Int
  bytes : Array[Byte]
  mut row_capacity : Int
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
  mut bytes : FixedArray[Byte]
  dirty_flags : Array[Bool]
  dirty_indices : Array[Int]
  dirty_range_first : Array[Int]
  dirty_range_last : Array[Int]
  sort_bucket : Array[Bool]
  active_flags : Array[Bool]
  active_indices : Array[Int]
  active_positions : Array[Int]
}

///|
/// One contiguous slice for `GPUQueue.writeBuffer` / `write_buffer_from_fixed_array` (byte_offset + payload).
pub(all) struct GpuWrite {
  byte_offset : Int
  bytes : FixedArray[Byte]
}

///|
/// Borrowed contiguous GPU upload slice. Callers should upload these views before mutating the same GPU component store again.
pub(all) struct GpuWriteView {
  byte_offset : Int
  bytes : ArrayView[Byte]
}

///|
/// Emitted when the flat GPU backing store grows; callers may need to recreate GPU buffers and optionally full-upload.
pub(all) struct GpuResizeEvent {
  component : ComponentTypeId
  required_capacity : Int
  needs_full_upload : Bool
}

///|
/// Emitted when a packed builtin GPU word blob grows.
pub(all) struct PackedGpuBlobResizeEvent {
  required_word_capacity : Int
  needs_full_upload : Bool
}

///|
/// Backward-compatible name for GlobalTransform blob resize events.
pub type GlobalTransformBlobResizeEvent = PackedGpuBlobResizeEvent

///|
/// Thin query descriptor for system-style iteration over a fixed `required` component set.
pub struct Query {
  priv required : Array[ComponentTypeId]
}

///|
/// Raw query descriptor for expert byte-view iteration over a fixed `required` component set.
pub struct RawQuery {
  priv required : Array[ComponentTypeId]
}

///|
/// Cached row plan for repeated high-level iteration over the same query.
pub struct PreparedQuery {
  priv required : Array[ComponentTypeId]
  priv archetype_version : Int
  priv archetypes : Array[PreparedQueryArchetype]
}

///|
/// Cached raw archetype-column plan for repeated expert iteration over the same query.
pub struct RawPreparedQuery {
  priv required : Array[ComponentTypeId]
  priv archetype_version : Int
  priv archetypes : Array[PreparedQueryArchetype]
}

///|
priv struct QueryRowComponentAccess {
  kind : ComponentKind
  column_index : Int
  stride : Int
}

///|
/// Cached component lookup for one matched archetype chunk. This avoids repeated linear
/// `column_index` scans inside `RawQueryArchetype::read_column` / `write_column` hot loops.
priv struct QueryArchetypeComponentAccess {
  component : ComponentTypeId
  kind : ComponentKind
  column_index : Int
  stride : Int
}

///|
priv struct PreparedQueryArchetype {
  archetype_index : Int
  accesses : Array[QueryArchetypeComponentAccess]
}

///|
priv struct ArchetypeSignatureCacheEntry {
  hash : Int
  components : Array[ComponentTypeId]
  archetype_index : Int
}

///|
/// One row yielded by [`Query`], with component-id based access to the same zero-copy payload
/// views through closure-scoped high-level helpers.
pub struct QueryRow {
  priv world : World
  priv entity : EntityId
  priv components : Array[ComponentTypeId]
  priv accesses : Array[QueryRowComponentAccess]
  priv archetype_index : Int
  priv row : Int
}

///|
/// One row yielded by [`RawQuery`], exposing expert zero-copy byte views directly.
pub struct RawQueryRow {
  priv world : World
  priv entity : EntityId
  priv components : Array[ComponentTypeId]
  priv accesses : Array[QueryRowComponentAccess]
  priv archetype_index : Int
  priv row : Int
}

///|
/// One row yielded while batch-spawning entities directly into a target archetype.
pub struct SpawnBatchRow {
  priv world : World
  priv entity : EntityId
  priv archetype_index : Int
  priv row : Int
}

///|
/// One archetype chunk yielded by [`RawQuery::for_each_archetype`]. Use column views plus row
/// strides for hot loops that should avoid constructing one [`QueryRow`] per entity.
pub struct RawQueryArchetype {
  priv world : World
  priv accesses : Array[QueryArchetypeComponentAccess]
  priv archetype_index : Int
}

///|
/// Mutable contiguous GPU-visible component range borrowed through [`World`].
pub struct GpuComponentWriteRange {
  priv bytes : MutArrayView[Byte]
  priv stride : Int
  priv first_entity_index : Int
  priv count : Int
}

///|
/// CPU-side handle stored in the builtin GlobalTransform component and mirrored into render items.
pub(all) struct GlobalTransformRef {
  format : @comp.GlobalTransformGpuFormat
  word_offset : Int
}

///|
/// CPU-side handle stored in the builtin Camera component.
pub(all) struct CameraRef {
  word_offset : Int
}

///|
/// Packed `u32` backing store with variable-size word span allocation and upload tracking.
priv struct PackedGpuBlobStore {
  mut bytes : FixedArray[Byte]
  mut next_word_offset : Int
  free_word_offsets : Array[Int]
  free_word_counts : Array[Int]
  dirty_word_first : Array[Int]
  dirty_word_last : Array[Int]
  resize_events : Array[PackedGpuBlobResizeEvent]
}

///|
/// Packed `u32` backing store for builtin GlobalTransform affine rows.
struct GlobalTransformBlobStore {
  store : PackedGpuBlobStore
}

///|
/// Packed `u32` backing store for builtin Camera GPU rows.
struct CameraBlobStore {
  store : PackedGpuBlobStore
}

///|
/// Deferred structural or payload mutation command applied after query/system iteration.
pub(all) enum WorldCommand {
  CreateEntity(EntityId)
  DestroyEntity(EntityId)
  AddComponent(EntityId, ComponentTypeId)
  AddComponentBytes(EntityId, ComponentTypeId, FixedArray[Byte])
  SetComponentBytes(EntityId, ComponentTypeId, FixedArray[Byte])
  RemoveComponent(EntityId, ComponentTypeId)
  ClearGpuComponent(EntityId, ComponentTypeId)
}

///|
/// FIFO command buffer for changes that must not run while ECS component views are being queried.
pub struct CommandBuffer {
  priv commands : Array[WorldCommand]
  priv world : World
  priv system_name : String
  priv writes : Array[ComponentTypeId]
  priv structural_write : Bool
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
  priv name : String
  priv phase : SystemPhase
  priv reads : Array[ComponentTypeId]
  priv writes : Array[ComponentTypeId]
  priv structural_write : Bool
  priv run : (World, SystemContext, CommandBuffer) -> Unit
}

///|
/// External system list. `World` stays focused on ECS storage and mutation.
pub struct Schedule {
  priv systems : Array[System]
}

///|
/// CPU archetypes for cache-friendly iteration + separate flat GPU stores per GPU-visible component type.
pub struct World {
  priv registry : ComponentRegistry
  priv generations : Array[Int]
  priv alive : Array[Bool]
  priv reserved : Array[Bool]
  priv free_indices : Array[Int]
  priv locations : Array[EntityLocation?]
  priv archetypes : Array[Archetype]
  priv mut archetype_version : Int
  priv archetype_signature_cache : Array[ArchetypeSignatureCacheEntry]
  priv component_archetypes : Array[Array[Int]]
  priv gpu_stores : Array[GpuComponentStore?]
  priv global_transform_blob : GlobalTransformBlobStore
  priv camera_blob : CameraBlobStore
  priv resize_events : Array[GpuResizeEvent]
  /// Query nesting depth; nonzero means callback code is currently iterating component views.
  priv mut query_depth : Int
  /// Schedule execution depth; component registration is closed while this is nonzero.
  priv mut component_registration_lock_depth : Int
  /// Active system access guard; nonzero means component reads/writes are checked against declarations.
  priv mut system_access_depth : Int
  priv mut system_access_name : String
  priv mut system_access_reads : Array[ComponentTypeId]
  priv mut system_access_writes : Array[ComponentTypeId]
  priv mut system_access_structural_write : Bool
  priv transform_component_id : ComponentTypeId
  priv global_transform_component_id : ComponentTypeId
  priv global_transform_default_format : @comp.GlobalTransformGpuFormat
  priv child_of_component_id : ComponentTypeId
  priv camera_component_id : ComponentTypeId
}
