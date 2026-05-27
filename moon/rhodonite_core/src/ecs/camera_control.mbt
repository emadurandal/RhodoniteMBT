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
