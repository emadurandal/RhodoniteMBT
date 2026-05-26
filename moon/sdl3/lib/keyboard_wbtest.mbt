/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Builds an SDL key modifier value for tests.
fn test_keymod(bits : UInt) -> SDL_Keymod {
  SDL_Keymod(bits.to_uint16())
}

///|
test "SDL_Keymod reports grouped modifier flags" {
  assert_true(test_keymod(0x0001U).shift())
  assert_true(test_keymod(0x0002U).shift())
  assert_true(test_keymod(0x00C0U).ctrl())
  assert_true(test_keymod(0x0300U).alt())
  assert_true(test_keymod(0x0C00U).meta())
  assert_true(!test_keymod(0U).shift())
  assert_true(!test_keymod(0U).ctrl())
  assert_true(!test_keymod(0U).alt())
  assert_true(!test_keymod(0U).meta())
}
