///|
fn assert_double_near(actual : Double, expected : Double) -> Unit raise {
  let diff = if actual > expected {
    actual - expected
  } else {
    expected - actual
  }
  assert_true(diff < 0.000001)
}

///|
test "render clock uses caller supplied delta" {
  let time = @app.TimeState::new((0.25 : Float))
  let frame1 = time.next_render_frame((0.1 : Float))
  assert_eq(frame1.delta_seconds(), (0.1 : Float))
  assert_eq(frame1.frame_index(), 1)
  assert_double_near(frame1.elapsed_seconds(), 0.1)
  let frame2 = time.next_render_frame((0.2 : Float))
  assert_eq(frame2.delta_seconds(), (0.2 : Float))
  assert_eq(frame2.frame_index(), 2)
  assert_double_near(frame2.elapsed_seconds(), 0.3)
}

///|
test "fixed clock accumulates real elapsed and steps by fixed delta" {
  let time = @app.TimeState::new((0.25 : Float))
  time.push_fixed_elapsed((0.1 : Float))
  assert_true(!time.can_step_fixed())
  time.push_fixed_elapsed((0.4 : Float))
  assert_true(time.can_step_fixed())
  let frame1 = time.next_fixed_frame()
  assert_eq(frame1.delta_seconds(), (0.25 : Float))
  assert_eq(frame1.frame_index(), 1)
  assert_double_near(frame1.elapsed_seconds(), 0.25)
  assert_true(time.can_step_fixed())
  let frame2 = time.next_fixed_frame()
  assert_eq(frame2.delta_seconds(), (0.25 : Float))
  assert_eq(frame2.frame_index(), 2)
  assert_double_near(frame2.elapsed_seconds(), 0.5)
  assert_true(!time.can_step_fixed())
}
