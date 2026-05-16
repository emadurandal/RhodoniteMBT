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
/// Builds a canonical browser-style physical key code.
fn KeyCode::browser_code(name : String) -> KeyCode {
  KeyCode::new(name)
}

///|
/// Returns the canonical `Escape` key code.
pub fn KeyCode::escape() -> KeyCode {
  KeyCode::browser_code("Escape")
}

///|
/// Returns the canonical `F1` key code.
pub fn KeyCode::f1() -> KeyCode {
  KeyCode::browser_code("F1")
}

///|
/// Returns the canonical `F2` key code.
pub fn KeyCode::f2() -> KeyCode {
  KeyCode::browser_code("F2")
}

///|
/// Returns the canonical `F3` key code.
pub fn KeyCode::f3() -> KeyCode {
  KeyCode::browser_code("F3")
}

///|
/// Returns the canonical `F4` key code.
pub fn KeyCode::f4() -> KeyCode {
  KeyCode::browser_code("F4")
}

///|
/// Returns the canonical `F5` key code.
pub fn KeyCode::f5() -> KeyCode {
  KeyCode::browser_code("F5")
}

///|
/// Returns the canonical `F6` key code.
pub fn KeyCode::f6() -> KeyCode {
  KeyCode::browser_code("F6")
}

///|
/// Returns the canonical `F7` key code.
pub fn KeyCode::f7() -> KeyCode {
  KeyCode::browser_code("F7")
}

///|
/// Returns the canonical `F8` key code.
pub fn KeyCode::f8() -> KeyCode {
  KeyCode::browser_code("F8")
}

///|
/// Returns the canonical `F9` key code.
pub fn KeyCode::f9() -> KeyCode {
  KeyCode::browser_code("F9")
}

///|
/// Returns the canonical `F10` key code.
pub fn KeyCode::f10() -> KeyCode {
  KeyCode::browser_code("F10")
}

///|
/// Returns the canonical `F11` key code.
pub fn KeyCode::f11() -> KeyCode {
  KeyCode::browser_code("F11")
}

///|
/// Returns the canonical `F12` key code.
pub fn KeyCode::f12() -> KeyCode {
  KeyCode::browser_code("F12")
}

///|
/// Returns the canonical `Backquote` key code.
pub fn KeyCode::backquote() -> KeyCode {
  KeyCode::browser_code("Backquote")
}

///|
/// Returns the canonical `Digit0` key code.
pub fn KeyCode::digit_0() -> KeyCode {
  KeyCode::browser_code("Digit0")
}

///|
/// Returns the canonical `Digit1` key code.
pub fn KeyCode::digit_1() -> KeyCode {
  KeyCode::browser_code("Digit1")
}

///|
/// Returns the canonical `Digit2` key code.
pub fn KeyCode::digit_2() -> KeyCode {
  KeyCode::browser_code("Digit2")
}

///|
/// Returns the canonical `Digit3` key code.
pub fn KeyCode::digit_3() -> KeyCode {
  KeyCode::browser_code("Digit3")
}

///|
/// Returns the canonical `Digit4` key code.
pub fn KeyCode::digit_4() -> KeyCode {
  KeyCode::browser_code("Digit4")
}

///|
/// Returns the canonical `Digit5` key code.
pub fn KeyCode::digit_5() -> KeyCode {
  KeyCode::browser_code("Digit5")
}

///|
/// Returns the canonical `Digit6` key code.
pub fn KeyCode::digit_6() -> KeyCode {
  KeyCode::browser_code("Digit6")
}

///|
/// Returns the canonical `Digit7` key code.
pub fn KeyCode::digit_7() -> KeyCode {
  KeyCode::browser_code("Digit7")
}

///|
/// Returns the canonical `Digit8` key code.
pub fn KeyCode::digit_8() -> KeyCode {
  KeyCode::browser_code("Digit8")
}

///|
/// Returns the canonical `Digit9` key code.
pub fn KeyCode::digit_9() -> KeyCode {
  KeyCode::browser_code("Digit9")
}

///|
/// Returns the canonical `Minus` key code.
pub fn KeyCode::minus() -> KeyCode {
  KeyCode::browser_code("Minus")
}

///|
/// Returns the canonical `Equal` key code.
pub fn KeyCode::equal() -> KeyCode {
  KeyCode::browser_code("Equal")
}

///|
/// Returns the canonical `Backspace` key code.
pub fn KeyCode::backspace() -> KeyCode {
  KeyCode::browser_code("Backspace")
}

///|
/// Returns the canonical `Tab` key code.
pub fn KeyCode::tab() -> KeyCode {
  KeyCode::browser_code("Tab")
}

///|
/// Returns the canonical `KeyA` key code.
pub fn KeyCode::key_a() -> KeyCode {
  KeyCode::browser_code("KeyA")
}

///|
/// Returns the canonical `KeyB` key code.
pub fn KeyCode::key_b() -> KeyCode {
  KeyCode::browser_code("KeyB")
}

///|
/// Returns the canonical `KeyC` key code.
pub fn KeyCode::key_c() -> KeyCode {
  KeyCode::browser_code("KeyC")
}

///|
/// Returns the canonical `KeyD` key code.
pub fn KeyCode::key_d() -> KeyCode {
  KeyCode::browser_code("KeyD")
}

///|
/// Returns the canonical `KeyE` key code.
pub fn KeyCode::key_e() -> KeyCode {
  KeyCode::browser_code("KeyE")
}

///|
/// Returns the canonical `KeyF` key code.
pub fn KeyCode::key_f() -> KeyCode {
  KeyCode::browser_code("KeyF")
}

///|
/// Returns the canonical `KeyG` key code.
pub fn KeyCode::key_g() -> KeyCode {
  KeyCode::browser_code("KeyG")
}

///|
/// Returns the canonical `KeyH` key code.
pub fn KeyCode::key_h() -> KeyCode {
  KeyCode::browser_code("KeyH")
}

///|
/// Returns the canonical `KeyI` key code.
pub fn KeyCode::key_i() -> KeyCode {
  KeyCode::browser_code("KeyI")
}

///|
/// Returns the canonical `KeyJ` key code.
pub fn KeyCode::key_j() -> KeyCode {
  KeyCode::browser_code("KeyJ")
}

///|
/// Returns the canonical `KeyK` key code.
pub fn KeyCode::key_k() -> KeyCode {
  KeyCode::browser_code("KeyK")
}

///|
/// Returns the canonical `KeyL` key code.
pub fn KeyCode::key_l() -> KeyCode {
  KeyCode::browser_code("KeyL")
}

///|
/// Returns the canonical `KeyM` key code.
pub fn KeyCode::key_m() -> KeyCode {
  KeyCode::browser_code("KeyM")
}

///|
/// Returns the canonical `KeyN` key code.
pub fn KeyCode::key_n() -> KeyCode {
  KeyCode::browser_code("KeyN")
}

///|
/// Returns the canonical `KeyO` key code.
pub fn KeyCode::key_o() -> KeyCode {
  KeyCode::browser_code("KeyO")
}

///|
/// Returns the canonical `KeyP` key code.
pub fn KeyCode::key_p() -> KeyCode {
  KeyCode::browser_code("KeyP")
}

///|
/// Returns the canonical `KeyQ` key code.
pub fn KeyCode::key_q() -> KeyCode {
  KeyCode::browser_code("KeyQ")
}

///|
/// Returns the canonical `KeyR` key code.
pub fn KeyCode::key_r() -> KeyCode {
  KeyCode::browser_code("KeyR")
}

///|
/// Returns the canonical `KeyS` key code.
pub fn KeyCode::key_s() -> KeyCode {
  KeyCode::browser_code("KeyS")
}

///|
/// Returns the canonical `KeyT` key code.
pub fn KeyCode::key_t() -> KeyCode {
  KeyCode::browser_code("KeyT")
}

///|
/// Returns the canonical `KeyU` key code.
pub fn KeyCode::key_u() -> KeyCode {
  KeyCode::browser_code("KeyU")
}

///|
/// Returns the canonical `KeyV` key code.
pub fn KeyCode::key_v() -> KeyCode {
  KeyCode::browser_code("KeyV")
}

///|
/// Returns the canonical `KeyW` key code.
pub fn KeyCode::key_w() -> KeyCode {
  KeyCode::browser_code("KeyW")
}

///|
/// Returns the canonical `KeyX` key code.
pub fn KeyCode::key_x() -> KeyCode {
  KeyCode::browser_code("KeyX")
}

///|
/// Returns the canonical `KeyY` key code.
pub fn KeyCode::key_y() -> KeyCode {
  KeyCode::browser_code("KeyY")
}

///|
/// Returns the canonical `KeyZ` key code.
pub fn KeyCode::key_z() -> KeyCode {
  KeyCode::browser_code("KeyZ")
}

///|
/// Returns the canonical `BracketLeft` key code.
pub fn KeyCode::bracket_left() -> KeyCode {
  KeyCode::browser_code("BracketLeft")
}

///|
/// Returns the canonical `BracketRight` key code.
pub fn KeyCode::bracket_right() -> KeyCode {
  KeyCode::browser_code("BracketRight")
}

///|
/// Returns the canonical `Backslash` key code.
pub fn KeyCode::backslash() -> KeyCode {
  KeyCode::browser_code("Backslash")
}

///|
/// Returns the canonical `CapsLock` key code.
pub fn KeyCode::caps_lock() -> KeyCode {
  KeyCode::browser_code("CapsLock")
}

///|
/// Returns the canonical `Semicolon` key code.
pub fn KeyCode::semicolon() -> KeyCode {
  KeyCode::browser_code("Semicolon")
}

///|
/// Returns the canonical `Quote` key code.
pub fn KeyCode::quote() -> KeyCode {
  KeyCode::browser_code("Quote")
}

///|
/// Returns the canonical `Enter` key code.
pub fn KeyCode::enter() -> KeyCode {
  KeyCode::browser_code("Enter")
}

///|
/// Returns the canonical `ShiftLeft` key code.
pub fn KeyCode::shift_left() -> KeyCode {
  KeyCode::browser_code("ShiftLeft")
}

///|
/// Returns the canonical `Comma` key code.
pub fn KeyCode::comma() -> KeyCode {
  KeyCode::browser_code("Comma")
}

///|
/// Returns the canonical `Period` key code.
pub fn KeyCode::period() -> KeyCode {
  KeyCode::browser_code("Period")
}

///|
/// Returns the canonical `Slash` key code.
pub fn KeyCode::slash() -> KeyCode {
  KeyCode::browser_code("Slash")
}

///|
/// Returns the canonical `ShiftRight` key code.
pub fn KeyCode::shift_right() -> KeyCode {
  KeyCode::browser_code("ShiftRight")
}

///|
/// Returns the canonical `ControlLeft` key code.
pub fn KeyCode::control_left() -> KeyCode {
  KeyCode::browser_code("ControlLeft")
}

///|
/// Returns the canonical `AltLeft` key code.
pub fn KeyCode::alt_left() -> KeyCode {
  KeyCode::browser_code("AltLeft")
}

///|
/// Returns the canonical `Space` key code.
pub fn KeyCode::space() -> KeyCode {
  KeyCode::browser_code("Space")
}

///|
/// Returns the canonical `AltRight` key code.
pub fn KeyCode::alt_right() -> KeyCode {
  KeyCode::browser_code("AltRight")
}

///|
/// Returns the canonical `MetaLeft` key code.
pub fn KeyCode::meta_left() -> KeyCode {
  KeyCode::browser_code("MetaLeft")
}

///|
/// Returns the canonical `MetaRight` key code.
pub fn KeyCode::meta_right() -> KeyCode {
  KeyCode::browser_code("MetaRight")
}

///|
/// Returns the canonical `ControlRight` key code.
pub fn KeyCode::control_right() -> KeyCode {
  KeyCode::browser_code("ControlRight")
}

///|
/// Returns the canonical `ArrowLeft` key code.
pub fn KeyCode::arrow_left() -> KeyCode {
  KeyCode::browser_code("ArrowLeft")
}

///|
/// Returns the canonical `ArrowDown` key code.
pub fn KeyCode::arrow_down() -> KeyCode {
  KeyCode::browser_code("ArrowDown")
}

///|
/// Returns the canonical `ArrowUp` key code.
pub fn KeyCode::arrow_up() -> KeyCode {
  KeyCode::browser_code("ArrowUp")
}

///|
/// Returns the canonical `ArrowRight` key code.
pub fn KeyCode::arrow_right() -> KeyCode {
  KeyCode::browser_code("ArrowRight")
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
