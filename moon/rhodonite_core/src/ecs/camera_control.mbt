/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

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
/// Returns the world's builtin orbit camera controller CPU component.
pub fn register_orbit_camera_controller_component(
  world : World,
) -> ComponentTypeId {
  world.orbit_camera_controller_component()
}

///|
/// Returns the world's builtin camera home transform CPU component.
pub fn register_camera_home_transform_component(
  world : World,
) -> ComponentTypeId {
  world.camera_home_transform_component()
}

///|
/// Returns the world's builtin camera lens CPU component.
pub fn register_camera_lens_component(world : World) -> ComponentTypeId {
  world.camera_lens_component()
}

///|
/// Describes the initial ECS components for an orbit-controlled orthographic camera.
pub(all) struct OrbitOrthographicCameraDesc {
  priv yaw : Double
  priv pitch : Double
  priv pan_x : Float
  priv pan_y : Float
  priv dolly : Float
  priv distance : Float
  priv near : Float
  priv far : Float
  priv aspect : Float
  priv ortho_half_height : Float
  priv flags : Float
}

///|
/// Builds an orbit orthographic camera description from explicit orbit pose and lens values.
pub fn OrbitOrthographicCameraDesc::new(
  yaw : Double,
  pitch : Double,
  pan_x : Float,
  pan_y : Float,
  dolly : Float,
  distance : Float,
  near : Float,
  far : Float,
  aspect : Float,
  ortho_half_height : Float,
  flags? : Float = (0.0 : Float),
) -> OrbitOrthographicCameraDesc {
  {
    yaw,
    pitch,
    pan_x,
    pan_y,
    dolly,
    distance,
    near,
    far,
    aspect,
    ortho_half_height,
    flags,
  }
}

///|
/// Builds a yaw-zero orbit camera description that starts at the given Y/Z position.
pub fn OrbitOrthographicCameraDesc::new_yz_pitched(
  pitch : Double,
  position_y : Float,
  position_z : Float,
  near : Float,
  far : Float,
  aspect : Float,
  ortho_half_height : Float,
  flags? : Float = (0.0 : Float),
) -> OrbitOrthographicCameraDesc {
  let pan_y = Float::from_double(-position_y.to_double() / @math.cos(pitch))
  let distance = Float::from_double(
    position_z.to_double() - pan_y.to_double() * @math.sin(pitch),
  )
  OrbitOrthographicCameraDesc::new(
    0.0,
    pitch,
    (0.0 : Float),
    pan_y,
    (1.0 : Float),
    distance,
    near,
    far,
    aspect,
    ortho_half_height,
    flags~,
  )
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
/// Adds an orbit camera controller component with an explicit pose.
pub fn add_orbit_camera_controller_with_pose(
  world : World,
  camera : EntityId,
  component : ComponentTypeId,
  yaw : Double,
  pitch : Double,
  pan_x : Float,
  pan_y : Float,
  dolly : Float,
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
      pan_x,
      pan_y,
      (0.01 : Float),
      dolly,
      (0.001 : Float),
      (0.01 : Float),
      (4.0 : Float),
      distance,
      false,
    ),
  )
}

///|
/// Adds or sets one component row through WorldHistory depending on current presence.
fn set_or_add_camera_control_component_bytes_tracked(
  history : WorldHistory,
  world : World,
  camera : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  if world.has_component(camera, component) {
    history.set_component_bytes(world, camera, component, bytes)
  } else {
    history.add_component_bytes(world, camera, component, bytes)
  }
}

///|
/// Adds an orbit camera controller component through WorldHistory.
pub fn add_orbit_camera_controller_tracked(
  history : WorldHistory,
  world : World,
  camera : EntityId,
  component : ComponentTypeId,
  yaw : Double,
  pitch : Double,
) -> Bool {
  add_orbit_camera_controller_with_distance_tracked(
    history,
    world,
    camera,
    component,
    yaw,
    pitch,
    (16.0 : Float),
  )
}

///|
/// Adds an orbit camera controller component with an explicit orbit distance through WorldHistory.
pub fn add_orbit_camera_controller_with_distance_tracked(
  history : WorldHistory,
  world : World,
  camera : EntityId,
  component : ComponentTypeId,
  yaw : Double,
  pitch : Double,
  distance : Float,
) -> Bool {
  history.add_component_bytes(
    world,
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
/// Adds an orbit camera controller component with an explicit pose through WorldHistory.
pub fn add_orbit_camera_controller_with_pose_tracked(
  history : WorldHistory,
  world : World,
  camera : EntityId,
  component : ComponentTypeId,
  yaw : Double,
  pitch : Double,
  pan_x : Float,
  pan_y : Float,
  dolly : Float,
  distance : Float,
) -> Bool {
  history.add_component_bytes(
    world,
    camera,
    component,
    orbit_camera_controller_bytes(
      Float::from_double(yaw),
      Float::from_double(pitch),
      (0.006 : Float),
      (-1.25 : Float),
      (1.25 : Float),
      pan_x,
      pan_y,
      (0.01 : Float),
      dolly,
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
  left_down : Bool,
  left_pressed : Bool,
  middle_down : Bool,
  middle_pressed : Bool,
  pointer_delta_x : Float,
  pointer_delta_y : Float,
  wheel_delta_y : Float,
) -> Bool {
  let component = world.orbit_camera_controller_component()
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
/// Updates an orbit camera controller from mouse values through WorldHistory.
pub fn update_orbit_camera_controller_from_mouse_frame_tracked(
  history : WorldHistory,
  world : World,
  camera : EntityId,
  left_down : Bool,
  left_pressed : Bool,
  middle_down : Bool,
  middle_pressed : Bool,
  pointer_delta_x : Float,
  pointer_delta_y : Float,
  wheel_delta_y : Float,
) -> Bool {
  let component = world.orbit_camera_controller_component()
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
        history.set_component_bytes(world, camera, component, bytes)
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
/// Marks an orbit camera controller for reset through WorldHistory.
pub fn request_orbit_camera_reset_tracked(
  history : WorldHistory,
  world : World,
  camera : EntityId,
  component : ComponentTypeId,
) -> Bool {
  match world.component_bytes(camera, component) {
    Some(bytes) => {
      @writes.put_f32_le(bytes, orbit_reset_requested_offset, 1.0)
      history.set_component_bytes(world, camera, component, bytes)
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
/// Copies one read-only byte view into an owned FixedArray.
fn fixed_array_from_view(src : ArrayView[Byte]) -> FixedArray[Byte] {
  let out = FixedArray::make(src.length(), (0 : Byte))
  copy_view_to_mut_view(src, out.mut_view(start=0, end=out.length()))
  out
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
/// Stores the current local Transform3D row as camera reset home through WorldHistory.
pub fn set_camera_home_from_current_transform_tracked(
  history : WorldHistory,
  world : World,
  camera : EntityId,
  home_component : ComponentTypeId,
) -> Bool {
  let tf = world.transform_component()
  match world.component_bytes(camera, tf) {
    Some(bytes) =>
      set_or_add_camera_control_component_bytes_tracked(
        history, world, camera, home_component, bytes,
      )
    None => false
  }
}

///|
/// Builds a perspective CameraLens component row.
fn camera_lens_perspective_bytes(
  near : Float,
  far : Float,
  aspect : Float,
  fov_y_rad : Float,
  flags : Float,
) -> FixedArray[Byte] {
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
  bytes
}

///|
/// Builds an orthographic CameraLens component row.
fn camera_lens_orthographic_bytes(
  near : Float,
  far : Float,
  aspect : Float,
  ortho_half_height : Float,
  flags : Float,
) -> FixedArray[Byte] {
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
  bytes
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
  world.add_component_bytes(
    camera,
    lens_component,
    camera_lens_perspective_bytes(near, far, aspect, fov_y_rad, flags),
  )
}

///|
/// Adds a perspective lens component through WorldHistory.
pub fn add_camera_lens_perspective_tracked(
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
  history.add_component_bytes(
    world,
    camera,
    lens_component,
    camera_lens_perspective_bytes(near, far, aspect, fov_y_rad, flags),
  )
}

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
/// Finishes a tracked camera-control transaction opened by a helper.
fn finish_camera_control_tracked_transaction(
  history : WorldHistory,
  opened : Bool,
  ok : Bool,
) -> Bool {
  if !opened {
    return ok
  }
  if ok {
    history.commit_transaction()
  } else {
    ignore(history.cancel_transaction())
    false
  }
}

///|
/// Sets up an orbit orthographic camera through WorldHistory as one operation when possible.
pub fn setup_orbit_orthographic_camera_tracked(
  history : WorldHistory,
  world : World,
  camera : EntityId,
  desc : OrbitOrthographicCameraDesc,
) -> Bool {
  let opened = history.begin_transaction("setup_orbit_orthographic_camera")
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
    None =>
      return finish_camera_control_tracked_transaction(history, opened, false)
  }
  let ok = history.set_transform_trs(
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
  finish_camera_control_tracked_transaction(history, opened, ok)
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
/// Writes Transform3D and GlobalTransform from orbit state through WorldHistory.
pub fn sync_orbit_camera_transform_component_tracked(
  history : WorldHistory,
  world : World,
  camera : EntityId,
  orbit_component : ComponentTypeId,
  home_component : ComponentTypeId,
) -> Bool {
  let opened = history.begin_transaction(
    "sync_orbit_camera_transform_component",
  )
  let orbit_row = match world.component_bytes(camera, orbit_component) {
    Some(bytes) => bytes
    None =>
      return finish_camera_control_tracked_transaction(history, opened, false)
  }
  let (yaw, pitch, pan_x, pan_y, _dolly, distance, reset_requested) = orbit_camera_pose_from_controller_view(
    orbit_row[:],
  )
  let ok = if reset_requested {
    let home_row = match world.component_bytes(camera, home_component) {
      Some(bytes) => bytes
      None =>
        return finish_camera_control_tracked_transaction(history, opened, false)
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
  finish_camera_control_tracked_transaction(history, opened, ok)
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
  System::new(
    "rhodonite/orbit_camera_blob_sync",
    phase,
    [gt, lens_component, orbit_component],
    [camera],
    fn(world, _ctx, _commands) {
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
