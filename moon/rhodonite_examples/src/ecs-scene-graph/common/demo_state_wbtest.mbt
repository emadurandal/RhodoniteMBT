/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Returns the Undo/Redo sample shortcut selected by a single key-down event.
fn shortcut_for_key_event(
  key : @input.KeyCode,
  modifiers : @input.Modifiers,
  repeat? : Bool = false,
) -> UndoRedoShortcut {
  let input = @input.InputState::new()
  input.enqueue_event(KeyDown(key, modifiers, repeat))
  input.begin_frame()
  undo_redo_shortcut_from_input(input)
}

///|
test "undo redo shortcuts require command modifiers for history commands" {
  let none = @input.Modifiers::none()
  let ctrl = @input.Modifiers::new(false, true, false, false)
  let meta = @input.Modifiers::new(false, false, false, true)
  let ctrl_shift = @input.Modifiers::new(true, true, false, false)
  let meta_shift = @input.Modifiers::new(true, false, false, true)
  assert_true(
    shortcut_for_key_event(@input.KeyCode::key_z(), ctrl) is UndoShortcut,
  )
  assert_true(
    shortcut_for_key_event(@input.KeyCode::key_z(), meta) is UndoShortcut,
  )
  assert_true(
    shortcut_for_key_event(@input.KeyCode::key_z(), ctrl_shift) is RedoShortcut,
  )
  assert_true(
    shortcut_for_key_event(@input.KeyCode::key_z(), meta_shift) is RedoShortcut,
  )
  assert_true(
    shortcut_for_key_event(@input.KeyCode::key_y(), ctrl) is RedoShortcut,
  )
  assert_true(
    shortcut_for_key_event(@input.KeyCode::key_y(), meta) is RedoShortcut,
  )
  assert_true(
    shortcut_for_key_event(@input.KeyCode::key_z(), none) is NoShortcut,
  )
  assert_true(
    shortcut_for_key_event(@input.KeyCode::key_y(), none) is NoShortcut,
  )
}

///|
test "undo redo move shortcuts remain unmodified key presses" {
  let none = @input.Modifiers::none()
  let ctrl = @input.Modifiers::new(false, true, false, false)
  assert_true(
    shortcut_for_key_event(@input.KeyCode::key_m(), none) is ApplyMove,
  )
  assert_true(
    shortcut_for_key_event(@input.KeyCode::space(), none) is ApplyMove,
  )
  assert_true(
    shortcut_for_key_event(@input.KeyCode::enter(), none) is ApplyMove,
  )
  assert_true(
    shortcut_for_key_event(@input.KeyCode::key_m(), ctrl) is NoShortcut,
  )
}

///|
test "undo redo shortcuts ignore repeated key-down events" {
  let ctrl = @input.Modifiers::new(false, true, false, false)
  assert_true(
    shortcut_for_key_event(@input.KeyCode::key_z(), ctrl, repeat=true)
    is NoShortcut,
  )
}
