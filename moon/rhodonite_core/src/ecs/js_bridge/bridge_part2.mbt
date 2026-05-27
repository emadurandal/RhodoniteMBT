/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `world_history_serialization_record_report_reason`.
pub fn world_history_serialization_record_report_reason(
  report : @ecs.WorldHistorySerializationRecordReport,
) -> String {
  report.reason
}

///|
/// Implements `world_history_serialization_record_report_delta_count`.
pub fn world_history_serialization_record_report_delta_count(
  report : @ecs.WorldHistorySerializationRecordReport,
) -> Int {
  report.delta_count
}

///|
/// Implements `world_history_serialization_record_report_payload_bytes`.
pub fn world_history_serialization_record_report_payload_bytes(
  report : @ecs.WorldHistorySerializationRecordReport,
) -> Int {
  report.payload_bytes
}

///|
/// Implements `world_history_serialization_record_report_deltas`.
pub fn world_history_serialization_record_report_deltas(
  report : @ecs.WorldHistorySerializationRecordReport,
) -> Array[@ecs.WorldHistorySerializationDeltaReport] {
  report.deltas
}

///|
/// Implements `world_history_serialization_delta_report_kind`.
pub fn world_history_serialization_delta_report_kind(
  report : @ecs.WorldHistorySerializationDeltaReport,
) -> String {
  report.kind
}

///|
/// Implements `world_history_serialization_delta_report_entity`.
pub fn world_history_serialization_delta_report_entity(
  report : @ecs.WorldHistorySerializationDeltaReport,
) -> @ecs.EntityId? {
  report.entity
}

///|
/// Implements `world_history_serialization_delta_report_component`.
pub fn world_history_serialization_delta_report_component(
  report : @ecs.WorldHistorySerializationDeltaReport,
) -> @ecs.ComponentTypeId? {
  report.component
}

///|
/// Implements `world_history_serialization_delta_report_component_count`.
pub fn world_history_serialization_delta_report_component_count(
  report : @ecs.WorldHistorySerializationDeltaReport,
) -> Int {
  report.component_count
}

///|
/// Implements `world_history_serialization_delta_report_serializable`.
pub fn world_history_serialization_delta_report_serializable(
  report : @ecs.WorldHistorySerializationDeltaReport,
) -> Bool {
  report.serializable
}

///|
/// Implements `world_history_serialization_delta_report_reason`.
pub fn world_history_serialization_delta_report_reason(
  report : @ecs.WorldHistorySerializationDeltaReport,
) -> String {
  report.reason
}

///|
/// Implements `world_history_serialization_delta_report_payload_bytes`.
pub fn world_history_serialization_delta_report_payload_bytes(
  report : @ecs.WorldHistorySerializationDeltaReport,
) -> Int {
  report.payload_bytes
}

///|
/// Implements `world_history_serialization_delta_report_components`.
pub fn world_history_serialization_delta_report_components(
  report : @ecs.WorldHistorySerializationDeltaReport,
) -> Array[@ecs.WorldHistorySerializationComponentReport] {
  report.components
}

///|
/// Implements `world_history_serialization_component_report_component`.
pub fn world_history_serialization_component_report_component(
  report : @ecs.WorldHistorySerializationComponentReport,
) -> @ecs.ComponentTypeId {
  report.component
}

///|
/// Implements `world_history_serialization_component_report_serializable`.
pub fn world_history_serialization_component_report_serializable(
  report : @ecs.WorldHistorySerializationComponentReport,
) -> Bool {
  report.serializable
}

///|
/// Implements `world_history_serialization_component_report_reason`.
pub fn world_history_serialization_component_report_reason(
  report : @ecs.WorldHistorySerializationComponentReport,
) -> String {
  report.reason
}

///|
/// Implements `world_history_serialization_component_report_stable_key`.
pub fn world_history_serialization_component_report_stable_key(
  report : @ecs.WorldHistorySerializationComponentReport,
) -> String? {
  report.stable_key
}

///|
/// Implements `world_history_export_format_version`.
pub fn world_history_export_format_version(
  exported : @ecs.WorldHistoryExport,
) -> Int {
  exported.format_version
}

///|
/// Implements `world_history_export_record_count`.
pub fn world_history_export_record_count(
  exported : @ecs.WorldHistoryExport,
) -> Int {
  exported.record_count
}

///|
/// Implements `world_history_export_records`.
pub fn world_history_export_records(
  exported : @ecs.WorldHistoryExport,
) -> Array[@ecs.WorldHistoryExportRecord] {
  exported.records
}

///|
/// Implements `world_history_export_record_label`.
pub fn world_history_export_record_label(
  record : @ecs.WorldHistoryExportRecord,
) -> String {
  record.label
}

///|
/// Implements `world_history_export_record_delta_count`.
pub fn world_history_export_record_delta_count(
  record : @ecs.WorldHistoryExportRecord,
) -> Int {
  record.delta_count
}

///|
/// Implements `world_history_export_record_deltas`.
pub fn world_history_export_record_deltas(
  record : @ecs.WorldHistoryExportRecord,
) -> Array[@ecs.WorldHistoryExportDelta] {
  record.deltas
}

///|
/// Implements `world_history_export_delta_kind`.
pub fn world_history_export_delta_kind(
  delta : @ecs.WorldHistoryExportDelta,
) -> String {
  delta.kind
}

///|
/// Implements `world_history_export_delta_entity`.
pub fn world_history_export_delta_entity(
  delta : @ecs.WorldHistoryExportDelta,
) -> @ecs.EntityId? {
  delta.entity
}

///|
/// Implements `world_history_export_delta_component`.
pub fn world_history_export_delta_component(
  delta : @ecs.WorldHistoryExportDelta,
) -> @ecs.WorldHistoryExportComponentIdentity? {
  delta.component
}

///|
/// Implements `world_history_export_delta_before`.
pub fn world_history_export_delta_before(
  delta : @ecs.WorldHistoryExportDelta,
) -> @ecs.WorldHistoryExportPayload? {
  delta.before
}

///|
/// Implements `world_history_export_delta_after`.
pub fn world_history_export_delta_after(
  delta : @ecs.WorldHistoryExportDelta,
) -> @ecs.WorldHistoryExportPayload? {
  delta.after
}

///|
/// Implements `world_history_export_delta_components`.
pub fn world_history_export_delta_components(
  delta : @ecs.WorldHistoryExportDelta,
) -> Array[@ecs.WorldHistoryExportComponentSnapshot] {
  delta.components
}

///|
/// Implements `world_history_export_component_identity_local_component`.
pub fn world_history_export_component_identity_local_component(
  identity : @ecs.WorldHistoryExportComponentIdentity,
) -> @ecs.ComponentTypeId {
  identity.local_component
}

///|
/// Implements `world_history_export_component_identity_key`.
pub fn world_history_export_component_identity_key(
  identity : @ecs.WorldHistoryExportComponentIdentity,
) -> String {
  identity.key
}

///|
/// Implements `world_history_export_component_identity_builtin`.
pub fn world_history_export_component_identity_builtin(
  identity : @ecs.WorldHistoryExportComponentIdentity,
) -> Bool {
  identity.builtin
}

///|
/// Implements `world_history_export_component_identity_schema_version`.
pub fn world_history_export_component_identity_schema_version(
  identity : @ecs.WorldHistoryExportComponentIdentity,
) -> String? {
  identity.schema_version
}

///|
/// Implements `world_history_export_component_identity_schema_hash`.
pub fn world_history_export_component_identity_schema_hash(
  identity : @ecs.WorldHistoryExportComponentIdentity,
) -> String? {
  identity.schema_hash
}

///|
/// Implements `world_history_export_payload_global_transform_format`.
pub fn world_history_export_payload_global_transform_format(
  payload : @ecs.WorldHistoryExportPayload,
) -> Int? {
  payload.global_transform_format
}

///|
/// Implements `world_history_export_payload_bytes`.
pub fn world_history_export_payload_bytes(
  payload : @ecs.WorldHistoryExportPayload,
) -> FixedArray[Byte] {
  payload.bytes
}

///|
/// Implements `world_history_export_component_snapshot_component`.
pub fn world_history_export_component_snapshot_component(
  snapshot : @ecs.WorldHistoryExportComponentSnapshot,
) -> @ecs.WorldHistoryExportComponentIdentity {
  snapshot.component
}

///|
/// Implements `world_history_export_component_snapshot_bytes`.
pub fn world_history_export_component_snapshot_bytes(
  snapshot : @ecs.WorldHistoryExportComponentSnapshot,
) -> FixedArray[Byte] {
  snapshot.bytes
}

///|
/// Implements `world_history_export_component_identity_new`.
pub fn world_history_export_component_identity_new(
  local_component : @ecs.ComponentTypeId,
  key : String,
  builtin : Bool,
  schema_version : String?,
  schema_hash : String?,
) -> @ecs.WorldHistoryExportComponentIdentity {
  { local_component, key, builtin, schema_version, schema_hash }
}

///|
/// Implements `world_history_export_payload_new`.
pub fn world_history_export_payload_new(
  global_transform_format : Int?,
  bytes : FixedArray[Byte],
) -> @ecs.WorldHistoryExportPayload {
  { global_transform_format, bytes }
}

///|
/// Implements `world_history_export_component_snapshot_new`.
pub fn world_history_export_component_snapshot_new(
  component : @ecs.WorldHistoryExportComponentIdentity,
  bytes : FixedArray[Byte],
) -> @ecs.WorldHistoryExportComponentSnapshot {
  { component, bytes }
}

///|
/// Implements `world_history_export_delta_new`.
pub fn world_history_export_delta_new(
  kind : String,
  entity : @ecs.EntityId?,
  component : @ecs.WorldHistoryExportComponentIdentity?,
  before : @ecs.WorldHistoryExportPayload?,
  after : @ecs.WorldHistoryExportPayload?,
  components : Array[@ecs.WorldHistoryExportComponentSnapshot],
) -> @ecs.WorldHistoryExportDelta {
  { kind, entity, component, before, after, components }
}

///|
/// Implements `world_history_export_record_new`.
pub fn world_history_export_record_new(
  label : String,
  delta_count : Int,
  deltas : Array[@ecs.WorldHistoryExportDelta],
) -> @ecs.WorldHistoryExportRecord {
  { label, delta_count, deltas }
}

///|
/// Implements `world_history_export_new`.
pub fn world_history_export_new(
  format_version : Int,
  record_count : Int,
  records : Array[@ecs.WorldHistoryExportRecord],
) -> @ecs.WorldHistoryExport {
  { format_version, record_count, records }
}

///|
/// Implements `world_history_record_summary_label`.
pub fn world_history_record_summary_label(
  summary : @ecs.WorldHistoryRecordSummary,
) -> String {
  summary.label
}

///|
/// Implements `world_history_record_summary_delta_count`.
pub fn world_history_record_summary_delta_count(
  summary : @ecs.WorldHistoryRecordSummary,
) -> Int {
  summary.delta_count
}

///|
/// Implements `world_history_record_summary_payload_bytes`.
pub fn world_history_record_summary_payload_bytes(
  summary : @ecs.WorldHistoryRecordSummary,
) -> Int {
  summary.payload_bytes
}

///|
/// Implements `world_history_record_summary_deltas`.
pub fn world_history_record_summary_deltas(
  summary : @ecs.WorldHistoryRecordSummary,
) -> Array[@ecs.WorldHistoryDeltaSummary] {
  summary.deltas
}

///|
/// Implements `world_history_delta_summary_kind`.
pub fn world_history_delta_summary_kind(
  summary : @ecs.WorldHistoryDeltaSummary,
) -> String {
  summary.kind
}

///|
/// Implements `world_history_delta_summary_entity`.
pub fn world_history_delta_summary_entity(
  summary : @ecs.WorldHistoryDeltaSummary,
) -> @ecs.EntityId? {
  summary.entity
}

///|
/// Implements `world_history_delta_summary_component`.
pub fn world_history_delta_summary_component(
  summary : @ecs.WorldHistoryDeltaSummary,
) -> @ecs.ComponentTypeId? {
  summary.component
}

///|
/// Implements `world_history_delta_summary_component_count`.
pub fn world_history_delta_summary_component_count(
  summary : @ecs.WorldHistoryDeltaSummary,
) -> Int {
  summary.component_count
}

///|
/// Implements `world_history_delta_summary_payload_bytes`.
pub fn world_history_delta_summary_payload_bytes(
  summary : @ecs.WorldHistoryDeltaSummary,
) -> Int {
  summary.payload_bytes
}

///|
/// Implements `world_history_delta_summary_before_present`.
pub fn world_history_delta_summary_before_present(
  summary : @ecs.WorldHistoryDeltaSummary,
) -> Bool {
  summary.before_present
}

///|
/// Implements `world_history_delta_summary_after_present`.
pub fn world_history_delta_summary_after_present(
  summary : @ecs.WorldHistoryDeltaSummary,
) -> Bool {
  summary.after_present
}

///|
/// Implements `world_history_last_diagnostic`.
pub fn world_history_last_diagnostic(history : @ecs.WorldHistory) -> String {
  history.last_diagnostic()
}

///|
/// Implements `world_history_undo_label`.
pub fn world_history_undo_label(history : @ecs.WorldHistory) -> String? {
  history.undo_label()
}

///|
/// Implements `world_history_redo_label`.
pub fn world_history_redo_label(history : @ecs.WorldHistory) -> String? {
  history.redo_label()
}

///|
/// Implements `world_history_begin_transaction`.
pub fn world_history_begin_transaction(
  history : @ecs.WorldHistory,
  label : String,
) -> Bool {
  history.begin_transaction(label)
}

///|
/// Implements `world_history_begin_guarded_transaction`.
pub fn world_history_begin_guarded_transaction(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  label : String,
) -> Bool {
  history.begin_guarded_transaction(world, label)
}

///|
/// Implements `world_history_commit_transaction`.
pub fn world_history_commit_transaction(history : @ecs.WorldHistory) -> Bool {
  history.commit_transaction()
}

///|
/// Implements `world_history_cancel_transaction`.
pub fn world_history_cancel_transaction(history : @ecs.WorldHistory) -> Bool {
  history.cancel_transaction()
}

///|
/// Implements `world_history_cancel_transaction_preserving_diagnostic`.
pub fn world_history_cancel_transaction_preserving_diagnostic(
  history : @ecs.WorldHistory,
) -> Bool {
  history.cancel_transaction_preserving_diagnostic()
}

///|
/// Implements `world_history_cancel_transaction_reverting`.
pub fn world_history_cancel_transaction_reverting(
  history : @ecs.WorldHistory,
  world : @ecs.World,
) -> Bool {
  history.cancel_transaction_reverting(world)
}

///|
/// Implements `world_history_can_undo`.
pub fn world_history_can_undo(history : @ecs.WorldHistory) -> Bool {
  history.can_undo()
}

///|
/// Implements `world_history_can_redo`.
pub fn world_history_can_redo(history : @ecs.WorldHistory) -> Bool {
  history.can_redo()
}

///|
/// Implements `world_history_undo`.
pub fn world_history_undo(
  history : @ecs.WorldHistory,
  world : @ecs.World,
) -> Bool {
  history.undo(world)
}

///|
/// Implements `world_history_redo`.
pub fn world_history_redo(
  history : @ecs.WorldHistory,
  world : @ecs.World,
) -> Bool {
  history.redo(world)
}

///|
/// Implements `world_history_create_entity`.
pub fn world_history_create_entity(
  history : @ecs.WorldHistory,
  world : @ecs.World,
) -> @ecs.EntityId {
  history.create_entity(world)
}

///|
/// Implements `world_history_create_entities`.
pub fn world_history_create_entities(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  count : Int,
) -> Array[@ecs.EntityId] {
  history.create_entities(world, count)
}

///|
/// Implements `world_history_spawn_batch`.
pub fn world_history_spawn_batch(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  components : Array[@ecs.ComponentTypeId],
  count : Int,
  f : (Int, @ecs.EntityId, @ecs.SpawnBatchRow) -> Unit,
) -> Array[@ecs.EntityId] {
  history.spawn_batch(world, components, count, f)
}

///|
/// Implements `world_history_destroy_entity`.
pub fn world_history_destroy_entity(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
) -> Bool {
  history.destroy_entity(world, entity)
}

///|
/// Implements `world_history_add_component`.
pub fn world_history_add_component(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
) -> Bool {
  history.add_component(world, entity, component)
}

///|
/// Implements `world_history_add_component_bytes`.
pub fn world_history_add_component_bytes(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  history.add_component_bytes(world, entity, component, bytes)
}

///|
/// Implements `world_history_add_component_bytes_many`.
pub fn world_history_add_component_bytes_many(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  component : @ecs.ComponentTypeId,
  entities : Array[@ecs.EntityId],
  bytes_list : Array[FixedArray[Byte]],
) -> Bool {
  history.add_component_bytes_many(world, component, entities, bytes_list)
}

///|
/// Implements `world_history_set_component_bytes`.
pub fn world_history_set_component_bytes(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  history.set_component_bytes(world, entity, component, bytes)
}

///|
/// Implements `world_history_set_component_bytes_many`.
pub fn world_history_set_component_bytes_many(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  component : @ecs.ComponentTypeId,
  entities : Array[@ecs.EntityId],
  bytes_list : Array[FixedArray[Byte]],
) -> Bool {
  history.set_component_bytes_many(world, component, entities, bytes_list)
}

///|
/// Implements `world_history_remove_component`.
pub fn world_history_remove_component(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
) -> Bool {
  history.remove_component(world, entity, component)
}

///|
/// Implements `world_history_set_transform_trs`.
pub fn world_history_set_transform_trs(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
  px : Float,
  py : Float,
  pz : Float,
  qx : Double,
  qy : Double,
  qz : Double,
  qw : Double,
  sx : Float,
  sy : Float,
  sz : Float,
) -> Bool {
  history.set_transform_trs(
    world, entity, px, py, pz, qx, qy, qz, qw, sx, sy, sz,
  )
}

///|
/// Implements `world_history_set_global_transform_col_major`.
pub fn world_history_set_global_transform_col_major(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
  matrix_col_major : FixedArray[Float],
) -> Bool {
  history.set_global_transform(
    world,
    entity,
    matrix44f_from_col_major_array(matrix_col_major),
  )
}

///|
/// Implements `world_history_set_global_transform_format`.
pub fn world_history_set_global_transform_format(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
  format_code : UInt,
) -> Bool {
  history.set_global_transform_format(
    world,
    entity,
    @comp.global_transform_format_from_code(format_code),
  )
}

///|
/// Implements `world_history_set_child_of`.
pub fn world_history_set_child_of(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
  parent : @ecs.EntityId,
) -> Bool {
  history.set_child_of(world, entity, parent)
}

///|
/// Implements `world_history_set_camera_matrices_col_major`.
pub fn world_history_set_camera_matrices_col_major(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
  view_col_major : FixedArray[Float],
  proj_col_major : FixedArray[Float],
  near : Float,
  far : Float,
  aspect : Float,
  projection_kind : Float,
  flags : Float,
) -> Bool {
  history.set_camera_matrices(
    world,
    entity,
    matrix44f_from_col_major_array(view_col_major),
    matrix44f_from_col_major_array(proj_col_major),
    near,
    far,
    aspect,
    projection_kind,
    flags,
  )
}

///|
/// Implements `spawn_batch_row_entity`.
pub fn spawn_batch_row_entity(row : @ecs.SpawnBatchRow) -> @ecs.EntityId {
  row.entity()
}

///|
/// Implements `spawn_batch_row_write_view`.
pub fn spawn_batch_row_write_view(
  row : @ecs.SpawnBatchRow,
  component : @ecs.ComponentTypeId,
) -> MutArrayView[Byte] {
  row.write_view(component)
}

///|
/// Implements `spawn_batch_row_write`.
pub fn spawn_batch_row_write(
  row : @ecs.SpawnBatchRow,
  component : @ecs.ComponentTypeId,
  f : (MutArrayView[Byte]) -> Unit,
) -> Unit {
  row.write(component, f)
}

///|
/// Implements `query_new`.
pub fn query_new(required : Array[@ecs.ComponentTypeId]) -> @ecs.Query {
  @ecs.Query::new(required)
}

///|
/// Implements `query_new_with_excluded`.
pub fn query_new_with_excluded(
  required : Array[@ecs.ComponentTypeId],
  excluded : Array[@ecs.ComponentTypeId],
) -> @ecs.Query {
  @ecs.Query::new_with_excluded(required, excluded)
}

///|
/// Implements `raw_query_new`.
pub fn raw_query_new(required : Array[@ecs.ComponentTypeId]) -> @ecs.RawQuery {
  @ecs.RawQuery::new(required)
}

///|
/// Implements `raw_query_new_with_excluded`.
pub fn raw_query_new_with_excluded(
  required : Array[@ecs.ComponentTypeId],
  excluded : Array[@ecs.ComponentTypeId],
) -> @ecs.RawQuery {
  @ecs.RawQuery::new_with_excluded(required, excluded)
}

///|
/// Implements `query_cache_new`.
pub fn query_cache_new(
  required : Array[@ecs.ComponentTypeId],
) -> @ecs.QueryCache {
  @ecs.QueryCache::new(required)
}

///|
/// Implements `query_cache_new_with_excluded`.
pub fn query_cache_new_with_excluded(
  required : Array[@ecs.ComponentTypeId],
  excluded : Array[@ecs.ComponentTypeId],
) -> @ecs.QueryCache {
  @ecs.QueryCache::new_with_excluded(required, excluded)
}

///|
/// Implements `raw_query_cache_new`.
pub fn raw_query_cache_new(
  required : Array[@ecs.ComponentTypeId],
) -> @ecs.RawQueryCache {
  @ecs.RawQueryCache::new(required)
}

///|
/// Implements `raw_query_cache_new_with_excluded`.
pub fn raw_query_cache_new_with_excluded(
  required : Array[@ecs.ComponentTypeId],
  excluded : Array[@ecs.ComponentTypeId],
) -> @ecs.RawQueryCache {
  @ecs.RawQueryCache::new_with_excluded(required, excluded)
}

///|
/// Implements `query_required_components`.
pub fn query_required_components(
  query : @ecs.Query,
) -> Array[@ecs.ComponentTypeId] {
  query.required_components()
}

///|
/// Implements `query_excluded_components`.
pub fn query_excluded_components(
  query : @ecs.Query,
) -> Array[@ecs.ComponentTypeId] {
  query.excluded_components()
}

///|
/// Implements `query_component_index`.
pub fn query_component_index(
  query : @ecs.Query,
  component : @ecs.ComponentTypeId,
) -> Int {
  query.component_index(component)
}

///|
/// Implements `query_cache_required_components`.
pub fn query_cache_required_components(
  cache : @ecs.QueryCache,
) -> Array[@ecs.ComponentTypeId] {
  cache.required_components()
}

///|
/// Implements `query_cache_excluded_components`.
pub fn query_cache_excluded_components(
  cache : @ecs.QueryCache,
) -> Array[@ecs.ComponentTypeId] {
  cache.excluded_components()
}

///|
/// Implements `query_cache_component_index`.
pub fn query_cache_component_index(
  cache : @ecs.QueryCache,
  component : @ecs.ComponentTypeId,
) -> Int {
  cache.component_index(component)
}

///|
/// Implements `raw_query_cache_required_components`.
pub fn raw_query_cache_required_components(
  cache : @ecs.RawQueryCache,
) -> Array[@ecs.ComponentTypeId] {
  cache.required_components()
}
