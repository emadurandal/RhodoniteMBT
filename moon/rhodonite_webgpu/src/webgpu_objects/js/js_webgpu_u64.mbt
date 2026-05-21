/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `js_u64_to_double`.
fn js_u64_to_double(n : UInt64) -> Double {
  n.to_uint().to_double()
}
