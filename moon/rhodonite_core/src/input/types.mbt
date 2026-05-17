///|
/// Platform-stable keyboard key identifier. Use physical key names such as
/// `KeyW`, `ArrowLeft`, or `Space` so browser `KeyboardEvent.code` and native
/// scancodes can map to the same value.
pub(all) struct KeyCode {
  name : String
} derive(Eq)

///|
/// Mouse button identifier normalized across browser pointer events and SDL.
pub(all) enum MouseButton {
  Left
  Middle
  Right
  Back
  Forward
  Other(Int)
} derive(Eq)

///|
/// Keyboard modifier snapshot attached to input events when the source can
/// provide it.
pub(all) struct Modifiers {
  shift : Bool
  ctrl : Bool
  alt : Bool
  meta : Bool
} derive(Eq)

///|
/// Platform-independent input event queued by browser or native adapters.
pub(all) enum InputEvent {
  KeyDown(KeyCode, Modifiers, Bool)
  KeyUp(KeyCode, Modifiers)
  TextInput(String)
  PointerMove(Float, Float)
  MouseDown(MouseButton, Float, Float)
  MouseUp(MouseButton, Float, Float)
  Wheel(Float, Float)
  FocusLost
}

///|
/// Per-frame user input state. Adapters enqueue raw events between frames;
/// `begin_frame` folds queued events into current and one-frame state.
pub struct InputState {
  priv keys_down : Array[KeyCode]
  priv keys_pressed : Array[KeyCode]
  priv keys_released : Array[KeyCode]
  priv mouse_buttons_down : Array[MouseButton]
  priv mouse_buttons_pressed : Array[MouseButton]
  priv mouse_buttons_released : Array[MouseButton]
  priv mut pointer_x : Float
  priv mut pointer_y : Float
  priv mut pointer_delta_x : Float
  priv mut pointer_delta_y : Float
  priv mut wheel_delta_x : Float
  priv mut wheel_delta_y : Float
  priv events : Array[InputEvent]
  priv queued_events : Array[InputEvent]
}
