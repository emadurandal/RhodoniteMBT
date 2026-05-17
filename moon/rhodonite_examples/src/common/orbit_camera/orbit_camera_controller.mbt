///|
/// Byte stride for the sample orbit camera controller component.
let orbit_camera_controller_stride : Int = 48

///|
/// Byte offset of the yaw field.
let orbit_yaw_offset : Int = 0

///|
/// Byte offset of the pitch field.
let orbit_pitch_offset : Int = 4

///|
/// Byte offset of the drag sensitivity field.
let orbit_sensitivity_offset : Int = 8

///|
/// Byte offset of the minimum pitch field.
let orbit_min_pitch_offset : Int = 12

///|
/// Byte offset of the maximum pitch field.
let orbit_max_pitch_offset : Int = 16

///|
/// Byte offset of the view-space horizontal pan field.
let orbit_pan_x_offset : Int = 20

///|
/// Byte offset of the view-space vertical pan field.
let orbit_pan_y_offset : Int = 24

///|
/// Byte offset of the pan sensitivity field.
let orbit_pan_sensitivity_offset : Int = 28

///|
/// Byte offset of the orthographic dolly scale field.
let orbit_dolly_offset : Int = 32

///|
/// Byte offset of the wheel dolly sensitivity field.
let orbit_dolly_sensitivity_offset : Int = 36

///|
/// Byte offset of the minimum dolly scale field.
let orbit_min_dolly_offset : Int = 40

///|
/// Byte offset of the maximum dolly scale field.
let orbit_max_dolly_offset : Int = 44

///|
/// Default orbit drag sensitivity in radians per pixel.
let default_orbit_sensitivity : Double = 0.006

///|
/// Default pan sensitivity in view-space units per pixel.
let default_pan_sensitivity : Double = 0.01

///|
/// Default dolly scale sensitivity per wheel delta unit.
let default_dolly_sensitivity : Double = 0.001

///|
/// Default lower pitch clamp in radians.
let default_min_pitch : Double = -1.25

///|
/// Default upper pitch clamp in radians.
let default_max_pitch : Double = 1.25

///|
/// Default lower dolly scale clamp.
let default_min_dolly : Double = 0.01

///|
/// Default upper dolly scale clamp.
let default_max_dolly : Double = 4.0

///|
/// Registers the sample orbit camera controller CPU component.
pub fn register_orbit_camera_controller_component(
  world : @ecs.World,
) -> @ecs.ComponentTypeId {
  world.register_cpu_component(
    "OrbitCameraController", orbit_camera_controller_stride,
  )
}

///|
/// Clamps an angle between lower and upper bounds.
fn clamp_angle(value : Double, lo : Double, hi : Double) -> Double {
  if value < lo {
    lo
  } else if value > hi {
    hi
  } else {
    value
  }
}

///|
/// Encodes one orbit camera controller payload.
fn orbit_camera_controller_bytes(
  yaw : Double,
  pitch : Double,
  sensitivity : Double,
  min_pitch : Double,
  max_pitch : Double,
  pan_x : Double,
  pan_y : Double,
  pan_sensitivity : Double,
  dolly : Double,
  dolly_sensitivity : Double,
  min_dolly : Double,
  max_dolly : Double,
) -> FixedArray[Byte] {
  let bytes = FixedArray::make(orbit_camera_controller_stride, (0 : Byte))
  @writes.put_f32_le(bytes, orbit_yaw_offset, yaw)
  @writes.put_f32_le(bytes, orbit_pitch_offset, pitch)
  @writes.put_f32_le(bytes, orbit_sensitivity_offset, sensitivity)
  @writes.put_f32_le(bytes, orbit_min_pitch_offset, min_pitch)
  @writes.put_f32_le(bytes, orbit_max_pitch_offset, max_pitch)
  @writes.put_f32_le(bytes, orbit_pan_x_offset, pan_x)
  @writes.put_f32_le(bytes, orbit_pan_y_offset, pan_y)
  @writes.put_f32_le(bytes, orbit_pan_sensitivity_offset, pan_sensitivity)
  @writes.put_f32_le(bytes, orbit_dolly_offset, dolly)
  @writes.put_f32_le(bytes, orbit_dolly_sensitivity_offset, dolly_sensitivity)
  @writes.put_f32_le(bytes, orbit_min_dolly_offset, min_dolly)
  @writes.put_f32_le(bytes, orbit_max_dolly_offset, max_dolly)
  bytes
}

///|
/// Adds an orbit camera controller component to a camera entity.
pub fn add_orbit_camera_controller(
  world : @ecs.World,
  camera : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
  yaw : Double,
  pitch : Double,
) -> Bool {
  world.add_component_bytes(
    camera,
    component,
    orbit_camera_controller_bytes(
      yaw, pitch, default_orbit_sensitivity, default_min_pitch, default_max_pitch,
      0.0, 0.0, default_pan_sensitivity, 1.0, default_dolly_sensitivity, default_min_dolly,
      default_max_dolly,
    ),
  )
}

///|
/// Reads the yaw and pitch from an orbit camera controller component.
pub fn orbit_camera_yaw_pitch(
  world : @ecs.World,
  camera : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
) -> (Double, Double) {
  match world.component_bytes(camera, component) {
    Some(bytes) =>
      (
        @writes.get_f32_le(bytes, orbit_yaw_offset),
        @writes.get_f32_le(bytes, orbit_pitch_offset),
      )
    None =>
      abort("orbit_camera_yaw_pitch: camera is missing OrbitCameraController")
  }
}

///|
/// Reads the full camera control transform fields from the component.
pub fn orbit_camera_transform(
  world : @ecs.World,
  camera : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
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
/// Updates an orbit camera controller from already-folded per-frame mouse values.
pub fn update_orbit_camera_controller_from_mouse_frame(
  world : @ecs.World,
  camera : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
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
      let yaw = @writes.get_f32_le(bytes, orbit_yaw_offset)
      let pitch = @writes.get_f32_le(bytes, orbit_pitch_offset)
      let sensitivity = @writes.get_f32_le(bytes, orbit_sensitivity_offset)
      let min_pitch = @writes.get_f32_le(bytes, orbit_min_pitch_offset)
      let max_pitch = @writes.get_f32_le(bytes, orbit_max_pitch_offset)
      let pan_x = @writes.get_f32_le(bytes, orbit_pan_x_offset)
      let pan_y = @writes.get_f32_le(bytes, orbit_pan_y_offset)
      let pan_sensitivity = @writes.get_f32_le(
        bytes, orbit_pan_sensitivity_offset,
      )
      let dolly = @writes.get_f32_le(bytes, orbit_dolly_offset)
      let dolly_sensitivity = @writes.get_f32_le(
        bytes, orbit_dolly_sensitivity_offset,
      )
      let min_dolly = @writes.get_f32_le(bytes, orbit_min_dolly_offset)
      let max_dolly = @writes.get_f32_le(bytes, orbit_max_dolly_offset)
      let mut next_yaw = yaw
      let mut next_pitch = pitch
      let mut next_pan_x = pan_x
      let mut next_pan_y = pan_y
      let mut next_dolly = dolly
      let mut changed = false
      if left_down && !left_pressed {
        next_yaw = yaw + pointer_delta_x.to_double() * sensitivity
        next_pitch = clamp_angle(
          pitch + pointer_delta_y.to_double() * sensitivity,
          min_pitch,
          max_pitch,
        )
        changed = true
      }
      if middle_down && !middle_pressed {
        next_pan_x = pan_x +
          pointer_delta_x.to_double() * pan_sensitivity * dolly
        next_pan_y = pan_y -
          pointer_delta_y.to_double() * pan_sensitivity * dolly
        changed = true
      }
      if wheel_delta_y != (0.0 : Float) {
        next_dolly = clamp_angle(
          dolly + wheel_delta_y.to_double() * dolly_sensitivity * dolly,
          min_dolly,
          max_dolly,
        )
        changed = true
      }
      if changed {
        world.set_component_bytes(
          camera,
          component,
          orbit_camera_controller_bytes(
            next_yaw, next_pitch, sensitivity, min_pitch, max_pitch, next_pan_x,
            next_pan_y, pan_sensitivity, next_dolly, dolly_sensitivity, min_dolly,
            max_dolly,
          ),
        )
      } else {
        false
      }
    }
    None => false
  }
}

///|
/// Updates an orbit camera controller from per-frame mouse drag input.
pub fn update_orbit_camera_controller_from_input(
  world : @ecs.World,
  camera : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
  input : @input.InputState,
) -> Bool {
  update_orbit_camera_controller_from_mouse_frame(
    world,
    camera,
    component,
    input.mouse_down(Left),
    input.mouse_pressed(Left),
    input.mouse_down(Middle),
    input.mouse_pressed(Middle),
    input.pointer_delta_x(),
    input.pointer_delta_y(),
    input.wheel_delta_y(),
  )
}
