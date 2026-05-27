/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Builds a system that writes Camera blob rows from GlobalTransform and CameraLens.
pub fn camera_blob_sync_system(
  world : World,
  phase : PhaseKey,
  lens_component : ComponentTypeId,
) -> System {
  let gt = world.global_transform_component()
  let camera = world.camera_component()
  System::new_direct(
    "rhodonite/camera_blob_sync",
    phase,
    [gt, lens_component],
    [camera],
    fn(world, _ctx) {
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
                  ignore(
                    world.set_camera_matrices(
                      entity, view, proj, near, far, aspect, projection_kind, flags,
                    ),
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
  System::new_direct(
    "rhodonite/orbit_camera_blob_sync",
    phase,
    [gt, lens_component, orbit_component],
    [camera],
    fn(world, _ctx) {
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
                      ignore(
                        world.set_camera_matrices(
                          entity, view, proj, near, far, aspect, projection_kind,
                          flags,
                        ),
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
