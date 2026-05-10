///|
/// Scalar and vector kinds sized for std140-like layouts (`Vec3` uses 16-byte slots including padding).
pub(all) enum GpuFieldKind {
  F32
  U32
  Vec2F32
  ///
  /// `vec3` as three consecutive `f32` (12 bytes), no std140 tail padding.
  Vec3F32Packed
  ///
  /// std140-style `vec3`: 16-byte column (12 bytes payload + 4 padding).
  Vec3F32
  Vec4F32
  Mat4x4F32
} derive(Eq)

///|
/// One member inside the struct described by `GpuLayout` (offset/size are resolved by `GpuLayout::std140`).
pub(all) struct GpuField {
  name : String
  kind : GpuFieldKind
  offset : Int
  size : Int
  align : Int
}

///|
/// CPU-side mirror of a WGSL-friendly layout (std140-style packing). Stride is padded to 16 bytes for storage-buffer alignment.
pub(all) struct GpuLayout {
  fields : Array[GpuField]
  stride : Int
  align : Int
}
