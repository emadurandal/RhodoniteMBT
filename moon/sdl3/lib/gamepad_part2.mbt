/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///
/// Simple DirectMedia Layer
/// Copyright (C) 1997-2025 Sam Lantinga <slouken@libsdl.org>
///
/// This software is provided 'as-is', without any express or implied
/// warranty.  In no event will the authors be held liable for any damages
/// arising from the use of this software.
///
/// Permission is granted to anyone to use this software for any purpose,
/// including commercial applications, and to alter it and redistribute it
/// freely, subject to the following restrictions:
///
/// 1. The origin of this software must not be misrepresented; you must not
///    claim that you wrote the original software. If you use this software
///    in a product, an acknowledgment in the product documentation would be
///    appreciated but is not required.
/// 2. Altered source versions must be plainly marked as such, and must not be
///    misrepresented as being the original software.
/// 3. This notice may not be removed or altered from any source distribution.
///

///|
/// Convert a string into an SDL_GamepadButton enum.
///
/// ```c
/// extern SDL_DECLSPEC SDL_GamepadButton SDLCALL SDL_GetGamepadButtonFromString(const char *str);
/// ```
#owned(str)
extern "C" fn __sdl_GetGamepadButtonFromString(
  str : Bytes,
) -> SDL_GamepadButton = "SDL_GetGamepadButtonFromString"

///|
pub fn sdl_GetGamepadButtonFromString(str : String) -> SDL_GamepadButton {
  let c_str = string_to_cbytes(str)
  __sdl_GetGamepadButtonFromString(c_str)
}

///|
/// Convert from an SDL_GamepadButton enum to a string.
///
/// ```c
/// extern SDL_DECLSPEC const char * SDLCALL SDL_GetGamepadStringForButton(SDL_GamepadButton button);
/// ```
extern "C" fn __sdl_GetGamepadStringForButton(
  button : SDL_GamepadButton,
) -> CStr = "SDL_GetGamepadStringForButton"

///|
pub fn sdl_GetGamepadStringForButton(button : SDL_GamepadButton) -> String {
  let cstr = __sdl_GetGamepadStringForButton(button)
  let res = cstr.to_string()
  // Do not free cstr, it's a pointer to internal SDL memory
  res
}

///|
/// Query whether a gamepad has a given button.
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GamepadHasButton(SDL_Gamepad *gamepad, SDL_GamepadButton button);
/// ```
pub extern "C" fn sdl_GamepadHasButton(
  gamepad : SDL_Gamepad,
  button : SDL_GamepadButton,
) -> Bool = "SDL_GamepadHasButton"

///|
/// Get the current state of a button on a gamepad.
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetGamepadButton(SDL_Gamepad *gamepad, SDL_GamepadButton button);
/// ```
pub extern "C" fn sdl_GetGamepadButton(
  gamepad : SDL_Gamepad,
  button : SDL_GamepadButton,
) -> Bool = "SDL_GetGamepadButton"

///|
/// Get the label of a button on a gamepad.
///
/// ```c
/// extern SDL_DECLSPEC SDL_GamepadButtonLabel SDLCALL SDL_GetGamepadButtonLabelForType(SDL_GamepadType type, SDL_GamepadButton button);
/// ```
pub extern "C" fn sdl_GetGamepadButtonLabelForType(
  type_ : SDL_GamepadType,
  button : SDL_GamepadButton,
) -> SDL_GamepadButtonLabel = "SDL_GetGamepadButtonLabelForType"

///|
/// Get the label of a button on a gamepad.
///
/// ```c
/// extern SDL_DECLSPEC SDL_GamepadButtonLabel SDLCALL SDL_GetGamepadButtonLabel(SDL_Gamepad *gamepad, SDL_GamepadButton button);
/// ```
pub extern "C" fn sdl_GetGamepadButtonLabel(
  gamepad : SDL_Gamepad,
  button : SDL_GamepadButton,
) -> SDL_GamepadButtonLabel = "SDL_GetGamepadButtonLabel"

///|
/// Get the number of touchpads on a gamepad.
///
/// ```c
/// extern SDL_DECLSPEC int SDLCALL SDL_GetNumGamepadTouchpads(SDL_Gamepad *gamepad);
/// ```
pub extern "C" fn sdl_GetNumGamepadTouchpads(gamepad : SDL_Gamepad) -> Int = "SDL_GetNumGamepadTouchpads"

///| Get the number of supported simultaneous fingers on a touchpad on a game

///|
/// gamepad.
///
/// ```c
/// extern SDL_DECLSPEC int SDLCALL SDL_GetNumGamepadTouchpadFingers(SDL_Gamepad *gamepad, int touchpad);
/// ```
pub extern "C" fn sdl_GetNumGamepadTouchpadFingers(
  gamepad : SDL_Gamepad,
  touchpad : Int,
) -> Int = "SDL_GetNumGamepadTouchpadFingers"

///|
/// Get the current state of a finger on a touchpad on a gamepad.
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetGamepadTouchpadFinger(SDL_Gamepad *gamepad, int touchpad, int finger, bool *down, float *x, float *y, float *pressure);
/// ```
#owned(down, x, y, pressure)
extern "C" fn __sdl_GetGamepadTouchpadFinger(
  gamepad : SDL_Gamepad,
  touchpad : Int,
  finger : Int,
  down : FixedArray[Bool],
  x : FixedArray[Float],
  y : FixedArray[Float],
  pressure : FixedArray[Float],
) -> Bool = "SDL_GetGamepadTouchpadFinger"

///|
pub fn sdl_GetGamepadTouchpadFinger(
  gamepad : SDL_Gamepad,
  touchpad : Int,
  finger : Int,
) -> (Bool, Bool, Float, Float, Float) {
  let down = FixedArray::make(1, false)
  let x : FixedArray[Float] = FixedArray::make(1, 0.0)
  let y : FixedArray[Float] = FixedArray::make(1, 0.0)
  let pressure : FixedArray[Float] = FixedArray::make(1, 0.0)
  let success = __sdl_GetGamepadTouchpadFinger(
    gamepad, touchpad, finger, down, x, y, pressure,
  )
  (success, down[0], x[0], y[0], pressure[0])
}

///|
/// Return whether a gamepad has a particular sensor.
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GamepadHasSensor(SDL_Gamepad *gamepad, SDL_SensorType type);
/// ```
pub extern "C" fn sdl_GamepadHasSensor(
  gamepad : SDL_Gamepad,
  type_ : SDL_SensorType,
) -> Bool = "SDL_GamepadHasSensor"

///|
/// Set whether data reporting for a gamepad sensor is enabled.
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetGamepadSensorEnabled(SDL_Gamepad *gamepad, SDL_SensorType type, bool enabled);
/// ```
pub extern "C" fn sdl_SetGamepadSensorEnabled(
  gamepad : SDL_Gamepad,
  type_ : SDL_SensorType,
  enabled : Bool,
) -> Bool = "SDL_SetGamepadSensorEnabled"

///|
/// Query whether sensor data reporting is enabled for a gamepad.
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GamepadSensorEnabled(SDL_Gamepad *gamepad, SDL_SensorType type);
/// ```
pub extern "C" fn sdl_GamepadSensorEnabled(
  gamepad : SDL_Gamepad,
  type_ : SDL_SensorType,
) -> Bool = "SDL_GamepadSensorEnabled"

///|
/// Get the data rate (number of events per second) of a gamepad sensor.
///
/// ```c
/// extern SDL_DECLSPEC float SDLCALL SDL_GetGamepadSensorDataRate(SDL_Gamepad *gamepad, SDL_SensorType type);
/// ```
pub extern "C" fn sdl_GetGamepadSensorDataRate(
  gamepad : SDL_Gamepad,
  type_ : SDL_SensorType,
) -> Float = "SDL_GetGamepadSensorDataRate"

///|
/// Get the current state of a gamepad sensor.
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetGamepadSensorData(SDL_Gamepad *gamepad, SDL_SensorType type, float *data, int num_values);
/// ```
#owned(data)
pub extern "C" fn __sdl_GetGamepadSensorData(
  gamepad : SDL_Gamepad,
  type_ : SDL_SensorType,
  data : FixedArray[Float],
  num_values : Int,
) -> Bool = "SDL_GetGamepadSensorData"

///|
pub fn sdl_GetGamepadSensorData(
  gamepad : SDL_Gamepad,
  type_ : SDL_SensorType,
  num_values : Int,
) -> (Bool, Array[Float]) {
  let data : FixedArray[Float] = FixedArray::make(num_values, 0.0)
  let success = __sdl_GetGamepadSensorData(gamepad, type_, data, num_values)
  let res = Array::new()
  for i = 0; i < num_values; i = i + 1 {
    res.push(data[i])
  }
  (success, res)
}

///|
/// Start a rumble effect on a gamepad.
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RumbleGamepad(SDL_Gamepad *gamepad, Uint16 low_frequency_rumble, Uint16 high_frequency_rumble, Uint32 duration_ms);
/// ```
pub extern "C" fn sdl_RumbleGamepad(
  gamepad : SDL_Gamepad,
  low_frequency_rumble : UInt16,
  high_frequency_rumble : UInt16,
  duration_ms : UInt,
) -> Bool = "SDL_RumbleGamepad"

///|
/// Start a rumble effect in the gamepad's triggers.
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RumbleGamepadTriggers(SDL_Gamepad *gamepad, Uint16 left_rumble, Uint16 right_rumble, Uint32 duration_ms);
/// ```
pub extern "C" fn sdl_RumbleGamepadTriggers(
  gamepad : SDL_Gamepad,
  left_rumble : UInt16,
  right_rumble : UInt16,
  duration_ms : UInt,
) -> Bool = "SDL_RumbleGamepadTriggers"

///|
/// Update a gamepad's LED color.
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetGamepadLED(SDL_Gamepad *gamepad, Uint8 red, Uint8 green, Uint8 blue);
/// ```
pub extern "C" fn sdl_SetGamepadLED(
  gamepad : SDL_Gamepad,
  red : Byte,
  green : Byte,
  blue : Byte,
) -> Bool = "SDL_SetGamepadLED"

///|
/// Send a gamepad specific effect packet.
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SendGamepadEffect(SDL_Gamepad *gamepad, const void *data, int size);
/// ```
pub extern "C" fn sdl_SendGamepadEffect(
  gamepad : SDL_Gamepad,
  data : VoidPtr,
  size : Int,
) -> Bool = "SDL_SendGamepadEffect"

///|
/// Close a gamepad previously opened with SDL_OpenGamepad().
///
/// ```c
/// extern SDL_DECLSPEC void SDLCALL SDL_CloseGamepad(SDL_Gamepad *gamepad);
/// ```
pub extern "C" fn sdl_CloseGamepad(gamepad : SDL_Gamepad) -> Unit = "SDL_CloseGamepad"

///| Return the sfSymbolsName for a given button on a gamepad on Apple

///|
/// platforms.
///
/// ```c
/// extern SDL_DECLSPEC const char * SDLCALL SDL_GetGamepadAppleSFSymbolsNameForButton(SDL_Gamepad *gamepad, SDL_GamepadButton button);
/// ```
extern "C" fn __sdl_GetGamepadAppleSFSymbolsNameForButton(
  gamepad : SDL_Gamepad,
  button : SDL_GamepadButton,
) -> CStr = "SDL_GetGamepadAppleSFSymbolsNameForButton"

///|
pub fn sdl_GetGamepadAppleSFSymbolsNameForButton(
  gamepad : SDL_Gamepad,
  button : SDL_GamepadButton,
) -> String {
  let cstr = __sdl_GetGamepadAppleSFSymbolsNameForButton(gamepad, button)
  let res = cstr.to_string()
  // Do not free cstr, it's a pointer to internal SDL memory
  res
}

///|
/// Return the sfSymbolsName for a given axis on a gamepad on Apple platforms.
///
/// ```c
/// extern SDL_DECLSPEC const char * SDLCALL SDL_GetGamepadAppleSFSymbolsNameForAxis(SDL_Gamepad *gamepad, SDL_GamepadAxis axis);
/// ```
extern "C" fn __sdl_GetGamepadAppleSFSymbolsNameForAxis(
  gamepad : SDL_Gamepad,
  axis : SDL_GamepadAxis,
) -> CStr = "SDL_GetGamepadAppleSFSymbolsNameForAxis"

///|
pub fn sdl_GetGamepadAppleSFSymbolsNameForAxis(
  gamepad : SDL_Gamepad,
  axis : SDL_GamepadAxis,
) -> String {
  let cstr = __sdl_GetGamepadAppleSFSymbolsNameForAxis(gamepad, axis)
  let res = cstr.to_string()
  // Do not free cstr, it's a pointer to internal SDL memory
  res
}
