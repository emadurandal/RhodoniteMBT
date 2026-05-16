///|
/// Byte stride for the library orbit camera controller component.
let orbit_camera_controller_stride : Int = 80

///|
/// Byte stride for the camera home transform component.
let camera_home_transform_stride : Int = 48

///|
/// Byte stride for the camera lens component.
let camera_lens_stride : Int = 32

///|
/// Byte offsets for the orbit camera controller component.
let orbit_yaw_offset : Int = 0

///|
/// Byte offsets for the orbit camera controller component.
let orbit_pitch_offset : Int = 4

///|
/// Byte offsets for the orbit camera controller component.
let orbit_sensitivity_offset : Int = 8

///|
/// Byte offsets for the orbit camera controller component.
let orbit_min_pitch_offset : Int = 12

///|
/// Byte offsets for the orbit camera controller component.
let orbit_max_pitch_offset : Int = 16

///|
/// Byte offsets for the orbit camera controller component.
let orbit_pan_x_offset : Int = 20

///|
/// Byte offsets for the orbit camera controller component.
let orbit_pan_y_offset : Int = 24

///|
/// Byte offsets for the orbit camera controller component.
let orbit_pan_sensitivity_offset : Int = 28

///|
/// Byte offsets for the orbit camera controller component.
let orbit_dolly_offset : Int = 32

///|
/// Byte offsets for the orbit camera controller component.
let orbit_dolly_sensitivity_offset : Int = 36

///|
/// Byte offsets for the orbit camera controller component.
let orbit_min_dolly_offset : Int = 40

///|
/// Byte offsets for the orbit camera controller component.
let orbit_max_dolly_offset : Int = 44

///|
/// Byte offsets for the orbit camera controller component.
let orbit_distance_offset : Int = 48

///|
/// Byte offsets for the orbit camera controller component.
let orbit_reset_yaw_offset : Int = 52

///|
/// Byte offsets for the orbit camera controller component.
let orbit_reset_pitch_offset : Int = 56

///|
/// Byte offsets for the orbit camera controller component.
let orbit_reset_pan_x_offset : Int = 60

///|
/// Byte offsets for the orbit camera controller component.
let orbit_reset_pan_y_offset : Int = 64

///|
/// Byte offsets for the orbit camera controller component.
let orbit_reset_dolly_offset : Int = 68

///|
/// Byte offsets for the orbit camera controller component.
let orbit_reset_distance_offset : Int = 72

///|
/// Byte offsets for the orbit camera controller component.
let orbit_reset_requested_offset : Int = 76

///|
/// Byte offsets for the camera lens component.
let lens_projection_kind_offset : Int = 0

///|
/// Byte offsets for the camera lens component.
let lens_near_offset : Int = 4

///|
/// Byte offsets for the camera lens component.
let lens_far_offset : Int = 8

///|
/// Byte offsets for the camera lens component.
let lens_aspect_offset : Int = 12

///|
/// Byte offsets for the camera lens component.
let lens_fov_y_rad_offset : Int = 16

///|
/// Byte offsets for the camera lens component.
let lens_ortho_half_height_offset : Int = 20

///|
/// Byte offsets for the camera lens component.
let lens_flags_offset : Int = 24

///|
/// Perspective camera lens discriminator.
pub fn camera_projection_perspective() -> Float {
  0.0
}

///|
/// Orthographic camera lens discriminator.
pub fn camera_projection_orthographic() -> Float {
  1.0
}

///|
/// Registers the builtin-style orbit camera controller CPU component.
pub fn register_orbit_camera_controller_component(
  world : World,
) -> ComponentTypeId {
  world.register_cpu_component(
    "OrbitCameraController", orbit_camera_controller_stride,
  )
}

///|
/// Registers the camera home transform CPU component.
pub fn register_camera_home_transform_component(
  world : World,
) -> ComponentTypeId {
  world.register_cpu_component(
    "CameraHomeTransform", camera_home_transform_stride,
  )
}

///|
/// Registers the camera lens CPU component.
pub fn register_camera_lens_component(world : World) -> ComponentTypeId {
  world.register_cpu_component("CameraLens", camera_lens_stride)
}

///|
/// Clamps a floating-point value between lower and upper bounds.
fn clamp_float(value : Float, lo : Float, hi : Float) -> Float {
  if value < lo {
    lo
  } else if value > hi {
    hi
  } else {
    value
  }
}

///|
/// Reads one f32 payload value from owned component bytes as Float.
fn fixed_f32(bytes : FixedArray[Byte], offset : Int) -> Float {
  Float::from_double(@writes.get_f32_le(bytes, offset))
}

///|
/// Encodes one orbit camera controller payload.
fn orbit_camera_controller_bytes(
  yaw : Float,
  pitch : Float,
  sensitivity : Float,
  min_pitch : Float,
  max_pitch : Float,
  pan_x : Float,
  pan_y : Float,
  pan_sensitivity : Float,
  dolly : Float,
  dolly_sensitivity : Float,
  min_dolly : Float,
  max_dolly : Float,
  distance : Float,
  reset_requested : Bool,
) -> FixedArray[Byte] {
  let bytes = FixedArray::make(orbit_camera_controller_stride, (0 : Byte))
  @writes.put_f32_le(bytes, orbit_yaw_offset, yaw.to_double())
  @writes.put_f32_le(bytes, orbit_pitch_offset, pitch.to_double())
  @writes.put_f32_le(bytes, orbit_sensitivity_offset, sensitivity.to_double())
  @writes.put_f32_le(bytes, orbit_min_pitch_offset, min_pitch.to_double())
  @writes.put_f32_le(bytes, orbit_max_pitch_offset, max_pitch.to_double())
  @writes.put_f32_le(bytes, orbit_pan_x_offset, pan_x.to_double())
  @writes.put_f32_le(bytes, orbit_pan_y_offset, pan_y.to_double())
  @writes.put_f32_le(
    bytes,
    orbit_pan_sensitivity_offset,
    pan_sensitivity.to_double(),
  )
  @writes.put_f32_le(bytes, orbit_dolly_offset, dolly.to_double())
  @writes.put_f32_le(
    bytes,
    orbit_dolly_sensitivity_offset,
    dolly_sensitivity.to_double(),
  )
  @writes.put_f32_le(bytes, orbit_min_dolly_offset, min_dolly.to_double())
  @writes.put_f32_le(bytes, orbit_max_dolly_offset, max_dolly.to_double())
  @writes.put_f32_le(bytes, orbit_distance_offset, distance.to_double())
  @writes.put_f32_le(bytes, orbit_reset_yaw_offset, yaw.to_double())
  @writes.put_f32_le(bytes, orbit_reset_pitch_offset, pitch.to_double())
  @writes.put_f32_le(bytes, orbit_reset_pan_x_offset, pan_x.to_double())
  @writes.put_f32_le(bytes, orbit_reset_pan_y_offset, pan_y.to_double())
  @writes.put_f32_le(bytes, orbit_reset_dolly_offset, dolly.to_double())
  @writes.put_f32_le(bytes, orbit_reset_distance_offset, distance.to_double())
  @writes.put_f32_le(
    bytes,
    orbit_reset_requested_offset,
    if reset_requested {
      1.0
    } else {
      0.0
    },
  )
  bytes
}

///|
/// Adds an orbit camera controller component to a camera entity.
pub fn add_orbit_camera_controller(
  world : World,
  camera : EntityId,
  component : ComponentTypeId,
  yaw : Double,
  pitch : Double,
) -> Bool {
  world.add_component_bytes(
    camera,
    component,
    orbit_camera_controller_bytes(
      Float::from_double(yaw),
      Float::from_double(pitch),
      (0.006 : Float),
      (-1.25 : Float),
      (1.25 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (0.01 : Float),
      (1.0 : Float),
      (0.001 : Float),
      (0.01 : Float),
      (4.0 : Float),
      (16.0 : Float),
      false,
    ),
  )
}

///|
/// Adds an orbit camera controller component with an explicit orbit distance.
pub fn add_orbit_camera_controller_with_distance(
  world : World,
  camera : EntityId,
  component : ComponentTypeId,
  yaw : Double,
  pitch : Double,
  distance : Float,
) -> Bool {
  world.add_component_bytes(
    camera,
    component,
    orbit_camera_controller_bytes(
      Float::from_double(yaw),
      Float::from_double(pitch),
      (0.006 : Float),
      (-1.25 : Float),
      (1.25 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (0.01 : Float),
      (1.0 : Float),
      (0.001 : Float),
      (0.01 : Float),
      (4.0 : Float),
      distance,
      false,
    ),
  )
}

///|
/// Reads the current orbit camera controller transform fields.
pub fn orbit_camera_transform(
  world : World,
  camera : EntityId,
  component : ComponentTypeId,
) -> (Double, Double, Double, Double, Double) {
  match world.component_bytes(camera, component) {
    Some(bytes) =>
      (
        @writes.get_f32_le(bytes, orbit_yaw_offset),
        @writes.get_f32_le(bytes, orbit_pitch_offset),
        @writes.get_f32_le(bytes, orbit_pan_x_offset),
        @writes.get_f32_le(bytes, orbit_pan_y_offset),
        @writes.get_f32_le(bytes, orbit_dolly_offset),
      )
    None =>
      abort("orbit_camera_transform: camera is missing OrbitCameraController")
  }
}

///|
/// Reads the current orbit camera controller pose fields including distance.
pub fn orbit_camera_pose(
  world : World,
  camera : EntityId,
  component : ComponentTypeId,
) -> (Float, Float, Float, Float, Float, Float) {
  match world.component_bytes(camera, component) {
    Some(bytes) =>
      (
        fixed_f32(bytes, orbit_yaw_offset),
        fixed_f32(bytes, orbit_pitch_offset),
        fixed_f32(bytes, orbit_pan_x_offset),
        fixed_f32(bytes, orbit_pan_y_offset),
        fixed_f32(bytes, orbit_dolly_offset),
        fixed_f32(bytes, orbit_distance_offset),
      )
    None => abort("orbit_camera_pose: camera is missing OrbitCameraController")
  }
}

///|
/// Updates an orbit camera controller from already-folded per-frame mouse values.
pub fn update_orbit_camera_controller_from_mouse_frame(
  world : World,
  camera : EntityId,
  component : ComponentTypeId,
  left_down : Bool,
  left_pressed : Bool,
  middle_down : Bool,
  middle_pressed : Bool,
  pointer_delta_x : Float,
  pointer_delta_y : Float,
  wheel_delta_y : Float,
) -> Bool {
  match world.component_bytes(camera, component) {
    Some(bytes) => {
      let yaw = fixed_f32(bytes, orbit_yaw_offset)
      let pitch = fixed_f32(bytes, orbit_pitch_offset)
      let sensitivity = fixed_f32(bytes, orbit_sensitivity_offset)
      let min_pitch = fixed_f32(bytes, orbit_min_pitch_offset)
      let max_pitch = fixed_f32(bytes, orbit_max_pitch_offset)
      let pan_x = fixed_f32(bytes, orbit_pan_x_offset)
      let pan_y = fixed_f32(bytes, orbit_pan_y_offset)
      let pan_sensitivity = fixed_f32(bytes, orbit_pan_sensitivity_offset)
      let dolly = fixed_f32(bytes, orbit_dolly_offset)
      let dolly_sensitivity = fixed_f32(bytes, orbit_dolly_sensitivity_offset)
      let min_dolly = fixed_f32(bytes, orbit_min_dolly_offset)
      let max_dolly = fixed_f32(bytes, orbit_max_dolly_offset)
      let mut next_yaw = yaw
      let mut next_pitch = pitch
      let mut next_pan_x = pan_x
      let mut next_pan_y = pan_y
      let mut next_dolly = dolly
      let mut changed = false
      if left_down && !left_pressed {
        next_yaw = yaw + pointer_delta_x * sensitivity
        next_pitch = clamp_float(
          pitch + pointer_delta_y * sensitivity,
          min_pitch,
          max_pitch,
        )
        changed = true
      }
      if middle_down && !middle_pressed {
        next_pan_x = pan_x + pointer_delta_x * pan_sensitivity * dolly
        next_pan_y = pan_y - pointer_delta_y * pan_sensitivity * dolly
        changed = true
      }
      if wheel_delta_y != (0.0 : Float) {
        next_dolly = clamp_float(
          dolly + wheel_delta_y * dolly_sensitivity * dolly,
          min_dolly,
          max_dolly,
        )
        changed = true
      }
      if changed {
        @writes.put_f32_le(bytes, orbit_yaw_offset, next_yaw.to_double())
        @writes.put_f32_le(bytes, orbit_pitch_offset, next_pitch.to_double())
        @writes.put_f32_le(bytes, orbit_pan_x_offset, next_pan_x.to_double())
        @writes.put_f32_le(bytes, orbit_pan_y_offset, next_pan_y.to_double())
        @writes.put_f32_le(bytes, orbit_dolly_offset, next_dolly.to_double())
        world.set_component_bytes(camera, component, bytes)
      } else {
        false
      }
    }
    None => false
  }
}

///|
/// Marks an orbit camera controller for reset during the next orbit transform system run.
pub fn request_orbit_camera_reset(
  world : World,
  camera : EntityId,
  component : ComponentTypeId,
) -> Bool {
  match world.component_bytes(camera, component) {
    Some(bytes) => {
      @writes.put_f32_le(bytes, orbit_reset_requested_offset, 1.0)
      world.set_component_bytes(camera, component, bytes)
    }
    None => false
  }
}

///|
/// Copies one read-only byte view into a mutable view of the same length.
fn copy_view_to_mut_view(
  src : ArrayView[Byte],
  dst : MutArrayView[Byte],
) -> Unit {
  if src.length() != dst.length() {
    abort("copy_view_to_mut_view: length mismatch")
  }
  for i = 0; i < src.length(); i = i + 1 {
    dst[i] = src[i]
  }
}

///|
/// Stores the entity's current local Transform3D row as its camera reset home.
pub fn set_camera_home_from_current_transform(
  world : World,
  camera : EntityId,
  home_component : ComponentTypeId,
) -> Bool {
  let tf = world.transform_component()
  match world.component_bytes(camera, tf) {
    Some(bytes) =>
      if world.has_component(camera, home_component) {
        world.set_component_bytes(camera, home_component, bytes)
      } else {
        world.add_component_bytes(camera, home_component, bytes)
      }
    None => false
  }
}

///|
/// Adds a perspective lens component to a camera entity.
pub fn add_camera_lens_perspective(
  world : World,
  camera : EntityId,
  lens_component : ComponentTypeId,
  near : Float,
  far : Float,
  aspect : Float,
  fov_y_rad : Float,
  flags : Float,
) -> Bool {
  let bytes = FixedArray::make(camera_lens_stride, (0 : Byte))
  @writes.put_f32_le(
    bytes,
    lens_projection_kind_offset,
    camera_projection_perspective().to_double(),
  )
  @writes.put_f32_le(bytes, lens_near_offset, near.to_double())
  @writes.put_f32_le(bytes, lens_far_offset, far.to_double())
  @writes.put_f32_le(bytes, lens_aspect_offset, aspect.to_double())
  @writes.put_f32_le(bytes, lens_fov_y_rad_offset, fov_y_rad.to_double())
  @writes.put_f32_le(bytes, lens_ortho_half_height_offset, 1.0)
  @writes.put_f32_le(bytes, lens_flags_offset, flags.to_double())
  world.add_component_bytes(camera, lens_component, bytes)
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
  let bytes = FixedArray::make(camera_lens_stride, (0 : Byte))
  @writes.put_f32_le(
    bytes,
    lens_projection_kind_offset,
    camera_projection_orthographic().to_double(),
  )
  @writes.put_f32_le(bytes, lens_near_offset, near.to_double())
  @writes.put_f32_le(bytes, lens_far_offset, far.to_double())
  @writes.put_f32_le(bytes, lens_aspect_offset, aspect.to_double())
  @writes.put_f32_le(bytes, lens_fov_y_rad_offset, 1.0)
  @writes.put_f32_le(
    bytes,
    lens_ortho_half_height_offset,
    ortho_half_height.to_double(),
  )
  @writes.put_f32_le(bytes, lens_flags_offset, flags.to_double())
  world.add_component_bytes(camera, lens_component, bytes)
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
    let half_w = half_h * aspect
    @m44.Matrix44::ortho(-half_w, half_w, -half_h, half_h, near, far)
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
/// Builds a system that writes Camera blob rows from GlobalTransform and CameraLens.
pub fn camera_blob_sync_system(
  world : World,
  phase : PhaseKey,
  lens_component : ComponentTypeId,
) -> System {
  let gt = world.global_transform_component()
  let camera = world.camera_component()
  System::new(
    "rhodonite/camera_blob_sync",
    phase,
    [gt, lens_component],
    [camera],
    fn(world, _ctx, _commands) {
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
