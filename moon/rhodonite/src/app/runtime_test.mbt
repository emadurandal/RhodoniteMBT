/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "default phase groups split frame begin fixed step and render frame" {
  assert_true(default_frame_begin_phases() == [phase_surface(), phase_input()])
  assert_true(
    default_fixed_step_phases() ==
    [phase_fixed_update(), phase_fixed_post_update()],
  )
  assert_true(
    default_render_frame_phases() ==
    [
      phase_update(),
      phase_post_update(),
      phase_render_extract(),
      phase_render_prepare(),
      phase_render(),
      phase_present(),
    ],
  )
  assert_true(
    default_render_state_preparation_phases() ==
    [phase_update(), phase_post_update(), phase_render_extract()],
  )
}
