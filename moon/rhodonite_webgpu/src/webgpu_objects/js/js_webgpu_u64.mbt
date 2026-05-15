///|
/// Implements `js_u64_to_double`.
pub fn js_u64_to_double(n : UInt64) -> Double {
  n.to_uint().to_double()
}
