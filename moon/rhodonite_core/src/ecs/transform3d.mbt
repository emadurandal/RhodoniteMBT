///|
/// Library-local transform: TRS in std140-friendly packing for flat GPU storage.

///|
pub(all) struct Transform3D {
  position : @v3.Vector3F
  rotation : @v4.Vector4F
  scale : @v3.Vector3F
}

///|
pub fn Transform3D::identity() -> Transform3D {
  {
    position: @v3.Vector3F::zero(),
    rotation: @v4.Vector4F::new(
      (0.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (1.0 : Float),
    ),
    scale: @v3.Vector3F::new((1.0 : Float), (1.0 : Float), (1.0 : Float)),
  }
}

///|
/// WGSL/std140 layout: `vec3 position`, `vec4 rotation`, `vec3 scale` (each vec3 padded to 16 bytes).
pub fn transform3d_gpu_layout() -> GpuLayout {
  let fields : Array[(String, GpuFieldKind)] = [
    ("position", Vec3F32),
    ("rotation", Vec4F32),
    ("scale", Vec3F32),
  ]
  GpuLayout::std140(fields)
}

///|
fn put_vec3(buf : FixedArray[Byte], base : Int, v : @v3.Vector3F) -> Unit {
  put_gpu_f32(buf, base + 0, v.x().to_double())
  put_gpu_f32(buf, base + 4, v.y().to_double())
  put_gpu_f32(buf, base + 8, v.z().to_double())
}

///|
fn put_vec4(buf : FixedArray[Byte], base : Int, v : @v4.Vector4F) -> Unit {
  put_gpu_f32(buf, base + 0, v.x().to_double())
  put_gpu_f32(buf, base + 4, v.y().to_double())
  put_gpu_f32(buf, base + 8, v.z().to_double())
  put_gpu_f32(buf, base + 12, v.w().to_double())
}

///|
fn get_vec3(buf : FixedArray[Byte], base : Int) -> @v3.Vector3F {
  @v3.Vector3F::new(
    Float::from_double(get_gpu_f32(buf, base + 0)),
    Float::from_double(get_gpu_f32(buf, base + 4)),
    Float::from_double(get_gpu_f32(buf, base + 8)),
  )
}

///|
fn get_vec4(buf : FixedArray[Byte], base : Int) -> @v4.Vector4F {
  @v4.Vector4F::new(
    Float::from_double(get_gpu_f32(buf, base + 0)),
    Float::from_double(get_gpu_f32(buf, base + 4)),
    Float::from_double(get_gpu_f32(buf, base + 8)),
    Float::from_double(get_gpu_f32(buf, base + 12)),
  )
}

///|
/// Encodes one row using [`transform3d_gpu_layout`] stride and field offsets.
pub fn Transform3D::to_gpu_bytes(self : Transform3D) -> FixedArray[Byte] {
  let layout = transform3d_gpu_layout()
  let buf = gpu_component_bytes(layout.stride)
  let fields = layout.fields
  if fields.length() != 3 {
    abort("transform3d_gpu_layout: expected 3 fields")
  }
  put_vec3(buf, fields[0].offset, self.position)
  put_vec4(buf, fields[1].offset, self.rotation)
  put_vec3(buf, fields[2].offset, self.scale)
  buf
}

///|
pub fn Transform3D::from_gpu_bytes(bytes : FixedArray[Byte]) -> Transform3D {
  let layout = transform3d_gpu_layout()
  if bytes.length() != layout.stride {
    abort("Transform3D::from_gpu_bytes: length mismatch")
  }
  let fields = layout.fields
  if fields.length() != 3 {
    abort("transform3d_gpu_layout: expected 3 fields")
  }
  {
    position: get_vec3(bytes, fields[0].offset),
    rotation: get_vec4(bytes, fields[1].offset),
    scale: get_vec3(bytes, fields[2].offset),
  }
}
