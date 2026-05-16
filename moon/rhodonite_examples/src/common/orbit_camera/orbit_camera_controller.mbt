///|
/// Byte stride for the sample orbit camera controller component.
let orbit_camera_controller_stride : Int = 20

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
/// Default orbit drag sensitivity in radians per pixel.
let default_orbit_sensitivity : Double = 0.006

///|
/// Default lower pitch clamp in radians.
let default_min_pitch : Double = -1.25

///|
/// Default upper pitch clamp in radians.
let default_max_pitch : Double = 1.25

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
) -> FixedArray[Byte] {
  let bytes = FixedArray::make(orbit_camera_controller_stride, (0 : Byte))
  @writes.put_f32_le(bytes, orbit_yaw_offset, yaw)
  @writes.put_f32_le(bytes, orbit_pitch_offset, pitch)
  @writes.put_f32_le(bytes, orbit_sensitivity_offset, sensitivity)
  @writes.put_f32_le(bytes, orbit_min_pitch_offset, min_pitch)
  @writes.put_f32_le(bytes, orbit_max_pitch_offset, max_pitch)
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
/// Updates an orbit camera controller from per-frame mouse drag input.
pub fn update_orbit_camera_controller_from_input(
  world : @ecs.World,
  camera : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
  input : @input.InputState,
) -> Bool {
  match world.component_bytes(camera, component) {
    Some(bytes) => {
      let yaw = @writes.get_f32_le(bytes, orbit_yaw_offset)
      let pitch = @writes.get_f32_le(bytes, orbit_pitch_offset)
      let sensitivity = @writes.get_f32_le(bytes, orbit_sensitivity_offset)
      let min_pitch = @writes.get_f32_le(bytes, orbit_min_pitch_offset)
      let max_pitch = @writes.get_f32_le(bytes, orbit_max_pitch_offset)
      if input.mouse_down(Left) && !input.mouse_pressed(Left) {
        let next_yaw = yaw + input.pointer_delta_x().to_double() * sensitivity
        let next_pitch = clamp_angle(
          pitch + input.pointer_delta_y().to_double() * sensitivity,
          min_pitch,
          max_pitch,
        )
        world.set_component_bytes(
          camera,
          component,
          orbit_camera_controller_bytes(
            next_yaw, next_pitch, sensitivity, min_pitch, max_pitch,
          ),
        )
      } else {
        false
      }
    }
    None => false
  }
}
