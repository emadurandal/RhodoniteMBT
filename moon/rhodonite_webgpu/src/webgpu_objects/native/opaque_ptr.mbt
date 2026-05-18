///|
/// Native opaque pointer handle shared with host window/surface integrations.
#external
pub type OpaquePtr

///|
pub fn opaque_ptr_to_c(ptr : OpaquePtr) -> @c.OpaquePtr = "%identity"

///|
/// Returns whether an opaque native pointer is null.
pub fn opaque_ptr_is_null(ptr : OpaquePtr) -> Bool {
  @c.opaque_ptr_is_null(opaque_ptr_to_c(ptr))
}

///|
/// Returns a null opaque native pointer.
pub fn null_opaque_ptr() -> OpaquePtr {
  opaque_ptr_from_c(@c.null_opaque_ptr())
}

///|
fn opaque_ptr_from_c(ptr : @c.OpaquePtr) -> OpaquePtr = "%identity"
