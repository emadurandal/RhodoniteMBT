/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Sets or adds a perspective lens component through WorldHistory.
pub fn set_camera_lens_perspective_tracked(
  history : WorldHistory,
  world : World,
  camera : EntityId,
  lens_component : ComponentTypeId,
  near : Float,
  far : Float,
  aspect : Float,
  fov_y_rad : Float,
  flags : Float,
) -> Bool {
  set_or_add_camera_control_component_bytes_tracked(
    history,
    world,
    camera,
    lens_component,
    camera_lens_perspective_bytes(near, far, aspect, fov_y_rad, flags),
  )
}

///|
/// Adds an orthographic lens component to a camera entity.
pub fn add_camera_lens_orthographic(
  world : World,
  camera : EntityId,
  lens_component : ComponentTypeId,
  near : Float,
  far : Float,
  aspect : Float,
  ortho_half_height : Float,
  flags : Float,
) -> Bool {
  world.add_component_bytes(
    camera,
    lens_component,
    camera_lens_orthographic_bytes(near, far, aspect, ortho_half_height, flags),
  )
}

///|
/// Adds an orthographic lens component through WorldHistory.
pub fn add_camera_lens_orthographic_tracked(
  history : WorldHistory,
  world : World,
  camera : EntityId,
  lens_component : ComponentTypeId,
  near : Float,
  far : Float,
  aspect : Float,
  ortho_half_height : Float,
  flags : Float,
) -> Bool {
  history.add_component_bytes(
    world,
    camera,
    lens_component,
    camera_lens_orthographic_bytes(near, far, aspect, ortho_half_height, flags),
  )
}

///|
/// Sets or adds an orthographic lens component through WorldHistory.
pub fn set_camera_lens_orthographic_tracked(
  history : WorldHistory,
  world : World,
  camera : EntityId,
  lens_component : ComponentTypeId,
  near : Float,
  far : Float,
  aspect : Float,
  ortho_half_height : Float,
  flags : Float,
) -> Bool {
  set_or_add_camera_control_component_bytes_tracked(
    history,
    world,
    camera,
    lens_component,
    camera_lens_orthographic_bytes(near, far, aspect, ortho_half_height, flags),
  )
}

///|
/// Derives the local TRS written by the orbit camera transform system for one description.
fn orbit_camera_desc_trs(
  desc : OrbitOrthographicCameraDesc,
) -> (Float, Float, Float, Double, Double, Double, Double) {
  let (qx0, qy0, qz0, qw0) = quat_y(-desc.yaw)
  let (qx1, qy1, qz1, qw1) = quat_x(-desc.pitch)
  let (qx, qy, qz, qw) = quat_mul(qx0, qy0, qz0, qw0, qx1, qy1, qz1, qw1)
  let (dx, dy, dz) = quat_rotate_vec3(
    qx,
    qy,
    qz,
    qw,
    -desc.pan_x.to_double(),
    -desc.pan_y.to_double(),
    0.0,
  )
  (
    Float::from_double(dx),
    Float::from_double(dy),
    Float::from_double(dz) + desc.distance,
    qx,
    qy,
    qz,
    qw,
  )
}

///|
/// Builds the orthographic projection matrix for one orbit camera description.
fn orbit_orthographic_camera_desc_projection(
  desc : OrbitOrthographicCameraDesc,
) -> @m44.Matrix44F {
  let half_h = desc.ortho_half_height * desc.dolly
  let half_w = half_h * desc.aspect
  @m44.Matrix44::ortho(-half_w, half_w, -half_h, half_h, desc.near, desc.far)
}

///|
/// Sets Transform3D, GlobalTransform, orbit/home/lens components, and initial Camera blob.
pub fn setup_orbit_orthographic_camera(
  world : World,
  camera : EntityId,
  desc : OrbitOrthographicCameraDesc,
) -> Bool {
  let (px, py, pz, qx, qy, qz, qw) = orbit_camera_desc_trs(desc)
  let local_matrix = @comp.Transform3D::local_matrix_from_component_view(
    @comp.transform3d_trs_bytes(
      px,
      py,
      pz,
      qx,
      qy,
      qz,
      qw,
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    )[:],
  )
  let view = match local_matrix.inverse() {
    Some(view) => view
    None => return false
  }
  world.set_transform_trs(
    camera,
    px,
    py,
    pz,
    qx,
    qy,
    qz,
    qw,
    (1.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
  ) &&
  world.set_global_transform(camera, local_matrix) &&
  add_orbit_camera_controller_with_pose(
    world,
    camera,
    world.orbit_camera_controller_component(),
    desc.yaw,
    desc.pitch,
    desc.pan_x,
    desc.pan_y,
    desc.dolly,
    desc.distance,
  ) &&
  set_camera_home_from_current_transform(
    world,
    camera,
    world.camera_home_transform_component(),
  ) &&
  add_camera_lens_orthographic(
    world,
    camera,
    world.camera_lens_component(),
    desc.near,
    desc.far,
    desc.aspect,
    desc.ortho_half_height,
    desc.flags,
  ) &&
  world.set_camera_matrices(
    camera,
    view,
    orbit_orthographic_camera_desc_projection(desc),
    desc.near,
    desc.far,
    desc.aspect,
    camera_projection_orthographic(),
    desc.flags,
  )
}

///|
/// Runs a camera-control edit in a helper-owned transaction when possible.
fn run_camera_control_tracked_transaction(
  history : WorldHistory,
  world : World,
  label : String,
  body : () -> Bool,
) -> Bool {
  if !history.begin_transaction(label) {
    match history.last_diagnostic() {
      "transaction_open" | "recording_disabled" => body()
      _ => false
    }
  } else {
    if !body() {
      ignore(history.cancel_transaction_reverting(world))
      return false
    }
    if history.commit_transaction() {
      true
    } else {
      let diagnostic = history.last_diagnostic()
      ignore(history.cancel_transaction())
      diagnostic == "recording_disabled"
    }
  }
}

///|
/// Validates setup targets that would otherwise fail after earlier tracked mutations.
fn can_setup_orbit_orthographic_camera_tracked(
  world : World,
  camera : EntityId,
) -> Bool {
  world.is_alive(camera) &&
  !world.has_component(camera, world.orbit_camera_controller_component()) &&
  !world.has_component(camera, world.camera_lens_component()) &&
  (
    !world.has_component(camera, world.global_transform_component()) ||
    world.get_global_transform(camera) is Some(_)
  ) &&
  (
    !world.has_component(camera, world.camera_component()) ||
    world.camera_gpu_row(camera) is Some(_)
  )
}

///|
/// Validates orbit transform sync targets that would otherwise fail after earlier tracked mutations.
fn can_sync_orbit_camera_transform_tracked(
  world : World,
  camera : EntityId,
  reset_requested : Bool,
) -> Bool {
  world.is_alive(camera) &&
  (!reset_requested || world.has_component(camera, world.transform_component())) &&
  (
    !world.has_component(camera, world.global_transform_component()) ||
    world.get_global_transform(camera) is Some(_)
  )
}

///|
/// Applies tracked orbit orthographic setup steps inside the active transaction.
fn setup_orbit_orthographic_camera_tracked_body(
  history : WorldHistory,
  world : World,
  camera : EntityId,
  desc : OrbitOrthographicCameraDesc,
) -> Bool {
  let (px, py, pz, qx, qy, qz, qw) = orbit_camera_desc_trs(desc)
  let local_matrix = @comp.Transform3D::local_matrix_from_component_view(
    @comp.transform3d_trs_bytes(
      px,
      py,
      pz,
      qx,
      qy,
      qz,
      qw,
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    )[:],
  )
  let view = match local_matrix.inverse() {
    Some(view) => view
    None => return false
  }
  history.set_transform_trs(
    world,
    camera,
    px,
    py,
    pz,
    qx,
    qy,
    qz,
    qw,
    (1.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
  ) &&
  history.set_global_transform(world, camera, local_matrix) &&
  add_orbit_camera_controller_with_pose_tracked(
    history,
    world,
    camera,
    world.orbit_camera_controller_component(),
    desc.yaw,
    desc.pitch,
    desc.pan_x,
    desc.pan_y,
    desc.dolly,
    desc.distance,
  ) &&
  set_camera_home_from_current_transform_tracked(
    history,
    world,
    camera,
    world.camera_home_transform_component(),
  ) &&
  add_camera_lens_orthographic_tracked(
    history,
    world,
    camera,
    world.camera_lens_component(),
    desc.near,
    desc.far,
    desc.aspect,
    desc.ortho_half_height,
    desc.flags,
  ) &&
  history.set_camera_matrices(
    world,
    camera,
    view,
    orbit_orthographic_camera_desc_projection(desc),
    desc.near,
    desc.far,
    desc.aspect,
    camera_projection_orthographic(),
    desc.flags,
  )
}

///|
/// Sets up an orbit orthographic camera through WorldHistory as one operation when possible.
pub fn setup_orbit_orthographic_camera_tracked(
  history : WorldHistory,
  world : World,
  camera : EntityId,
  desc : OrbitOrthographicCameraDesc,
) -> Bool {
  if !can_setup_orbit_orthographic_camera_tracked(world, camera) {
    return false
  }
  run_camera_control_tracked_transaction(
    history,
    world,
    "setup_orbit_orthographic_camera",
    () => {
      setup_orbit_orthographic_camera_tracked_body(history, world, camera, desc)
    },
  )
}

///|
/// Builds a WebGPU perspective projection matrix from camera lens fields.
fn perspective_projection(
  fov_y_rad : Float,
  aspect : Float,
  near : Float,
  far : Float,
) -> @m44.Matrix44F {
  let f = Float::from_double(1.0 / @math.tan(fov_y_rad.to_double() * 0.5))
  let a = far / (near - far)
  let b = near * far / (near - far)
  @m44.Matrix44::new_col_major(
    f / aspect,
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    f,
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    a,
    (-1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    b,
    (0.0 : Float),
  )
}

///|
/// Builds the projection matrix described by a CameraLens component row.
pub fn camera_lens_projection_from_view(
  lens : ArrayView[Byte],
) -> (@m44.Matrix44F, Float, Float, Float, Float, Float) {
  camera_lens_projection_from_view_with_ortho_scale(lens, (1.0 : Float))
}

///|
/// Builds the projection matrix described by a CameraLens row with an orthographic scale.
fn camera_lens_projection_from_view_with_ortho_scale(
  lens : ArrayView[Byte],
  ortho_scale : Float,
) -> (@m44.Matrix44F, Float, Float, Float, Float, Float) {
  if lens.length() != camera_lens_stride {
    abort("camera_lens_projection_from_view: row length mismatch")
  }
  let projection_kind = @comp.get_gpu_f32_byte_view(
    lens, lens_projection_kind_offset,
  )
  let near = @comp.get_gpu_f32_byte_view(lens, lens_near_offset)
  let far = @comp.get_gpu_f32_byte_view(lens, lens_far_offset)
  let aspect = @comp.get_gpu_f32_byte_view(lens, lens_aspect_offset)
  let fov_y = @comp.get_gpu_f32_byte_view(lens, lens_fov_y_rad_offset)
  let half_h = @comp.get_gpu_f32_byte_view(lens, lens_ortho_half_height_offset)
  let flags = @comp.get_gpu_f32_byte_view(lens, lens_flags_offset)
  let proj = if projection_kind == camera_projection_orthographic() {
    let scaled_half_h = half_h * ortho_scale
    let half_w = scaled_half_h * aspect
    @m44.Matrix44::ortho(
      -half_w,
      half_w,
      -scaled_half_h,
      scaled_half_h,
      near,
      far,
    )
  } else {
    perspective_projection(fov_y, aspect, near, far)
  }
  (proj, near, far, aspect, projection_kind, flags)
}

///|
/// Multiplies two quaternions.
fn quat_mul(
  ax : Double,
  ay : Double,
  az : Double,
  aw : Double,
  bx : Double,
  by : Double,
  bz : Double,
  bw : Double,
) -> (Double, Double, Double, Double) {
  (
    aw * bx + ax * bw + ay * bz - az * by,
    aw * by - ax * bz + ay * bw + az * bx,
    aw * bz + ax * by - ay * bx + az * bw,
    aw * bw - ax * bx - ay * by - az * bz,
  )
}

///|
/// Builds a quaternion for a right-handed X-axis rotation.
fn quat_x(angle : Double) -> (Double, Double, Double, Double) {
  let half = angle * 0.5
  (@math.sin(half), 0.0, 0.0, @math.cos(half))
}

///|
/// Builds a quaternion for a right-handed Y-axis rotation.
fn quat_y(angle : Double) -> (Double, Double, Double, Double) {
  let half = angle * 0.5
  (0.0, @math.sin(half), 0.0, @math.cos(half))
}

///|
/// Rotates a vector by a unit quaternion.
fn quat_rotate_vec3(
  qx : Double,
  qy : Double,
  qz : Double,
  qw : Double,
  x : Double,
  y : Double,
  z : Double,
) -> (Double, Double, Double) {
  let tx = 2.0 * (qy * z - qz * y)
  let ty = 2.0 * (qz * x - qx * z)
  let tz = 2.0 * (qx * y - qy * x)
  (
    x + qw * tx + (qy * tz - qz * ty),
    y + qw * ty + (qz * tx - qx * tz),
    z + qw * tz + (qx * ty - qy * tx),
  )
}

///|
/// Decodes reset-aware orbit fields from a mutable controller row.
fn orbit_camera_pose_from_controller_view(
  row : ArrayView[Byte],
) -> (Float, Float, Float, Float, Float, Float, Bool) {
  (
    @comp.get_gpu_f32_byte_view(row, orbit_yaw_offset),
    @comp.get_gpu_f32_byte_view(row, orbit_pitch_offset),
    @comp.get_gpu_f32_byte_view(row, orbit_pan_x_offset),
    @comp.get_gpu_f32_byte_view(row, orbit_pan_y_offset),
    @comp.get_gpu_f32_byte_view(row, orbit_dolly_offset),
    @comp.get_gpu_f32_byte_view(row, orbit_distance_offset),
    @comp.get_gpu_f32_byte_view(row, orbit_reset_requested_offset) !=
    (0.0 : Float),
  )
}

///|
/// Writes the reset pose into a controller row and clears its reset request flag.
fn reset_orbit_camera_controller_view(row : MutArrayView[Byte]) -> Unit {
  let reset_yaw = @comp.get_gpu_f32_mut_view(row, orbit_reset_yaw_offset)
  let reset_pitch = @comp.get_gpu_f32_mut_view(row, orbit_reset_pitch_offset)
  let reset_pan_x = @comp.get_gpu_f32_mut_view(row, orbit_reset_pan_x_offset)
  let reset_pan_y = @comp.get_gpu_f32_mut_view(row, orbit_reset_pan_y_offset)
  let reset_dolly = @comp.get_gpu_f32_mut_view(row, orbit_reset_dolly_offset)
  let reset_distance = @comp.get_gpu_f32_mut_view(
    row, orbit_reset_distance_offset,
  )
  @writes.put_f32_le_mut_view(row, orbit_yaw_offset, reset_yaw.to_double())
  @writes.put_f32_le_mut_view(row, orbit_pitch_offset, reset_pitch.to_double())
  @writes.put_f32_le_mut_view(row, orbit_pan_x_offset, reset_pan_x.to_double())
  @writes.put_f32_le_mut_view(row, orbit_pan_y_offset, reset_pan_y.to_double())
  @writes.put_f32_le_mut_view(row, orbit_dolly_offset, reset_dolly.to_double())
  @writes.put_f32_le_mut_view(
    row,
    orbit_distance_offset,
    reset_distance.to_double(),
  )
  @writes.put_f32_le_mut_view(row, orbit_reset_requested_offset, 0.0)
}

///|
/// Writes Transform3D from orbit pose fields and returns its local matrix.
fn write_orbit_transform_row(
  tf_row : MutArrayView[Byte],
  yaw : Float,
  pitch : Float,
  pan_x : Float,
  pan_y : Float,
  distance : Float,
) -> @m44.Matrix44F {
  let (qx0, qy0, qz0, qw0) = quat_y(-yaw.to_double())
  let (qx1, qy1, qz1, qw1) = quat_x(-pitch.to_double())
  let (qx, qy, qz, qw) = quat_mul(qx0, qy0, qz0, qw0, qx1, qy1, qz1, qw1)
  let (dx, dy, dz) = quat_rotate_vec3(
    qx,
    qy,
    qz,
    qw,
    -pan_x.to_double(),
    -pan_y.to_double(),
    0.0,
  )
  let px = Float::from_double(dx)
  let py = Float::from_double(dy)
  let pz = Float::from_double(dz) + distance
  @comp.Transform3D::write_trs_to_component_mut_view(
    tf_row, px, py, pz, qx, qy, qz, qw, 1.0, 1.0, 1.0,
  )
  @comp.Transform3D::local_matrix_from_component_view(tf_row[:])
}

///|
/// Writes the Camera blob for one orbit camera through WorldHistory.
pub fn sync_orbit_camera_blob_component_tracked(
  history : WorldHistory,
  world : World,
  camera : EntityId,
  orbit_component : ComponentTypeId,
  lens_component : ComponentTypeId,
) -> Bool {
  let global = match world.get_global_transform(camera) {
    Some(global) => global
    None => return false
  }
  let view = match global.inverse() {
    Some(view) => view
    None => return false
  }
  let orbit_row = match world.component_bytes(camera, orbit_component) {
    Some(bytes) => bytes
    None => return false
  }
  let lens_row = match world.component_bytes(camera, lens_component) {
    Some(bytes) => bytes
    None => return false
  }
  let (_yaw, _pitch, _pan_x, _pan_y, dolly, _distance, _requested) = orbit_camera_pose_from_controller_view(
    orbit_row[:],
  )
  let (proj, near, far, aspect, projection_kind, flags) = camera_lens_projection_from_view_with_ortho_scale(
    lens_row[:],
    dolly,
  )
  history.set_camera_matrices(
    world, camera, view, proj, near, far, aspect, projection_kind, flags,
  )
}

///|
/// Applies tracked Transform3D and GlobalTransform sync inside the active transaction.
fn sync_orbit_camera_transform_component_tracked_body(
  history : WorldHistory,
  world : World,
  camera : EntityId,
  orbit_component : ComponentTypeId,
  home_component : ComponentTypeId,
) -> Bool {
  let orbit_row = match world.component_bytes(camera, orbit_component) {
    Some(bytes) => bytes
    None => return false
  }
  let (yaw, pitch, pan_x, pan_y, _dolly, distance, reset_requested) = orbit_camera_pose_from_controller_view(
    orbit_row[:],
  )
  if reset_requested {
    let home_row = match world.component_bytes(camera, home_component) {
      Some(bytes) => bytes
      None => return false
    }
    if !can_sync_orbit_camera_transform_tracked(world, camera, reset_requested) {
      return false
    }
    let next_orbit = orbit_row
    reset_orbit_camera_controller_view(
      next_orbit.mut_view(start=0, end=next_orbit.length()),
    )
    history.set_component_bytes(
      world,
      camera,
      world.transform_component(),
      home_row,
    ) &&
    history.set_component_bytes(world, camera, orbit_component, next_orbit) &&
    history.set_global_transform(
      world,
      camera,
      @comp.Transform3D::local_matrix_from_component_view(home_row[:]),
    )
  } else {
    if !can_sync_orbit_camera_transform_tracked(world, camera, reset_requested) {
      return false
    }
    let (qx0, qy0, qz0, qw0) = quat_y(-yaw.to_double())
    let (qx1, qy1, qz1, qw1) = quat_x(-pitch.to_double())
    let (qx, qy, qz, qw) = quat_mul(qx0, qy0, qz0, qw0, qx1, qy1, qz1, qw1)
    let (dx, dy, dz) = quat_rotate_vec3(
      qx,
      qy,
      qz,
      qw,
      -pan_x.to_double(),
      -pan_y.to_double(),
      0.0,
    )
    let px = Float::from_double(dx)
    let py = Float::from_double(dy)
    let pz = Float::from_double(dz) + distance
    let local_matrix = @comp.Transform3D::local_matrix_from_component_view(
      @comp.transform3d_trs_bytes(
        px,
        py,
        pz,
        qx,
        qy,
        qz,
        qw,
        (1.0 : Float),
        (1.0 : Float),
        (1.0 : Float),
      )[:],
    )
    history.set_transform_trs(
      world,
      camera,
      px,
      py,
      pz,
      qx,
      qy,
      qz,
      qw,
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    ) &&
    history.set_global_transform(world, camera, local_matrix)
  }
}

///|
/// Writes Transform3D and GlobalTransform from orbit state through WorldHistory.
pub fn sync_orbit_camera_transform_component_tracked(
  history : WorldHistory,
  world : World,
  camera : EntityId,
  orbit_component : ComponentTypeId,
  home_component : ComponentTypeId,
) -> Bool {
  run_camera_control_tracked_transaction(
    history,
    world,
    "sync_orbit_camera_transform_component",
    () => {
      sync_orbit_camera_transform_component_tracked_body(
        history, world, camera, orbit_component, home_component,
      )
    },
  )
}

///|
/// Builds a system that applies orbit controller state to local Transform3D and parentless GlobalTransform.
pub fn orbit_camera_transform_system(
  world : World,
  phase : PhaseKey,
  orbit_component : ComponentTypeId,
  home_component : ComponentTypeId,
) -> System {
  let tf = world.transform_component()
  let gt = world.global_transform_component()
  System::new(
    "rhodonite/orbit_camera_transform",
    phase,
    [home_component],
    [tf, gt, orbit_component],
    fn(world, _ctx, _commands) {
      Query::new([tf, gt, orbit_component, home_component]).for_each(world, row => {
        let entity = row.entity()
        let mut reset_requested = false
        row.read(orbit_component, orbit_row => {
          let (_, _, _, _, _, _, requested) = orbit_camera_pose_from_controller_view(
            orbit_row,
          )
          reset_requested = requested
        })
        if reset_requested {
          row.read(home_component, home_row => {
            row.write(tf, tf_row => {
              copy_view_to_mut_view(home_row, tf_row)
              ignore(
                world.set_global_transform(
                  entity,
                  @comp.Transform3D::local_matrix_from_component_view(tf_row[:]),
                ),
              )
            })
          })
          row.write(orbit_component, orbit_row => {
            reset_orbit_camera_controller_view(orbit_row)
          })
        } else {
          let mut yaw = (0.0 : Float)
          let mut pitch = (0.0 : Float)
          let mut pan_x = (0.0 : Float)
          let mut pan_y = (0.0 : Float)
          let mut distance = (16.0 : Float)
          row.read(orbit_component, orbit_row => {
            let (cy, cp, cpx, cpy, _dolly, cdistance, _requested) = orbit_camera_pose_from_controller_view(
              orbit_row,
            )
            yaw = cy
            pitch = cp
            pan_x = cpx
            pan_y = cpy
            distance = cdistance
          })
          row.write(tf, tf_row => {
            let local_matrix = write_orbit_transform_row(
              tf_row, yaw, pitch, pan_x, pan_y, distance,
            )
            ignore(world.set_global_transform(entity, local_matrix))
          })
        }
      })
    },
  )
}

///|
/// Builds a command-buffer system that queues orbit controller transform writes.
pub fn orbit_camera_transform_command_system(
  world : World,
  phase : PhaseKey,
  orbit_component : ComponentTypeId,
  home_component : ComponentTypeId,
) -> System {
  let tf = world.transform_component()
  let gt = world.global_transform_component()
  System::new(
    "rhodonite/orbit_camera_transform_command",
    phase,
    [home_component],
    [tf, gt, orbit_component],
    fn(world, _ctx, commands) {
      Query::new([tf, gt, orbit_component, home_component]).for_each(world, row => {
        let entity = row.entity()
        let mut reset_requested = false
        row.read(orbit_component, orbit_row => {
          let (_, _, _, _, _, _, requested) = orbit_camera_pose_from_controller_view(
            orbit_row,
          )
          reset_requested = requested
        })
        if reset_requested {
          let mut home_bytes = FixedArray::make(0, (0 : Byte))
          row.read(home_component, home_row => {
            home_bytes = fixed_array_from_view(home_row)
          })
          let mut orbit_bytes = FixedArray::make(0, (0 : Byte))
          row.read(orbit_component, orbit_row => {
            orbit_bytes = fixed_array_from_view(orbit_row)
            reset_orbit_camera_controller_view(
              orbit_bytes.mut_view(start=0, end=orbit_bytes.length()),
            )
          })
          commands.set_component_bytes(entity, tf, home_bytes)
          commands.set_component_bytes(entity, orbit_component, orbit_bytes)
          commands.set_global_transform(
            entity,
            @comp.Transform3D::local_matrix_from_component_view(home_bytes[:]),
          )
        } else {
          let mut yaw = (0.0 : Float)
          let mut pitch = (0.0 : Float)
          let mut pan_x = (0.0 : Float)
          let mut pan_y = (0.0 : Float)
          let mut distance = (16.0 : Float)
          row.read(orbit_component, orbit_row => {
            let (cy, cp, cpx, cpy, _dolly, cdistance, _requested) = orbit_camera_pose_from_controller_view(
              orbit_row,
            )
            yaw = cy
            pitch = cp
            pan_x = cpx
            pan_y = cpy
            distance = cdistance
          })
          let tf_bytes = FixedArray::make(
            @comp.transform3d_gpu_layout().stride,
            (0 : Byte),
          )
          let local_matrix = write_orbit_transform_row(
            tf_bytes.mut_view(start=0, end=tf_bytes.length()),
            yaw,
            pitch,
            pan_x,
            pan_y,
            distance,
          )
          commands.set_component_bytes(entity, tf, tf_bytes)
          commands.set_global_transform(entity, local_matrix)
        }
      })
    },
  )
}
