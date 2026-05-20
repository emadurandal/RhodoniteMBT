/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// JS stub for native-only opaque pointer handles.
#external
pub type OpaquePtr

///|
pub fn opaque_ptr_is_null(_ptr : OpaquePtr) -> Bool {
  true
}

///|
pub fn null_opaque_ptr() -> OpaquePtr {
  abort("null_opaque_ptr is only available in the native backend")
}
