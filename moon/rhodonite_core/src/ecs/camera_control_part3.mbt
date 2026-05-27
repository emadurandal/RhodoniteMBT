/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Returns the dirty queue size where full raw scans are cheaper than per-entity lookup.
fn camera_blob_sync_full_scan_threshold() -> Int {
  128
}

///|
/// Syncs one dirty camera entity from GlobalTransform and CameraLens when all required rows exist.
fn sync_dirty_camera_blob_entity(
  world : World,
  entity : EntityId,
  lens_component : ComponentTypeId,
) -> Unit {
  if !world.has_component(entity, world.camera_component()) ||
    !world.has_component(entity, lens_component) {
    return
  }
  match world.get_global_transform(entity) {
    Some(global) =>
      match global.inverse() {
        Some(view) =>
          match world.component_bytes(entity, lens_component) {
            Some(lens_row) => {
              let (proj, near, far, aspect, projection_kind, flags) = camera_lens_projection_from_view(
                lens_row[:],
              )
              ignore(
                world.set_camera_matrices(
                  entity, view, proj, near, far, aspect, projection_kind, flags,
                ),
              )
            }
            None => ()
          }
        None => ()
      }
    None => ()
  }
}

///|
/// Syncs all Camera rows through a cached raw archetype scan for dense dirty frames.
fn sync_all_camera_blob_entities(
  world : World,
  cache : RawQueryCache,
  lens_index : Int,
) -> Unit {
  cache.for_each_archetype(world, arch => {
    let lens_stride = arch.component_stride_at(lens_index)
    let lens_col = arch.read_column_at(lens_index)
    for row = 0; row < arch.length(); row = row + 1 {
      let entity = arch.entity(row)
      match world.get_global_transform(entity) {
        Some(global) =>
          match global.inverse() {
            Some(view) => {
              let lens_start = row * lens_stride
              let lens_row = lens_col[lens_start:lens_start + lens_stride]
              let (proj, near, far, aspect, projection_kind, flags) = camera_lens_projection_from_view(
                lens_row,
              )
              ignore(
                world.set_camera_matrices(
                  entity, view, proj, near, far, aspect, projection_kind, flags,
                ),
              )
            }
            None => ()
          }
        None => ()
      }
    }
  })
}

///|
/// Syncs one dirty orbit camera entity, applying orbit dolly to orthographic lens rows.
fn sync_dirty_orbit_camera_blob_entity(
  world : World,
  entity : EntityId,
  orbit_component : ComponentTypeId,
  lens_component : ComponentTypeId,
) -> Unit {
  if !world.has_component(entity, world.camera_component()) ||
    !world.has_component(entity, orbit_component) ||
    !world.has_component(entity, lens_component) {
    return
  }
  match world.get_global_transform(entity) {
    Some(global) =>
      match global.inverse() {
        Some(view) => {
          let orbit_row = match world.component_bytes(entity, orbit_component) {
            Some(bytes) => bytes
            None => return
          }
          let lens_row = match world.component_bytes(entity, lens_component) {
            Some(bytes) => bytes
            None => return
          }
          let (_yaw, _pitch, _pan_x, _pan_y, dolly, _distance, _requested) = orbit_camera_pose_from_controller_view(
            orbit_row[:],
          )
          let (proj, near, far, aspect, projection_kind, flags) = camera_lens_projection_from_view_with_ortho_scale(
            lens_row[:],
            dolly,
          )
          ignore(
            world.set_camera_matrices(
              entity, view, proj, near, far, aspect, projection_kind, flags,
            ),
          )
        }
        None => ()
      }
    None => ()
  }
}

///|
/// Syncs all orbit Camera rows through a cached raw archetype scan for dense dirty frames.
fn sync_all_orbit_camera_blob_entities(
  world : World,
  cache : RawQueryCache,
  orbit_index : Int,
  lens_index : Int,
) -> Unit {
  cache.for_each_archetype(world, arch => {
    let orbit_stride = arch.component_stride_at(orbit_index)
    let lens_stride = arch.component_stride_at(lens_index)
    let orbit_col = arch.read_column_at(orbit_index)
    let lens_col = arch.read_column_at(lens_index)
    for row = 0; row < arch.length(); row = row + 1 {
      let entity = arch.entity(row)
      match world.get_global_transform(entity) {
        Some(global) =>
          match global.inverse() {
            Some(view) => {
              let orbit_start = row * orbit_stride
              let lens_start = row * lens_stride
              let orbit_row = orbit_col[orbit_start:orbit_start + orbit_stride]
              let lens_row = lens_col[lens_start:lens_start + lens_stride]
              let (_yaw, _pitch, _pan_x, _pan_y, dolly, _distance, _requested) = orbit_camera_pose_from_controller_view(
                orbit_row,
              )
              let (proj, near, far, aspect, projection_kind, flags) = camera_lens_projection_from_view_with_ortho_scale(
                lens_row, dolly,
              )
              ignore(
                world.set_camera_matrices(
                  entity, view, proj, near, far, aspect, projection_kind, flags,
                ),
              )
            }
            None => ()
          }
        None => ()
      }
    }
  })
}

///|
/// Builds a system that writes Camera blob rows from GlobalTransform and CameraLens.
pub fn camera_blob_sync_system(
  world : World,
  phase : PhaseKey,
  lens_component : ComponentTypeId,
) -> System {
  let gt = world.global_transform_component()
  let camera = world.camera_component()
  let cache = RawQueryCache::new([gt, camera, lens_component])
  let lens_index = cache.component_index(lens_component)
  System::new_direct(
    "rhodonite/camera_blob_sync",
    phase,
    [gt, lens_component],
    [camera],
    fn(world, _ctx) {
      let dirty = world.drain_camera_blob_sync_dirty_entities()
      if dirty.length() > camera_blob_sync_full_scan_threshold() {
        sync_all_camera_blob_entities(world, cache, lens_index)
      } else {
        for i = 0; i < dirty.length(); i = i + 1 {
          sync_dirty_camera_blob_entity(world, dirty[i], lens_component)
        }
      }
    },
  )
}

///|
/// Builds a command-buffer system that queues Camera blob writes from GlobalTransform and CameraLens.
pub fn camera_blob_sync_command_system(
  world : World,
  phase : PhaseKey,
  lens_component : ComponentTypeId,
) -> System {
  let gt = world.global_transform_component()
  let camera = world.camera_component()
  System::new(
    "rhodonite/camera_blob_sync_command",
    phase,
    [gt, lens_component],
    [camera],
    fn(world, _ctx, commands) {
      Query::new([gt, camera, lens_component]).for_each(world, row => {
        let entity = row.entity()
        match world.get_global_transform(entity) {
          Some(global) =>
            match global.inverse() {
              Some(view) =>
                row.read(lens_component, lens_row => {
                  let (proj, near, far, aspect, projection_kind, flags) = camera_lens_projection_from_view(
                    lens_row,
                  )
                  commands.set_camera_matrices(
                    entity, view, proj, near, far, aspect, projection_kind, flags,
                  )
                })
              None => ()
            }
          None => ()
        }
      })
    },
  )
}

///|
/// Builds a system that writes Camera blob rows from GlobalTransform, CameraLens, and orbit dolly.
pub fn orbit_camera_blob_sync_system(
  world : World,
  phase : PhaseKey,
  orbit_component : ComponentTypeId,
  lens_component : ComponentTypeId,
) -> System {
  let gt = world.global_transform_component()
  let camera = world.camera_component()
  let cache = RawQueryCache::new([gt, camera, lens_component, orbit_component])
  let orbit_index = cache.component_index(orbit_component)
  let lens_index = cache.component_index(lens_component)
  System::new_direct(
    "rhodonite/orbit_camera_blob_sync",
    phase,
    [gt, lens_component, orbit_component],
    [camera],
    fn(world, _ctx) {
      let dirty = world.drain_camera_blob_sync_dirty_entities()
      if dirty.length() > camera_blob_sync_full_scan_threshold() {
        sync_all_orbit_camera_blob_entities(
          world, cache, orbit_index, lens_index,
        )
      } else {
        for i = 0; i < dirty.length(); i = i + 1 {
          sync_dirty_orbit_camera_blob_entity(
            world,
            dirty[i],
            orbit_component,
            lens_component,
          )
        }
      }
    },
  )
}

///|
/// Builds a command-buffer system that queues orbit Camera blob writes.
pub fn orbit_camera_blob_sync_command_system(
  world : World,
  phase : PhaseKey,
  orbit_component : ComponentTypeId,
  lens_component : ComponentTypeId,
) -> System {
  let gt = world.global_transform_component()
  let camera = world.camera_component()
  System::new(
    "rhodonite/orbit_camera_blob_sync_command",
    phase,
    [gt, lens_component, orbit_component],
    [camera],
    fn(world, _ctx, commands) {
      Query::new([gt, camera, lens_component, orbit_component]).for_each(
        world,
        row => {
          let entity = row.entity()
          match world.get_global_transform(entity) {
            Some(global) =>
              match global.inverse() {
                Some(view) =>
                  row.read(orbit_component, orbit_row => {
                    let (
                      _yaw,
                      _pitch,
                      _pan_x,
                      _pan_y,
                      dolly,
                      _distance,
                      _requested,
                    ) = orbit_camera_pose_from_controller_view(orbit_row)
                    row.read(lens_component, lens_row => {
                      let (proj, near, far, aspect, projection_kind, flags) = camera_lens_projection_from_view_with_ortho_scale(
                        lens_row, dolly,
                      )
                      commands.set_camera_matrices(
                        entity, view, proj, near, far, aspect, projection_kind, flags,
                      )
                    })
                  })
                None => ()
              }
            None => ()
          }
        },
      )
    },
  )
}
