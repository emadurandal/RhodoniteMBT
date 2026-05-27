/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// One component payload captured for a restorable entity snapshot.
priv struct ComponentSnapshot {
  component : ComponentTypeId
  bytes : FixedArray[Byte]
}

///|
/// Entity contents captured before destruction so undo can restore the same id.
priv struct EntitySnapshot {
  entity : EntityId
  components : Array[ComponentSnapshot]
}

///|
/// One packed GlobalTransform GPU row captured for history replay.
priv struct GlobalTransformHistoryRow {
  format : @comp.GlobalTransformGpuFormat
  bytes : FixedArray[Byte]
}

///|
/// Minimal reversible ECS mutation recorded by [`WorldHistory`].
priv enum WorldDelta {
  EntityCreated(EntityId)
  EntityDestroyed(EntitySnapshot)
  ComponentAdded(EntityId, ComponentTypeId, FixedArray[Byte])
  ComponentRemoved(EntityId, ComponentTypeId, FixedArray[Byte])
  ComponentChanged(
    EntityId,
    ComponentTypeId,
    FixedArray[Byte],
    FixedArray[Byte]
  )
  GlobalTransformChanged(
    EntityId,
    GlobalTransformHistoryRow?,
    GlobalTransformHistoryRow
  )
  CameraChanged(EntityId, FixedArray[Byte]?, FixedArray[Byte])
}

///|
/// One committed user-facing undo/redo transaction.
priv struct WorldHistoryRecord {
  label : String
  deltas : Array[WorldDelta]
}

///|
/// Transaction-local lookup key for one component-row delta.
priv struct HistoryComponentDeltaIndexKey {
  entity_index : Int
  entity_generation : Int
  component_index : Int
} derive(Eq, Hash)

///|
/// Transaction-local lookup key for one entity-scoped builtin delta.
priv struct HistoryEntityDeltaIndexKey {
  entity_index : Int
  entity_generation : Int
} derive(Eq, Hash)

///|
/// Payload-free diagnostic summary for one reversible delta.
pub(all) struct WorldHistoryDeltaSummary {
  kind : String
  entity : EntityId?
  component : ComponentTypeId?
  component_count : Int
  payload_bytes : Int
  before_present : Bool
  after_present : Bool
}

///|
/// Payload-free diagnostic summary for one committed history record.
pub(all) struct WorldHistoryRecordSummary {
  label : String
  delta_count : Int
  payload_bytes : Int
  deltas : Array[WorldHistoryDeltaSummary]
}

///|
/// Payload-free serialization eligibility report for one component dependency.
pub(all) struct WorldHistorySerializationComponentReport {
  component : ComponentTypeId
  serializable : Bool
  reason : String
  stable_key : String?
}

///|
/// Payload-free serialization eligibility report for one reversible delta.
pub(all) struct WorldHistorySerializationDeltaReport {
  kind : String
  entity : EntityId?
  component : ComponentTypeId?
  component_count : Int
  serializable : Bool
  reason : String
  payload_bytes : Int
  components : Array[WorldHistorySerializationComponentReport]
}

///|
/// Payload-free serialization eligibility report for one committed record.
pub(all) struct WorldHistorySerializationRecordReport {
  label : String
  serializable : Bool
  reason : String
  delta_count : Int
  payload_bytes : Int
  deltas : Array[WorldHistorySerializationDeltaReport]
}

///|
/// Payload-free serialization eligibility report for one history stack.
pub(all) struct WorldHistorySerializationReport {
  serializable : Bool
  record_count : Int
  records : Array[WorldHistorySerializationRecordReport]
}

///|
/// Stable component identity stored beside exported history payload bytes.
pub(all) struct WorldHistoryExportComponentIdentity {
  local_component : ComponentTypeId
  key : String
  builtin : Bool
  schema_version : String?
  schema_hash : String?
}

///|
/// Byte payload for an exported history delta.
pub(all) struct WorldHistoryExportPayload {
  global_transform_format : Int?
  bytes : FixedArray[Byte]
}

///|
/// Component bytes captured for an exported entity-destroyed delta.
pub(all) struct WorldHistoryExportComponentSnapshot {
  component : WorldHistoryExportComponentIdentity
  bytes : FixedArray[Byte]
}

///|
/// One exported reversible delta with stable component identity metadata.
pub(all) struct WorldHistoryExportDelta {
  kind : String
  entity : EntityId?
  component : WorldHistoryExportComponentIdentity?
  before : WorldHistoryExportPayload?
  after : WorldHistoryExportPayload?
  components : Array[WorldHistoryExportComponentSnapshot]
}

///|
/// One exported committed history record.
pub(all) struct WorldHistoryExportRecord {
  label : String
  delta_count : Int
  deltas : Array[WorldHistoryExportDelta]
}

///|
/// In-memory draft export of one history stack.
pub(all) struct WorldHistoryExport {
  format_version : Int
  record_count : Int
  records : Array[WorldHistoryExportRecord]
}

///|
/// Payload-free validation report for one imported delta.
pub(all) struct WorldHistoryImportValidationDeltaReport {
  index : Int
  kind : String
  entity : EntityId?
  component : ComponentTypeId?
  component_key : String?
  valid : Bool
  reason : String
}

///|
/// Payload-free validation report for one imported record.
pub(all) struct WorldHistoryImportValidationRecordReport {
  index : Int
  label : String
  valid : Bool
  reason : String
  delta_count : Int
  deltas : Array[WorldHistoryImportValidationDeltaReport]
}

///|
/// Payload-free validation report for one imported history archive.
pub(all) struct WorldHistoryImportValidationReport {
  valid : Bool
  reason : String
  format_version : Int
  record_count : Int
  records : Array[WorldHistoryImportValidationRecordReport]
}

///|
/// Conversion result for one imported history delta.
priv struct WorldHistoryImportDeltaResult {
  delta : WorldDelta?
  diagnostic : String
}

///|
/// Conversion result for one imported history record.
priv struct WorldHistoryImportRecordResult {
  record : WorldHistoryRecord?
  diagnostic : String
  report : WorldHistoryImportValidationRecordReport
}

///|
/// Conversion result for one imported history stack in next-operation-first order.
priv struct WorldHistoryImportStackResult {
  records : Array[WorldHistoryRecord]
  diagnostic : String
  ok : Bool
  report : WorldHistoryImportValidationReport
}

///|
/// Whether applying stack limits dropped at least one retained record.
priv struct HistoryTrimResult {
  record_limit : Bool
  byte_limit : Bool
}

///|
/// Optional tracked transaction layer for reversible [`World`] mutations.
pub struct WorldHistory {
  priv mut enabled : Bool
  priv mut max_undo_records : Int
  priv mut max_undo_bytes : Int
  priv mut open : Bool
  priv mut applying : Bool
  priv mut current_label : String
  priv mut current_deltas : Array[WorldDelta]
  priv current_component_delta_index : @hashmap.HashMap[
    HistoryComponentDeltaIndexKey,
    Int,
  ]
  priv current_camera_delta_index : @hashmap.HashMap[
    HistoryEntityDeltaIndexKey,
    Int,
  ]
  priv current_global_transform_delta_index : @hashmap.HashMap[
    HistoryEntityDeltaIndexKey,
    Int,
  ]
  priv undo_stack : Array[WorldHistoryRecord]
  priv redo_stack : Array[WorldHistoryRecord]
  priv mut raw_mutation_guard_enabled : Bool
  priv mut guarded_world : World?
  priv mut last_diagnostic : String
}

///|
/// Default maximum number of committed undo records retained by a new history.
fn default_max_undo_records() -> Int {
  100
}

///|
/// Default payload byte budget for a new history; zero means unlimited.
fn default_max_undo_bytes() -> Int {
  0
}

///|
/// Diagnostic code for normal history operation results.
fn history_diagnostic_none() -> String {
  "none"
}

///|
/// Diagnostic reason used when retained history can be serialized.
fn history_serialization_reason_none() -> String {
  "none"
}

///|
/// Diagnostic reason used when a retained component id is not registered.
fn history_serialization_reason_unknown_component() -> String {
  "unknown_component"
}

///|
/// Diagnostic reason used when a user component has no stable serialization key.
fn history_serialization_reason_missing_stable_component_identity() -> String {
  "missing_stable_component_identity"
}

///|
/// Diagnostic code used when a history archive declares an unsupported format.
fn history_import_diagnostic_unsupported_format() -> String {
  "import_unsupported_format"
}

///|
/// Diagnostic code used when a history archive has an invalid shape.
fn history_import_diagnostic_invalid_archive() -> String {
  "import_invalid_archive"
}

///|
/// Diagnostic code used when a history archive cannot resolve stable component identity.
fn history_import_diagnostic_identity_mismatch() -> String {
  "import_identity_mismatch"
}

///|
/// Diagnostic code used when a history archive contains invalid payload bytes.
fn history_import_diagnostic_invalid_payload() -> String {
  "import_invalid_payload"
}

///|
/// Diagnostic code used when imported records cannot apply to the current world state.
fn history_import_diagnostic_validation_failed() -> String {
  "import_validation_failed"
}

///|
/// Current draft in-memory history export format version.
fn world_history_export_format_version() -> Int {
  1
}

///|
/// Converts a stack-trim result to the public diagnostic code.
fn history_trim_result_diagnostic(result : HistoryTrimResult) -> String {
  if result.record_limit && result.byte_limit {
    "stack_trimmed_limits"
  } else if result.record_limit {
    "stack_trimmed_record_limit"
  } else if result.byte_limit {
    "stack_trimmed_byte_limit"
  } else {
    history_diagnostic_none()
  }
}

///|
/// Returns the captured payload byte count for one entity snapshot.
fn entity_snapshot_payload_bytes(snapshot : EntitySnapshot) -> Int {
  let mut total = 0
  for i = 0; i < snapshot.components.length(); i = i + 1 {
    total = total + snapshot.components[i].bytes.length()
  }
  total
}

///|
/// Copies retained payload bytes so export objects do not alias history internals.
fn world_history_copy_bytes(bytes : FixedArray[Byte]) -> FixedArray[Byte] {
  let out = FixedArray::make(bytes.length(), (0 : Byte))
  for i = 0; i < bytes.length(); i = i + 1 {
    out[i] = bytes[i]
  }
  out
}

///|
/// Converts a GlobalTransform GPU row format to the export wire code.
fn world_history_global_transform_export_format_code(
  format : @comp.GlobalTransformGpuFormat,
) -> Int {
  match @comp.global_transform_format_code(format) {
    1U => 1
    _ => 0
  }
}

///|
/// Returns the captured payload byte count for one delta.
fn world_delta_payload_bytes(delta : WorldDelta) -> Int {
  match delta {
    EntityCreated(_) => 0
    EntityDestroyed(snapshot) => entity_snapshot_payload_bytes(snapshot)
    ComponentAdded(_, _, bytes) => bytes.length()
    ComponentRemoved(_, _, bytes) => bytes.length()
    ComponentChanged(_, _, before, after) => before.length() + after.length()
    GlobalTransformChanged(_, before, after) =>
      match before {
        Some(row) => row.bytes.length() + after.bytes.length()
        None => after.bytes.length()
      }
    CameraChanged(_, before, after) =>
      match before {
        Some(bytes) => bytes.length() + after.length()
        None => after.length()
      }
  }
}

///|
/// Returns the captured payload byte count for one committed history record.
fn world_history_record_payload_bytes(record : WorldHistoryRecord) -> Int {
  let mut total = 0
  for i = 0; i < record.deltas.length(); i = i + 1 {
    total = total + world_delta_payload_bytes(record.deltas[i])
  }
  total
}

///|
/// Returns the captured payload byte count for a history stack.
fn world_history_stack_payload_bytes(
  records : Array[WorldHistoryRecord],
) -> Int {
  let mut total = 0
  for i = 0; i < records.length(); i = i + 1 {
    total = total + world_history_record_payload_bytes(records[i])
  }
  total
}

///|
/// Returns a stable public diagnostic kind string for one delta.
fn world_delta_summary_kind(delta : WorldDelta) -> String {
  match delta {
    EntityCreated(_) => "entity_created"
    EntityDestroyed(_) => "entity_destroyed"
    ComponentAdded(_, _, _) => "component_added"
    ComponentRemoved(_, _, _) => "component_removed"
    ComponentChanged(_, _, _, _) => "component_changed"
    GlobalTransformChanged(_, _, _) => "global_transform_changed"
    CameraChanged(_, _, _) => "camera_changed"
  }
}

///|
/// Converts one internal delta to a payload-free public diagnostic summary.
fn world_delta_summary(delta : WorldDelta) -> WorldHistoryDeltaSummary {
  match delta {
    EntityCreated(entity) =>
      {
        kind: world_delta_summary_kind(delta),
        entity: Some(entity),
        component: None,
        component_count: 0,
        payload_bytes: 0,
        before_present: false,
        after_present: true,
      }
    EntityDestroyed(snapshot) =>
      {
        kind: world_delta_summary_kind(delta),
        entity: Some(snapshot.entity),
        component: None,
        component_count: snapshot.components.length(),
        payload_bytes: world_delta_payload_bytes(delta),
        before_present: true,
        after_present: false,
      }
    ComponentAdded(entity, component, bytes) =>
      {
        kind: world_delta_summary_kind(delta),
        entity: Some(entity),
        component: Some(component),
        component_count: 0,
        payload_bytes: bytes.length(),
        before_present: false,
        after_present: true,
      }
    ComponentRemoved(entity, component, bytes) =>
      {
        kind: world_delta_summary_kind(delta),
        entity: Some(entity),
        component: Some(component),
        component_count: 0,
        payload_bytes: bytes.length(),
        before_present: true,
        after_present: false,
      }
    ComponentChanged(entity, component, before, after) =>
      {
        kind: world_delta_summary_kind(delta),
        entity: Some(entity),
        component: Some(component),
        component_count: 0,
        payload_bytes: before.length() + after.length(),
        before_present: true,
        after_present: true,
      }
    GlobalTransformChanged(entity, before, _) =>
      {
        kind: world_delta_summary_kind(delta),
        entity: Some(entity),
        component: None,
        component_count: 0,
        payload_bytes: world_delta_payload_bytes(delta),
        before_present: before is Some(_),
        after_present: true,
      }
    CameraChanged(entity, before, _) =>
      {
        kind: world_delta_summary_kind(delta),
        entity: Some(entity),
        component: None,
        component_count: 0,
        payload_bytes: world_delta_payload_bytes(delta),
        before_present: before is Some(_),
        after_present: true,
      }
  }
}

///|
/// Converts one retained history record to a payload-free public summary.
fn world_history_record_summary(
  record : WorldHistoryRecord,
) -> WorldHistoryRecordSummary {
  let deltas : Array[WorldHistoryDeltaSummary] = []
  for i = 0; i < record.deltas.length(); i = i + 1 {
    deltas.push(world_delta_summary(record.deltas[i]))
  }
  {
    label: record.label,
    delta_count: record.deltas.length(),
    payload_bytes: world_history_record_payload_bytes(record),
    deltas,
  }
}

///|
/// Converts a history stack to summaries with the next operation first.
fn world_history_stack_summary_next_first(
  records : Array[WorldHistoryRecord],
) -> Array[WorldHistoryRecordSummary] {
  let summaries : Array[WorldHistoryRecordSummary] = []
  for i = records.length() - 1; i >= 0; i = i - 1 {
    summaries.push(world_history_record_summary(records[i]))
  }
  summaries
}

///|
/// Returns the stable serialization name for builtin ECS components.
fn world_history_builtin_component_stable_key(
  world : World,
  component : ComponentTypeId,
) -> String? {
  if component == world.transform_component() {
    Some("Transform3D")
  } else if component == world.child_of_component() {
    Some("ChildOf")
  } else if component == world.global_transform_component() {
    Some("GlobalTransform")
  } else if component == world.camera_component() {
    Some("Camera")
  } else if component == world.orbit_camera_controller_component() {
    Some("OrbitCameraController")
  } else if component == world.camera_home_transform_component() {
    Some("CameraHomeTransform")
  } else if component == world.camera_lens_component() {
    Some("CameraLens")
  } else {
    None
  }
}

///|
/// Reports whether one component dependency is eligible for future history serialization.
fn world_history_component_serialization_report(
  world : World,
  component : ComponentTypeId,
) -> WorldHistorySerializationComponentReport {
  match world_history_builtin_component_stable_key(world, component) {
    Some(stable_key) =>
      {
        component,
        serializable: true,
        reason: history_serialization_reason_none(),
        stable_key: Some(stable_key),
      }
    None =>
      match world.component_info(component) {
        Some(info) =>
          match info.stable_key {
            Some(stable_key) =>
              {
                component,
                serializable: true,
                reason: history_serialization_reason_none(),
                stable_key: Some(stable_key),
              }
            None =>
              {
                component,
                serializable: false,
                reason: history_serialization_reason_missing_stable_component_identity(),
                stable_key: None,
              }
          }
        None =>
          {
            component,
            serializable: false,
            reason: history_serialization_reason_unknown_component(),
            stable_key: None,
          }
      }
  }
}

///|
/// Returns the first non-serializable component report reason, or `none`.
fn world_history_component_reports_reason(
  components : Array[WorldHistorySerializationComponentReport],
) -> String {
  for i = 0; i < components.length(); i = i + 1 {
    if !components[i].serializable {
      return components[i].reason
    }
  }
  history_serialization_reason_none()
}

///|
/// Returns true when every component report is serializable.
fn world_history_component_reports_serializable(
  components : Array[WorldHistorySerializationComponentReport],
) -> Bool {
  for i = 0; i < components.length(); i = i + 1 {
    if !components[i].serializable {
      return false
    }
  }
  true
}

///|
/// Builds a serialization report for a logical delta that does not depend on user component identity.
fn world_history_serializable_delta_report(
  delta : WorldDelta,
  entity : EntityId?,
  component : ComponentTypeId?,
  component_count : Int,
) -> WorldHistorySerializationDeltaReport {
  {
    kind: world_delta_summary_kind(delta),
    entity,
    component,
    component_count,
    serializable: true,
    reason: history_serialization_reason_none(),
    payload_bytes: world_delta_payload_bytes(delta),
    components: [],
  }
}

///|
/// Builds a serialization report for a generic component delta.
fn world_history_component_delta_serialization_report(
  world : World,
  delta : WorldDelta,
  entity : EntityId,
  component : ComponentTypeId,
) -> WorldHistorySerializationDeltaReport {
  let component_report = world_history_component_serialization_report(
    world, component,
  )
  let components = [component_report]
  let serializable = component_report.serializable
  {
    kind: world_delta_summary_kind(delta),
    entity: Some(entity),
    component: Some(component),
    component_count: 0,
    serializable,
    reason: if serializable {
      history_serialization_reason_none()
    } else {
      component_report.reason
    },
    payload_bytes: world_delta_payload_bytes(delta),
    components,
  }
}

///|
/// Builds a serialization report for one delta.
fn world_delta_serialization_report(
  world : World,
  delta : WorldDelta,
) -> WorldHistorySerializationDeltaReport {
  match delta {
    EntityCreated(entity) =>
      world_history_serializable_delta_report(delta, Some(entity), None, 0)
    EntityDestroyed(snapshot) => {
      let components : Array[WorldHistorySerializationComponentReport] = []
      for i = 0; i < snapshot.components.length(); i = i + 1 {
        components.push(
          world_history_component_serialization_report(
            world,
            snapshot.components[i].component,
          ),
        )
      }
      let serializable = world_history_component_reports_serializable(
        components,
      )
      {
        kind: world_delta_summary_kind(delta),
        entity: Some(snapshot.entity),
        component: None,
        component_count: snapshot.components.length(),
        serializable,
        reason: if serializable {
          history_serialization_reason_none()
        } else {
          world_history_component_reports_reason(components)
        },
        payload_bytes: world_delta_payload_bytes(delta),
        components,
      }
    }
    ComponentAdded(entity, component, _) =>
      world_history_component_delta_serialization_report(
        world, delta, entity, component,
      )
    ComponentRemoved(entity, component, _) =>
      world_history_component_delta_serialization_report(
        world, delta, entity, component,
      )
    ComponentChanged(entity, component, _, _) =>
      world_history_component_delta_serialization_report(
        world, delta, entity, component,
      )
    GlobalTransformChanged(entity, _, _) =>
      world_history_serializable_delta_report(delta, Some(entity), None, 0)
    CameraChanged(entity, _, _) =>
      world_history_serializable_delta_report(delta, Some(entity), None, 0)
  }
}

///|
/// Returns the first non-serializable delta report reason, or `none`.
fn world_history_delta_reports_reason(
  deltas : Array[WorldHistorySerializationDeltaReport],
) -> String {
  for i = 0; i < deltas.length(); i = i + 1 {
    if !deltas[i].serializable {
      return deltas[i].reason
    }
  }
  history_serialization_reason_none()
}

///|
/// Returns true when every delta report is serializable.
fn world_history_delta_reports_serializable(
  deltas : Array[WorldHistorySerializationDeltaReport],
) -> Bool {
  for i = 0; i < deltas.length(); i = i + 1 {
    if !deltas[i].serializable {
      return false
    }
  }
  true
}

///|
/// Builds a serialization eligibility report for one history record.
fn world_history_record_serialization_report(
  world : World,
  record : WorldHistoryRecord,
) -> WorldHistorySerializationRecordReport {
  let deltas : Array[WorldHistorySerializationDeltaReport] = []
  for i = 0; i < record.deltas.length(); i = i + 1 {
    deltas.push(world_delta_serialization_report(world, record.deltas[i]))
  }
  let serializable = world_history_delta_reports_serializable(deltas)
  {
    label: record.label,
    serializable,
    reason: if serializable {
      history_serialization_reason_none()
    } else {
      world_history_delta_reports_reason(deltas)
    },
    delta_count: record.deltas.length(),
    payload_bytes: world_history_record_payload_bytes(record),
    deltas,
  }
}

///|
/// Returns true when every record report is serializable.
fn world_history_record_reports_serializable(
  records : Array[WorldHistorySerializationRecordReport],
) -> Bool {
  for i = 0; i < records.length(); i = i + 1 {
    if !records[i].serializable {
      return false
    }
  }
  true
}

///|
/// Builds a serialization eligibility report for a stack, next operation first.
fn world_history_stack_serialization_report_next_first(
  world : World,
  stack : Array[WorldHistoryRecord],
) -> WorldHistorySerializationReport {
  let records : Array[WorldHistorySerializationRecordReport] = []
  for i = stack.length() - 1; i >= 0; i = i - 1 {
    records.push(world_history_record_serialization_report(world, stack[i]))
  }
  {
    serializable: world_history_record_reports_serializable(records),
    record_count: stack.length(),
    records,
  }
}

///|
/// Resolves stable component identity metadata for exported history payloads.
fn world_history_export_component_identity(
  world : World,
  component : ComponentTypeId,
) -> WorldHistoryExportComponentIdentity? {
  match world_history_builtin_component_stable_key(world, component) {
    Some(key) =>
      Some({
        local_component: component,
        key,
        builtin: true,
        schema_version: None,
        schema_hash: None,
      })
    None =>
      match world.component_info(component) {
        Some(info) =>
          match info.stable_key {
            Some(key) =>
              Some({
                local_component: component,
                key,
                builtin: false,
                schema_version: info.schema_version,
                schema_hash: info.schema_hash,
              })
            None => None
          }
        None => None
      }
  }
}

///|
/// Builds an exported payload with a defensive copy of retained bytes.
fn world_history_export_payload(
  bytes : FixedArray[Byte],
  global_transform_format : Int?,
) -> WorldHistoryExportPayload {
  { global_transform_format, bytes: world_history_copy_bytes(bytes) }
}

///|
/// Builds an exported GlobalTransform row payload with its format code.
fn world_history_export_global_transform_payload(
  row : GlobalTransformHistoryRow,
) -> WorldHistoryExportPayload {
  world_history_export_payload(
    row.bytes,
    Some(world_history_global_transform_export_format_code(row.format)),
  )
}
