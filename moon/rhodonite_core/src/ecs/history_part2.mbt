/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Builds an exported component snapshot for an entity-destroyed delta.
fn world_history_export_component_snapshot(
  world : World,
  snapshot : ComponentSnapshot,
) -> WorldHistoryExportComponentSnapshot? {
  match world_history_export_component_identity(world, snapshot.component) {
    Some(component) =>
      Some({ component, bytes: world_history_copy_bytes(snapshot.bytes) })
    None => None
  }
}

///|
/// Builds the exported snapshot list for an entity-destroyed delta.
fn world_history_export_component_snapshots(
  world : World,
  snapshots : Array[ComponentSnapshot],
) -> Array[WorldHistoryExportComponentSnapshot]? {
  let components : Array[WorldHistoryExportComponentSnapshot] = []
  for i = 0; i < snapshots.length(); i = i + 1 {
    match world_history_export_component_snapshot(world, snapshots[i]) {
      Some(snapshot) => components.push(snapshot)
      None => return None
    }
  }
  Some(components)
}

///|
/// Builds an exported delta after serialization eligibility has passed.
fn world_history_export_delta(
  world : World,
  delta : WorldDelta,
) -> WorldHistoryExportDelta? {
  match delta {
    EntityCreated(entity) =>
      Some({
        kind: world_delta_summary_kind(delta),
        entity: Some(entity),
        component: None,
        before: None,
        after: None,
        components: [],
      })
    EntityDestroyed(snapshot) =>
      match
        world_history_export_component_snapshots(world, snapshot.components) {
        Some(components) =>
          Some({
            kind: world_delta_summary_kind(delta),
            entity: Some(snapshot.entity),
            component: None,
            before: None,
            after: None,
            components,
          })
        None => None
      }
    ComponentAdded(entity, component, after_bytes) =>
      match world_history_export_component_identity(world, component) {
        Some(identity) =>
          Some({
            kind: world_delta_summary_kind(delta),
            entity: Some(entity),
            component: Some(identity),
            before: None,
            after: Some(world_history_export_payload(after_bytes, None)),
            components: [],
          })
        None => None
      }
    ComponentRemoved(entity, component, before_bytes) =>
      match world_history_export_component_identity(world, component) {
        Some(identity) =>
          Some({
            kind: world_delta_summary_kind(delta),
            entity: Some(entity),
            component: Some(identity),
            before: Some(world_history_export_payload(before_bytes, None)),
            after: None,
            components: [],
          })
        None => None
      }
    ComponentChanged(entity, component, before_bytes, after_bytes) =>
      match world_history_export_component_identity(world, component) {
        Some(identity) =>
          Some({
            kind: world_delta_summary_kind(delta),
            entity: Some(entity),
            component: Some(identity),
            before: Some(world_history_export_payload(before_bytes, None)),
            after: Some(world_history_export_payload(after_bytes, None)),
            components: [],
          })
        None => None
      }
    GlobalTransformChanged(entity, before_row, after_row) =>
      match
        world_history_export_component_identity(
          world,
          world.global_transform_component(),
        ) {
        Some(identity) =>
          Some({
            kind: world_delta_summary_kind(delta),
            entity: Some(entity),
            component: Some(identity),
            before: match before_row {
              Some(row) =>
                Some(world_history_export_global_transform_payload(row))
              None => None
            },
            after: Some(
              world_history_export_global_transform_payload(after_row),
            ),
            components: [],
          })
        None => None
      }
    CameraChanged(entity, before_bytes, after_bytes) =>
      match
        world_history_export_component_identity(world, world.camera_component()) {
        Some(identity) =>
          Some({
            kind: world_delta_summary_kind(delta),
            entity: Some(entity),
            component: Some(identity),
            before: match before_bytes {
              Some(bytes) => Some(world_history_export_payload(bytes, None))
              None => None
            },
            after: Some(world_history_export_payload(after_bytes, None)),
            components: [],
          })
        None => None
      }
  }
}

///|
/// Builds an exported history record after serialization eligibility has passed.
fn world_history_export_record(
  world : World,
  record : WorldHistoryRecord,
) -> WorldHistoryExportRecord? {
  let deltas : Array[WorldHistoryExportDelta] = []
  for i = 0; i < record.deltas.length(); i = i + 1 {
    match world_history_export_delta(world, record.deltas[i]) {
      Some(delta) => deltas.push(delta)
      None => return None
    }
  }
  Some({ label: record.label, delta_count: record.deltas.length(), deltas })
}

///|
/// Builds an in-memory draft export for a history stack, next operation first.
fn world_history_stack_export_next_first(
  world : World,
  stack : Array[WorldHistoryRecord],
) -> WorldHistoryExport? {
  if !world_history_stack_serialization_report_next_first(world, stack).serializable {
    return None
  }
  let records : Array[WorldHistoryExportRecord] = []
  for i = stack.length() - 1; i >= 0; i = i - 1 {
    match world_history_export_record(world, stack[i]) {
      Some(record) => records.push(record)
      None => return None
    }
  }
  Some({
    format_version: world_history_export_format_version(),
    record_count: stack.length(),
    records,
  })
}

///|
/// Resolves a builtin component stable key to the current world's component id.
fn world_history_builtin_component_by_stable_key(
  world : World,
  key : String,
) -> ComponentTypeId? {
  if key == "Transform3D" {
    Some(world.transform_component())
  } else if key == "ChildOf" {
    Some(world.child_of_component())
  } else if key == "GlobalTransform" {
    Some(world.global_transform_component())
  } else if key == "Camera" {
    Some(world.camera_component())
  } else if key == "OrbitCameraController" {
    Some(world.orbit_camera_controller_component())
  } else if key == "CameraHomeTransform" {
    Some(world.camera_home_transform_component())
  } else if key == "CameraLens" {
    Some(world.camera_lens_component())
  } else {
    None
  }
}

///|
/// Resolves an exported stable component identity against the current world.
fn world_history_import_component_identity(
  world : World,
  identity : WorldHistoryExportComponentIdentity,
) -> ComponentTypeId? {
  if identity.builtin {
    if identity.schema_version is Some(_) || identity.schema_hash is Some(_) {
      return None
    }
    world_history_builtin_component_by_stable_key(world, identity.key)
  } else {
    match world.component_by_stable_key(identity.key) {
      Some(component) =>
        if world.component_matches_identity(
            component,
            identity.key,
            identity.schema_version,
            identity.schema_hash,
          ) {
          Some(component)
        } else {
          None
        }
      None => None
    }
  }
}

///|
/// Returns whether an exported delta carries no entity-destroyed snapshots.
fn world_history_export_delta_components_empty(
  delta : WorldHistoryExportDelta,
) -> Bool {
  delta.components.length() == 0
}

///|
/// Returns whether an exported delta omits an optional component identity.
fn world_history_export_delta_component_absent(
  delta : WorldHistoryExportDelta,
) -> Bool {
  delta.component is None
}

///|
/// Returns whether an exported delta omits both before and after payloads.
fn world_history_export_delta_payloads_absent(
  delta : WorldHistoryExportDelta,
) -> Bool {
  delta.before is None && delta.after is None
}

///|
/// Copies a non-GlobalTransform payload, rejecting format metadata.
fn world_history_import_plain_payload(
  payload : WorldHistoryExportPayload,
) -> FixedArray[Byte]? {
  match payload.global_transform_format {
    Some(_) => None
    None => Some(world_history_copy_bytes(payload.bytes))
  }
}

///|
/// Converts an exported GlobalTransform payload into a history row.
fn world_history_import_global_transform_payload(
  payload : WorldHistoryExportPayload,
) -> GlobalTransformHistoryRow? {
  let format = match payload.global_transform_format {
    Some(0) => @comp.global_transform_format_from_code(0U)
    Some(1) => @comp.global_transform_format_from_code(1U)
    _ => return None
  }
  let row = { format, bytes: world_history_copy_bytes(payload.bytes) }
  if global_transform_history_row_valid(row) {
    Some(row)
  } else {
    None
  }
}

///|
/// Copies an exported Camera payload after validating its row shape.
fn world_history_import_camera_payload(
  payload : WorldHistoryExportPayload,
) -> FixedArray[Byte]? {
  match world_history_import_plain_payload(payload) {
    Some(bytes) =>
      if bytes.length() == @comp.camera_gpu_byte_stride() {
        Some(bytes)
      } else {
        None
      }
    None => None
  }
}

///|
/// Returns the optional stable component key carried by one exported delta.
fn world_history_export_delta_component_key(
  delta : WorldHistoryExportDelta,
) -> String? {
  match delta.component {
    Some(identity) => Some(identity.key)
    None => None
  }
}

///|
/// Returns the imported component id addressed by one converted delta.
fn world_history_imported_delta_component(
  world : World,
  delta : WorldDelta,
) -> ComponentTypeId? {
  match delta {
    EntityCreated(_) => None
    EntityDestroyed(_) => None
    ComponentAdded(_, component, _) => Some(component)
    ComponentRemoved(_, component, _) => Some(component)
    ComponentChanged(_, component, _, _) => Some(component)
    GlobalTransformChanged(_, _, _) => Some(world.global_transform_component())
    CameraChanged(_, _, _) => Some(world.camera_component())
  }
}

///|
/// Returns the resolved component id when an exported delta carries resolvable identity.
fn world_history_import_delta_report_component(
  world : World,
  exported : WorldHistoryExportDelta,
  result : WorldHistoryImportDeltaResult,
) -> ComponentTypeId? {
  match result.delta {
    Some(delta) => world_history_imported_delta_component(world, delta)
    None =>
      match exported.component {
        Some(identity) =>
          world_history_import_component_identity(world, identity)
        None => None
      }
  }
}

///|
/// Builds a payload-free validation report for one imported delta conversion.
fn world_history_import_delta_report(
  world : World,
  index : Int,
  exported : WorldHistoryExportDelta,
  result : WorldHistoryImportDeltaResult,
) -> WorldHistoryImportValidationDeltaReport {
  {
    index,
    kind: exported.kind,
    entity: exported.entity,
    component: world_history_import_delta_report_component(
      world, exported, result,
    ),
    component_key: world_history_export_delta_component_key(exported),
    valid: result.delta is Some(_),
    reason: result.diagnostic,
  }
}

///|
/// Builds an import validation delta report for a validation-stage failure.
fn world_history_import_validation_failed_delta_report(
  report : WorldHistoryImportValidationDeltaReport,
) -> WorldHistoryImportValidationDeltaReport {
  {
    index: report.index,
    kind: report.kind,
    entity: report.entity,
    component: report.component,
    component_key: report.component_key,
    valid: false,
    reason: history_import_diagnostic_validation_failed(),
  }
}

///|
/// Builds a failed import delta result.
fn world_history_import_delta_failure(
  diagnostic : String,
) -> WorldHistoryImportDeltaResult {
  { delta: None, diagnostic }
}

///|
/// Builds a successful import delta result.
fn world_history_import_delta_success(
  delta : WorldDelta,
) -> WorldHistoryImportDeltaResult {
  { delta: Some(delta), diagnostic: history_diagnostic_none() }
}

///|
/// Converts exported entity-destroyed component snapshots into an entity snapshot.
fn world_history_import_entity_snapshot(
  world : World,
  entity : EntityId,
  components : Array[WorldHistoryExportComponentSnapshot],
) -> WorldHistoryImportDeltaResult {
  let snapshots : Array[ComponentSnapshot] = []
  let component_ids : Array[ComponentTypeId] = []
  for i = 0; i < components.length(); i = i + 1 {
    let snapshot = components[i]
    let component = match
      world_history_import_component_identity(world, snapshot.component) {
      Some(component) => component
      None =>
        return world_history_import_delta_failure(
          history_import_diagnostic_identity_mismatch(),
        )
    }
    let bytes = world_history_copy_bytes(snapshot.bytes)
    if !world.history_component_stride_matches(component, bytes) {
      return world_history_import_delta_failure(
        history_import_diagnostic_invalid_payload(),
      )
    }
    component_ids.push(component)
    snapshots.push({ component, bytes })
  }
  if component_array_has_duplicates(component_ids) {
    return world_history_import_delta_failure(
      history_import_diagnostic_invalid_archive(),
    )
  }
  world_history_import_delta_success(
    EntityDestroyed({ entity, components: snapshots }),
  )
}

///|
/// Resolves the required component identity on an exported delta.
fn world_history_import_delta_component(
  world : World,
  delta : WorldHistoryExportDelta,
) -> (ComponentTypeId?, String) {
  match delta.component {
    Some(identity) =>
      match world_history_import_component_identity(world, identity) {
        Some(component) => (Some(component), history_diagnostic_none())
        None => (None, history_import_diagnostic_identity_mismatch())
      }
    None => (None, history_import_diagnostic_invalid_archive())
  }
}

///|
/// Imports a component-added delta.
fn world_history_import_component_added_delta(
  world : World,
  delta : WorldHistoryExportDelta,
  entity : EntityId,
) -> WorldHistoryImportDeltaResult {
  if delta.before is Some(_) ||
    !world_history_export_delta_components_empty(delta) {
    return world_history_import_delta_failure(
      history_import_diagnostic_invalid_archive(),
    )
  }
  let component = match world_history_import_delta_component(world, delta) {
    (Some(component), _) => component
    (None, diagnostic) => return world_history_import_delta_failure(diagnostic)
  }
  if world.history_blob_ref_component(component) {
    return world_history_import_delta_failure(
      history_import_diagnostic_invalid_archive(),
    )
  }
  let after = match delta.after {
    Some(payload) =>
      match world_history_import_plain_payload(payload) {
        Some(bytes) => bytes
        None =>
          return world_history_import_delta_failure(
            history_import_diagnostic_invalid_payload(),
          )
      }
    None =>
      return world_history_import_delta_failure(
        history_import_diagnostic_invalid_archive(),
      )
  }
  if !world.history_component_stride_matches(component, after) {
    return world_history_import_delta_failure(
      history_import_diagnostic_invalid_payload(),
    )
  }
  world_history_import_delta_success(ComponentAdded(entity, component, after))
}

///|
/// Imports a component-removed delta.
fn world_history_import_component_removed_delta(
  world : World,
  delta : WorldHistoryExportDelta,
  entity : EntityId,
) -> WorldHistoryImportDeltaResult {
  if delta.after is Some(_) ||
    !world_history_export_delta_components_empty(delta) {
    return world_history_import_delta_failure(
      history_import_diagnostic_invalid_archive(),
    )
  }
  let component = match world_history_import_delta_component(world, delta) {
    (Some(component), _) => component
    (None, diagnostic) => return world_history_import_delta_failure(diagnostic)
  }
  if world.history_blob_ref_component(component) {
    return world_history_import_delta_failure(
      history_import_diagnostic_invalid_archive(),
    )
  }
  let before = match delta.before {
    Some(payload) =>
      match world_history_import_plain_payload(payload) {
        Some(bytes) => bytes
        None =>
          return world_history_import_delta_failure(
            history_import_diagnostic_invalid_payload(),
          )
      }
    None =>
      return world_history_import_delta_failure(
        history_import_diagnostic_invalid_archive(),
      )
  }
  if !world.history_component_stride_matches(component, before) {
    return world_history_import_delta_failure(
      history_import_diagnostic_invalid_payload(),
    )
  }
  world_history_import_delta_success(
    ComponentRemoved(entity, component, before),
  )
}

///|
/// Imports a component-changed delta.
fn world_history_import_component_changed_delta(
  world : World,
  delta : WorldHistoryExportDelta,
  entity : EntityId,
) -> WorldHistoryImportDeltaResult {
  if !world_history_export_delta_components_empty(delta) {
    return world_history_import_delta_failure(
      history_import_diagnostic_invalid_archive(),
    )
  }
  let component = match world_history_import_delta_component(world, delta) {
    (Some(component), _) => component
    (None, diagnostic) => return world_history_import_delta_failure(diagnostic)
  }
  if world.history_blob_ref_component(component) {
    return world_history_import_delta_failure(
      history_import_diagnostic_invalid_archive(),
    )
  }
  let before = match delta.before {
    Some(payload) =>
      match world_history_import_plain_payload(payload) {
        Some(bytes) => bytes
        None =>
          return world_history_import_delta_failure(
            history_import_diagnostic_invalid_payload(),
          )
      }
    None =>
      return world_history_import_delta_failure(
        history_import_diagnostic_invalid_archive(),
      )
  }
  let after = match delta.after {
    Some(payload) =>
      match world_history_import_plain_payload(payload) {
        Some(bytes) => bytes
        None =>
          return world_history_import_delta_failure(
            history_import_diagnostic_invalid_payload(),
          )
      }
    None =>
      return world_history_import_delta_failure(
        history_import_diagnostic_invalid_archive(),
      )
  }
  if !world.history_component_stride_matches(component, before) ||
    !world.history_component_stride_matches(component, after) {
    return world_history_import_delta_failure(
      history_import_diagnostic_invalid_payload(),
    )
  }
  world_history_import_delta_success(
    ComponentChanged(entity, component, before, after),
  )
}

///|
/// Imports a GlobalTransform changed delta.
fn world_history_import_global_transform_delta(
  world : World,
  delta : WorldHistoryExportDelta,
  entity : EntityId,
) -> WorldHistoryImportDeltaResult {
  if !world_history_export_delta_components_empty(delta) {
    return world_history_import_delta_failure(
      history_import_diagnostic_invalid_archive(),
    )
  }
  let component = match world_history_import_delta_component(world, delta) {
    (Some(component), _) => component
    (None, diagnostic) => return world_history_import_delta_failure(diagnostic)
  }
  if component != world.global_transform_component() {
    return world_history_import_delta_failure(
      history_import_diagnostic_identity_mismatch(),
    )
  }
  let before = match delta.before {
    Some(payload) =>
      match world_history_import_global_transform_payload(payload) {
        Some(row) => Some(row)
        None =>
          return world_history_import_delta_failure(
            history_import_diagnostic_invalid_payload(),
          )
      }
    None => None
  }
  let after = match delta.after {
    Some(payload) =>
      match world_history_import_global_transform_payload(payload) {
        Some(row) => row
        None =>
          return world_history_import_delta_failure(
            history_import_diagnostic_invalid_payload(),
          )
      }
    None =>
      return world_history_import_delta_failure(
        history_import_diagnostic_invalid_archive(),
      )
  }
  world_history_import_delta_success(
    GlobalTransformChanged(entity, before, after),
  )
}

///|
/// Imports a Camera changed delta.
fn world_history_import_camera_delta(
  world : World,
  delta : WorldHistoryExportDelta,
  entity : EntityId,
) -> WorldHistoryImportDeltaResult {
  if !world_history_export_delta_components_empty(delta) {
    return world_history_import_delta_failure(
      history_import_diagnostic_invalid_archive(),
    )
  }
  let component = match world_history_import_delta_component(world, delta) {
    (Some(component), _) => component
    (None, diagnostic) => return world_history_import_delta_failure(diagnostic)
  }
  if component != world.camera_component() {
    return world_history_import_delta_failure(
      history_import_diagnostic_identity_mismatch(),
    )
  }
  let before = match delta.before {
    Some(payload) =>
      match world_history_import_camera_payload(payload) {
        Some(bytes) => Some(bytes)
        None =>
          return world_history_import_delta_failure(
            history_import_diagnostic_invalid_payload(),
          )
      }
    None => None
  }
  let after = match delta.after {
    Some(payload) =>
      match world_history_import_camera_payload(payload) {
        Some(bytes) => bytes
        None =>
          return world_history_import_delta_failure(
            history_import_diagnostic_invalid_payload(),
          )
      }
    None =>
      return world_history_import_delta_failure(
        history_import_diagnostic_invalid_archive(),
      )
  }
  world_history_import_delta_success(CameraChanged(entity, before, after))
}

///|
/// Converts an exported delta into the internal reversible representation.
fn world_history_import_delta(
  world : World,
  delta : WorldHistoryExportDelta,
) -> WorldHistoryImportDeltaResult {
  let entity = match delta.entity {
    Some(entity) => entity
    None =>
      return world_history_import_delta_failure(
        history_import_diagnostic_invalid_archive(),
      )
  }
  match delta.kind {
    "entity_created" =>
      if world_history_export_delta_component_absent(delta) &&
        world_history_export_delta_payloads_absent(delta) &&
        world_history_export_delta_components_empty(delta) {
        world_history_import_delta_success(EntityCreated(entity))
      } else {
        world_history_import_delta_failure(
          history_import_diagnostic_invalid_archive(),
        )
      }
    "entity_destroyed" =>
      if world_history_export_delta_component_absent(delta) &&
        world_history_export_delta_payloads_absent(delta) {
        world_history_import_entity_snapshot(world, entity, delta.components)
      } else {
        world_history_import_delta_failure(
          history_import_diagnostic_invalid_archive(),
        )
      }
    "component_added" =>
      world_history_import_component_added_delta(world, delta, entity)
    "component_removed" =>
      world_history_import_component_removed_delta(world, delta, entity)
    "component_changed" =>
      world_history_import_component_changed_delta(world, delta, entity)
    "global_transform_changed" =>
      world_history_import_global_transform_delta(world, delta, entity)
    "camera_changed" => world_history_import_camera_delta(world, delta, entity)
    _ =>
      world_history_import_delta_failure(
        history_import_diagnostic_invalid_archive(),
      )
  }
}

///|
/// Builds a failed import record result.
fn world_history_import_record_failure(
  index : Int,
  record : WorldHistoryExportRecord,
  diagnostic : String,
  deltas : Array[WorldHistoryImportValidationDeltaReport],
) -> WorldHistoryImportRecordResult {
  {
    record: None,
    diagnostic,
    report: {
      index,
      label: record.label,
      valid: false,
      reason: diagnostic,
      delta_count: record.delta_count,
      deltas,
    },
  }
}

///|
/// Converts an exported record into the internal history record shape.
fn world_history_import_record(
  world : World,
  index : Int,
  record : WorldHistoryExportRecord,
) -> WorldHistoryImportRecordResult {
  let delta_reports : Array[WorldHistoryImportValidationDeltaReport] = []
  if record.delta_count != record.deltas.length() {
    return world_history_import_record_failure(
      index,
      record,
      history_import_diagnostic_invalid_archive(),
      delta_reports,
    )
  }
  let deltas : Array[WorldDelta] = []
  for i = 0; i < record.deltas.length(); i = i + 1 {
    let result = world_history_import_delta(world, record.deltas[i])
    delta_reports.push(
      world_history_import_delta_report(world, i, record.deltas[i], result),
    )
    match result {
      { delta: Some(delta), .. } => deltas.push(delta)
      { diagnostic, .. } =>
        return world_history_import_record_failure(
          index, record, diagnostic, delta_reports,
        )
    }
  }
  {
    record: Some({ label: record.label, deltas }),
    diagnostic: history_diagnostic_none(),
    report: {
      index,
      label: record.label,
      valid: true,
      reason: history_diagnostic_none(),
      delta_count: record.delta_count,
      deltas: delta_reports,
    },
  }
}

///|
/// Builds a failed import stack result.
fn world_history_import_stack_failure(
  archive : WorldHistoryExport,
  diagnostic : String,
  records : Array[WorldHistoryImportValidationRecordReport],
) -> WorldHistoryImportStackResult {
  {
    records: [],
    diagnostic,
    ok: false,
    report: {
      valid: false,
      reason: diagnostic,
      format_version: archive.format_version,
      record_count: archive.record_count,
      records,
    },
  }
}

///|
/// Converts an exported stack into internal records in next-operation-first order.
fn world_history_import_stack_records(
  world : World,
  archive : WorldHistoryExport,
) -> WorldHistoryImportStackResult {
  let record_reports : Array[WorldHistoryImportValidationRecordReport] = []
  if archive.format_version != world_history_export_format_version() {
    return world_history_import_stack_failure(
      archive,
      history_import_diagnostic_unsupported_format(),
      record_reports,
    )
  }
  if archive.record_count != archive.records.length() {
    return world_history_import_stack_failure(
      archive,
      history_import_diagnostic_invalid_archive(),
      record_reports,
    )
  }
  let records : Array[WorldHistoryRecord] = []
  for i = 0; i < archive.records.length(); i = i + 1 {
    match world_history_import_record(world, i, archive.records[i]) {
      { record: Some(record), report, .. } => {
        records.push(record)
        record_reports.push(report)
      }
      { diagnostic, report, .. } => {
        record_reports.push(report)
        return world_history_import_stack_failure(
          archive, diagnostic, record_reports,
        )
      }
    }
  }
  {
    records,
    diagnostic: history_diagnostic_none(),
    ok: true,
    report: {
      valid: true,
      reason: history_diagnostic_none(),
      format_version: archive.format_version,
      record_count: archive.record_count,
      records: record_reports,
    },
  }
}
