/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///| Stable slot index for dense arrays (GPU buffers index by `index`; shaders use it as the array subscript).

///|
/// `generation` bumps on destroy/reuse so stale `EntityId` handles are rejected.
pub(all) struct EntityId {
  index : Int
  generation : Int
} derive(Eq)

///|
/// Implements `EntityId::new`.
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
/// Implements `ComponentTypeId::new`.
pub fn ComponentTypeId::new(index : Int) -> ComponentTypeId {
  { index, }
}

///|
/// Metadata for one registered component: `cpu_stride` is the SoA row width.
///
/// `stable_key`, `schema_version`, and `schema_hash` are optional authoring
/// metadata for future history serialization; runtime ECS lookup still uses `id`.
pub(all) struct RegisteredComponent {
  id : ComponentTypeId
  name : String
  cpu_stride : Int
  stable_key : String?
  schema_version : String?
  schema_hash : String?
}

///|
/// Issues monotonic `ComponentTypeId`s; CPU stride is fixed at registration time (no runtime reflection).
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
  mut bytes : FixedArray[Byte]
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
/// One contiguous slice for `GPUQueue.writeBuffer` / `write_buffer_from_fixed_array` (byte_offset + payload).
pub(all) struct GpuWrite {
  byte_offset : Int
  bytes : FixedArray[Byte]
}

///|
/// Borrowed contiguous GPU upload slice. Callers should upload these views before mutating the same packed blob again.
pub(all) struct GpuWriteView {
  byte_offset : Int
  bytes : ArrayView[Byte]
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
/// Thin query descriptor for system-style iteration over a fixed required component set and optional excluded component filter.
pub struct Query {
  priv required : Array[ComponentTypeId]
  priv excluded : Array[ComponentTypeId]
}

///|
/// Raw query descriptor for expert byte-view iteration over a fixed required component set and optional excluded component filter.
pub struct RawQuery {
  priv required : Array[ComponentTypeId]
  priv excluded : Array[ComponentTypeId]
}

///|
/// Caller-owned row query cache that reuses a prepared plan until the world's archetype layout changes.
pub struct QueryCache {
  priv query : Query
  priv mut prepared : PreparedQuery?
}

///|
/// Caller-owned raw query cache that reuses a prepared archetype plan until the layout changes.
pub struct RawQueryCache {
  priv query : RawQuery
  priv mut prepared : RawPreparedQuery?
}

///|
/// One matched archetype entry inside a read-only query plan snapshot.
pub(all) struct QueryPlanArchetype {
  archetype_index : Int
  row_count : Int
}

///|
/// Read-only diagnostic snapshot for a query plan against one world's current archetype layout.
pub(all) struct QueryPlan {
  required : Array[ComponentTypeId]
  excluded : Array[ComponentTypeId]
  archetype_version : Int
  candidate_archetype_count : Int
  matched_archetype_count : Int
  matched_row_count : Int
  stale : Bool
  archetypes : Array[QueryPlanArchetype]
}

///|
/// Cached row plan for repeated high-level iteration over the same query.
pub struct PreparedQuery {
  priv required : Array[ComponentTypeId]
  priv excluded : Array[ComponentTypeId]
  priv archetype_version : Int
  priv archetypes : Array[PreparedQueryArchetype]
}

///|
/// Cached raw archetype-column plan for repeated expert iteration over the same query.
pub struct RawPreparedQuery {
  priv required : Array[ComponentTypeId]
  priv excluded : Array[ComponentTypeId]
  priv archetype_version : Int
  priv archetypes : Array[PreparedQueryArchetype]
}

///|
priv struct QueryRowComponentAccess {
  column_index : Int
  stride : Int
}

///|
/// Cached component lookup for one matched archetype chunk. This avoids repeated linear
/// `column_index` scans inside `RawQueryArchetype::read_column` / `write_column` hot loops.
priv struct QueryArchetypeComponentAccess {
  component : ComponentTypeId
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
#cfg(target="js")
struct CameraBlobStore {
  store : PackedGpuBlobStore
}

///|
/// Packed `u32` backing store for builtin Camera GPU rows.
#cfg(not(target="js"))
struct CameraBlobStore {
  store : PackedGpuBlobStore
  cache_valid : Array[Bool]
  cache_word_offsets : Array[Int]
  cache_words : Array[FixedArray[UInt]]
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
  SetGlobalTransform(EntityId, @m44.Matrix44F)
  SetGlobalTransformFormat(EntityId, @comp.GlobalTransformGpuFormat)
  SetCameraMatrices(
    EntityId,
    @m44.Matrix44F,
    @m44.Matrix44F,
    Float,
    Float,
    Float,
    Float,
    Float
  )
}

///|
/// FIFO command buffer for changes that must not run while ECS component views are being queried.
pub struct CommandBuffer {
  priv commands : Array[WorldCommand]
  priv world : World
  priv system_name : String
  priv writes : Array[ComponentTypeId]
  priv structural_write : Bool
  priv history : WorldHistory?
}

///|
/// Per-run data passed to systems by [`SystemRunner`].
pub(all) struct SystemContext {
  delta_seconds : Float
  frame_index : Int
}

///|
/// Open system phase identifier. The runner only compares phase names; lifecycle meaning and
/// execution order are supplied by the caller.
pub(all) struct PhaseKey {
  name : String
} derive(Eq)

///|
/// Function-backed ECS system metadata plus declared component access.
pub struct System {
  priv name : String
  priv phase : PhaseKey
  priv reads : Array[ComponentTypeId]
  priv writes : Array[ComponentTypeId]
  priv structural_write : Bool
  priv run : (World, SystemContext, CommandBuffer) -> Unit
}

///|
/// One scheduled system entry inside a private execution batch.
priv struct ScheduledSystem {
  runner_index : Int
  system : System
}

///|
/// Private execution batch built from one `SystemRunner` phase.
priv struct SystemBatch {
  systems : Array[ScheduledSystem]
}

///|
/// Cached private execution batches for one `SystemRunner` phase and generation.
priv struct SystemPhaseBatchCache {
  phase : PhaseKey
  generation : Int
  batches : Array[SystemBatch]
}

///|
/// Read-only snapshot of one system in a planned phase batch.
pub(all) struct SystemPlanSystem {
  runner_index : Int
  batch_index : Int
  name : String
  phase : PhaseKey
  reads : Array[ComponentTypeId]
  writes : Array[ComponentTypeId]
  structural_write : Bool
}

///|
/// Read-only snapshot of one conflict-free planned system batch.
pub(all) struct SystemPlanBatch {
  index : Int
  systems : Array[SystemPlanSystem]
}

///|
/// Read-only snapshot of the batches `SystemRunner::run_phase` would execute for a phase.
pub(all) struct SystemPhasePlan {
  phase : PhaseKey
  system_count : Int
  batches : Array[SystemPlanBatch]
}

///|
/// Read-only diagnostic for one failed queued command during system phase apply.
pub(all) struct CommandBufferCommandFailure {
  command_index : Int
  command_kind : String
  reason : String
  entity : EntityId
  component : ComponentTypeId
}

///|
/// Read-only execution report for one system's queued command buffer.
pub(all) struct SystemRunSystemReport {
  runner_index : Int
  batch_index : Int
  name : String
  queued_command_count : Int
  applied_command_count : Int
  failed_command_count : Int
  failures : Array[CommandBufferCommandFailure]
}

///|
/// Read-only execution report for one conflict-free system batch.
pub(all) struct SystemRunBatchReport {
  index : Int
  ok : Bool
  system_count : Int
  queued_command_count : Int
  applied_command_count : Int
  failed_command_count : Int
  systems : Array[SystemRunSystemReport]
}

///|
/// Read-only execution report for one `SystemRunner` phase run.
pub(all) struct SystemRunReport {
  phase : PhaseKey
  ok : Bool
  batch_count : Int
  system_count : Int
  queued_command_count : Int
  applied_command_count : Int
  failed_command_count : Int
  batches : Array[SystemRunBatchReport]
}

///|
/// Phase-filtered ECS system runner. `World` stays focused on ECS storage and mutation.
pub struct SystemRunner {
  priv systems : Array[System]
  priv mut plan_generation : Int
  priv mut phase_batch_cache : Array[SystemPhaseBatchCache]
}

///|
/// CPU archetypes for cache-friendly iteration.
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
  priv global_transform_blob : GlobalTransformBlobStore
  priv camera_blob : CameraBlobStore
  /// Entity ids whose local transform inputs changed since the last dirty propagation pass.
  priv transform_dirty_entities : Array[EntityId]
  /// Generation stamp per entity index for the current transform dirty queue; `-1` means clean.
  priv transform_dirty_generations : Array[Int]
  /// Query nesting depth; nonzero means callback code is currently iterating component views.
  priv mut query_depth : Int
  /// SystemRunner execution depth; component registration is closed while this is nonzero.
  priv mut component_registration_lock_depth : Int
  /// Active system access guard; nonzero means component reads/writes are checked against declarations.
  priv mut system_access_depth : Int
  priv mut system_access_name : String
  priv mut system_access_reads : Array[ComponentTypeId]
  priv mut system_access_writes : Array[ComponentTypeId]
  priv mut system_access_structural_write : Bool
  /// Raw ECS mutation guard depth armed by WorldHistory guarded transactions.
  priv mut history_raw_mutation_guard_depth : Int
  /// Tracked mutation bypass depth used by WorldHistory while applying recorded changes.
  priv mut history_tracked_mutation_depth : Int
  priv transform_component_id : ComponentTypeId
  priv global_transform_component_id : ComponentTypeId
  priv global_transform_default_format : @comp.GlobalTransformGpuFormat
  priv child_of_component_id : ComponentTypeId
  priv camera_component_id : ComponentTypeId
  priv orbit_camera_controller_component_id : ComponentTypeId
  priv camera_home_transform_component_id : ComponentTypeId
  priv camera_lens_component_id : ComponentTypeId
}
