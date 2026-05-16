///|
test "queued key transitions are visible for one frame" {
  let input = InputState::new()
  let key = KeyCode::new("KeyW")
  input.enqueue_event(KeyDown(key, Modifiers::none(), false))
  assert_eq(input.queued_event_count(), 1)
  input.begin_frame()
  assert_true(input.key_down(key))
  assert_true(input.key_pressed(key))
  assert_true(!input.key_released(key))
  assert_eq(input.events().length(), 1)
  input.begin_frame()
  assert_true(input.key_down(key))
  assert_true(!input.key_pressed(key))
  input.enqueue_event(KeyUp(key, Modifiers::none()))
  input.begin_frame()
  assert_true(!input.key_down(key))
  assert_true(input.key_released(key))
}

///|
test "pointer mouse and wheel deltas reset every frame" {
  let input = InputState::new()
  input.enqueue_event(PointerMove((10.0 : Float), (20.0 : Float)))
  input.enqueue_event(MouseDown(Left, (14.0 : Float), (25.0 : Float)))
  input.enqueue_event(Wheel((1.0 : Float), (-2.0 : Float)))
  input.begin_frame()
  assert_eq(input.pointer_x(), (14.0 : Float))
  assert_eq(input.pointer_y(), (25.0 : Float))
  assert_eq(input.pointer_delta_x(), (14.0 : Float))
  assert_eq(input.pointer_delta_y(), (25.0 : Float))
  assert_eq(input.wheel_delta_x(), (1.0 : Float))
  assert_eq(input.wheel_delta_y(), (-2.0 : Float))
  assert_true(input.mouse_down(Left))
  assert_true(input.mouse_pressed(Left))
  input.begin_frame()
  assert_eq(input.pointer_delta_x(), (0.0 : Float))
  assert_eq(input.pointer_delta_y(), (0.0 : Float))
  assert_eq(input.wheel_delta_x(), (0.0 : Float))
  assert_eq(input.wheel_delta_y(), (0.0 : Float))
  assert_true(input.mouse_down(Left))
  assert_true(!input.mouse_pressed(Left))
}

///|
test "focus lost clears held input" {
  let input = InputState::new()
  let key = KeyCode::new("Space")
  input.enqueue_event(KeyDown(key, Modifiers::none(), false))
  input.enqueue_event(MouseDown(Right, (1.0 : Float), (2.0 : Float)))
  input.begin_frame()
  assert_true(input.key_down(key))
  assert_true(input.mouse_down(Right))
  input.enqueue_event(FocusLost)
  input.begin_frame()
  assert_true(!input.key_down(key))
  assert_true(!input.mouse_down(Right))
}
