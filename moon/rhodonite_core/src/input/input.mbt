///|
/// Implements `KeyCode::new`.
pub fn KeyCode::new(name : String) -> KeyCode {
  { name, }
}

///|
/// Implements `KeyCode::name`.
pub fn KeyCode::name(self : KeyCode) -> String {
  self.name
}

///|
/// Builds an empty modifier snapshot.
pub fn Modifiers::none() -> Modifiers {
  { shift: false, ctrl: false, alt: false, meta: false }
}

///|
/// Implements `Modifiers::new`.
pub fn Modifiers::new(
  shift : Bool,
  ctrl : Bool,
  alt : Bool,
  meta : Bool,
) -> Modifiers {
  { shift, ctrl, alt, meta }
}

///|
/// Implements `Modifiers::shift`.
pub fn Modifiers::shift(self : Modifiers) -> Bool {
  self.shift
}

///|
/// Implements `Modifiers::ctrl`.
pub fn Modifiers::ctrl(self : Modifiers) -> Bool {
  self.ctrl
}

///|
/// Implements `Modifiers::alt`.
pub fn Modifiers::alt(self : Modifiers) -> Bool {
  self.alt
}

///|
/// Implements `Modifiers::meta`.
pub fn Modifiers::meta(self : Modifiers) -> Bool {
  self.meta
}

///|
/// Reports whether a key array contains a key.
fn key_array_contains(keys : Array[KeyCode], key : KeyCode) -> Bool {
  for i = 0; i < keys.length(); i = i + 1 {
    if keys[i] == key {
      return true
    }
  }
  false
}

///|
/// Adds a key if it is not already present.
fn key_array_push_unique(keys : Array[KeyCode], key : KeyCode) -> Unit {
  if !key_array_contains(keys, key) {
    keys.push(key)
  }
}

///|
/// Removes a key if present.
fn key_array_remove(keys : Array[KeyCode], key : KeyCode) -> Unit {
  for i = 0; i < keys.length(); i = i + 1 {
    if keys[i] == key {
      let last = keys.length() - 1
      keys[i] = keys[last]
      let _ = keys.pop()
      return
    }
  }
}

///|
/// Copies a key array for read-only public results.
fn copy_key_array(keys : Array[KeyCode]) -> Array[KeyCode] {
  let out : Array[KeyCode] = []
  for i = 0; i < keys.length(); i = i + 1 {
    out.push(keys[i])
  }
  out
}

///|
/// Reports whether a mouse button array contains a button.
fn mouse_button_array_contains(
  buttons : Array[MouseButton],
  button : MouseButton,
) -> Bool {
  for i = 0; i < buttons.length(); i = i + 1 {
    if buttons[i] == button {
      return true
    }
  }
  false
}

///|
/// Adds a mouse button if it is not already present.
fn mouse_button_array_push_unique(
  buttons : Array[MouseButton],
  button : MouseButton,
) -> Unit {
  if !mouse_button_array_contains(buttons, button) {
    buttons.push(button)
  }
}

///|
/// Removes a mouse button if present.
fn mouse_button_array_remove(
  buttons : Array[MouseButton],
  button : MouseButton,
) -> Unit {
  for i = 0; i < buttons.length(); i = i + 1 {
    if buttons[i] == button {
      let last = buttons.length() - 1
      buttons[i] = buttons[last]
      let _ = buttons.pop()
      return
    }
  }
}

///|
/// Copies a mouse button array for read-only public results.
fn copy_mouse_button_array(buttons : Array[MouseButton]) -> Array[MouseButton] {
  let out : Array[MouseButton] = []
  for i = 0; i < buttons.length(); i = i + 1 {
    out.push(buttons[i])
  }
  out
}

///|
/// Copies an event array for read-only public results.
fn copy_input_event_array(events : Array[InputEvent]) -> Array[InputEvent] {
  let out : Array[InputEvent] = []
  for i = 0; i < events.length(); i = i + 1 {
    out.push(events[i])
  }
  out
}

///|
/// Implements `InputState::new`.
pub fn InputState::new() -> InputState {
  {
    keys_down: [],
    keys_pressed: [],
    keys_released: [],
    mouse_buttons_down: [],
    mouse_buttons_pressed: [],
    mouse_buttons_released: [],
    pointer_x: (0.0 : Float),
    pointer_y: (0.0 : Float),
    pointer_delta_x: (0.0 : Float),
    pointer_delta_y: (0.0 : Float),
    wheel_delta_x: (0.0 : Float),
    wheel_delta_y: (0.0 : Float),
    events: [],
    queued_events: [],
  }
}

///|
/// Clears one-frame state and applies events queued since the previous frame.
pub fn InputState::begin_frame(self : InputState) -> Unit {
  self.keys_pressed.clear()
  self.keys_released.clear()
  self.mouse_buttons_pressed.clear()
  self.mouse_buttons_released.clear()
  self.pointer_delta_x = (0.0 : Float)
  self.pointer_delta_y = (0.0 : Float)
  self.wheel_delta_x = (0.0 : Float)
  self.wheel_delta_y = (0.0 : Float)
  self.events.clear()
  for i = 0; i < self.queued_events.length(); i = i + 1 {
    self.apply_event_to_frame(self.queued_events[i])
  }
  self.queued_events.clear()
}

///|
/// Queues an input event for the next `begin_frame` call.
pub fn InputState::enqueue_event(self : InputState, event : InputEvent) -> Unit {
  self.queued_events.push(event)
}

///|
/// Applies an input event to the current frame immediately. Use this only from
/// adapters that poll after `begin_frame`.
pub fn InputState::apply_event(self : InputState, event : InputEvent) -> Unit {
  self.apply_event_to_frame(event)
}

///|
/// Updates current and one-frame state from one normalized input event.
fn InputState::apply_event_to_frame(
  self : InputState,
  event : InputEvent,
) -> Unit {
  match event {
    KeyDown(key, _, repeat) => {
      if !repeat && !key_array_contains(self.keys_down, key) {
        key_array_push_unique(self.keys_pressed, key)
      }
      key_array_push_unique(self.keys_down, key)
    }
    KeyUp(key, _) => {
      if key_array_contains(self.keys_down, key) {
        key_array_push_unique(self.keys_released, key)
      }
      key_array_remove(self.keys_down, key)
    }
    TextInput(_) => ()
    PointerMove(x, y) => {
      self.pointer_delta_x = self.pointer_delta_x + x - self.pointer_x
      self.pointer_delta_y = self.pointer_delta_y + y - self.pointer_y
      self.pointer_x = x
      self.pointer_y = y
    }
    MouseDown(button, x, y) => {
      self.apply_event_to_frame(PointerMove(x, y))
      if !mouse_button_array_contains(self.mouse_buttons_down, button) {
        mouse_button_array_push_unique(self.mouse_buttons_pressed, button)
      }
      mouse_button_array_push_unique(self.mouse_buttons_down, button)
    }
    MouseUp(button, x, y) => {
      self.apply_event_to_frame(PointerMove(x, y))
      if mouse_button_array_contains(self.mouse_buttons_down, button) {
        mouse_button_array_push_unique(self.mouse_buttons_released, button)
      }
      mouse_button_array_remove(self.mouse_buttons_down, button)
    }
    Wheel(delta_x, delta_y) => {
      self.wheel_delta_x = self.wheel_delta_x + delta_x
      self.wheel_delta_y = self.wheel_delta_y + delta_y
    }
    FocusLost => {
      self.keys_down.clear()
      self.mouse_buttons_down.clear()
    }
  }
  self.events.push(event)
}

///|
/// Reports whether a key is currently held.
pub fn InputState::key_down(self : InputState, key : KeyCode) -> Bool {
  key_array_contains(self.keys_down, key)
}

///|
/// Reports whether a key transitioned from up to down this frame.
pub fn InputState::key_pressed(self : InputState, key : KeyCode) -> Bool {
  key_array_contains(self.keys_pressed, key)
}

///|
/// Reports whether a key transitioned from down to up this frame.
pub fn InputState::key_released(self : InputState, key : KeyCode) -> Bool {
  key_array_contains(self.keys_released, key)
}

///|
/// Returns a copy of keys currently held.
pub fn InputState::keys_down(self : InputState) -> Array[KeyCode] {
  copy_key_array(self.keys_down)
}

///|
/// Reports whether a mouse button is currently held.
pub fn InputState::mouse_down(self : InputState, button : MouseButton) -> Bool {
  mouse_button_array_contains(self.mouse_buttons_down, button)
}

///|
/// Reports whether a mouse button transitioned from up to down this frame.
pub fn InputState::mouse_pressed(
  self : InputState,
  button : MouseButton,
) -> Bool {
  mouse_button_array_contains(self.mouse_buttons_pressed, button)
}

///|
/// Reports whether a mouse button transitioned from down to up this frame.
pub fn InputState::mouse_released(
  self : InputState,
  button : MouseButton,
) -> Bool {
  mouse_button_array_contains(self.mouse_buttons_released, button)
}

///|
/// Returns a copy of mouse buttons currently held.
pub fn InputState::mouse_buttons_down(self : InputState) -> Array[MouseButton] {
  copy_mouse_button_array(self.mouse_buttons_down)
}

///|
/// Returns the current pointer x coordinate in platform surface coordinates.
pub fn InputState::pointer_x(self : InputState) -> Float {
  self.pointer_x
}

///|
/// Returns the current pointer y coordinate in platform surface coordinates.
pub fn InputState::pointer_y(self : InputState) -> Float {
  self.pointer_y
}

///|
/// Returns accumulated pointer x movement for this frame.
pub fn InputState::pointer_delta_x(self : InputState) -> Float {
  self.pointer_delta_x
}

///|
/// Returns accumulated pointer y movement for this frame.
pub fn InputState::pointer_delta_y(self : InputState) -> Float {
  self.pointer_delta_y
}

///|
/// Returns accumulated horizontal wheel movement for this frame.
pub fn InputState::wheel_delta_x(self : InputState) -> Float {
  self.wheel_delta_x
}

///|
/// Returns accumulated vertical wheel movement for this frame.
pub fn InputState::wheel_delta_y(self : InputState) -> Float {
  self.wheel_delta_y
}

///|
/// Returns events applied to this frame.
pub fn InputState::events(self : InputState) -> Array[InputEvent] {
  copy_input_event_array(self.events)
}

///|
/// Returns the number of events waiting for the next frame.
pub fn InputState::queued_event_count(self : InputState) -> Int {
  self.queued_events.length()
}
