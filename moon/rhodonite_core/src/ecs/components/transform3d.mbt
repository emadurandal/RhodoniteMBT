///|
/// Library-local transform: TRS packed with std140 vec3/vec4 rules for archetype SoA (`CpuOnly`).

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
    get_gpu_f32(buf, base + 0),
    get_gpu_f32(buf, base + 4),
    get_gpu_f32(buf, base + 8),
  )
}

///|
fn get_vec4(buf : FixedArray[Byte], base : Int) -> @v4.Vector4F {
  @v4.Vector4F::new(
    get_gpu_f32(buf, base + 0),
    get_gpu_f32(buf, base + 4),
    get_gpu_f32(buf, base + 8),
    get_gpu_f32(buf, base + 12),
  )
}

///|
fn get_vec3_byte_view(buf : ArrayView[Byte], base : Int) -> @v3.Vector3F {
  @v3.Vector3F::new(
    get_gpu_f32_byte_view(buf, base + 0),
    get_gpu_f32_byte_view(buf, base + 4),
    get_gpu_f32_byte_view(buf, base + 8),
  )
}

///|
fn get_vec4_byte_view(buf : ArrayView[Byte], base : Int) -> @v4.Vector4F {
  @v4.Vector4F::new(
    get_gpu_f32_byte_view(buf, base + 0),
    get_gpu_f32_byte_view(buf, base + 4),
    get_gpu_f32_byte_view(buf, base + 8),
    get_gpu_f32_byte_view(buf, base + 12),
  )
}

///|
/// Encodes one archetype row using [`transform3d_gpu_layout`] stride and field offsets.
pub fn Transform3D::to_component_bytes(self : Transform3D) -> FixedArray[Byte] {
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
pub fn Transform3D::from_component_bytes(
  bytes : FixedArray[Byte],
) -> Transform3D {
  let layout = transform3d_gpu_layout()
  if bytes.length() != layout.stride {
    abort("Transform3D::from_component_bytes: length mismatch")
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

///|
/// Decodes TRS from a zero-copy [`ArrayView`] over one archetype row (see MoonBit array views).
pub fn Transform3D::from_component_byte_view(
  bytes : ArrayView[Byte],
) -> Transform3D {
  let layout = transform3d_gpu_layout()
  if bytes.length() != layout.stride {
    abort("Transform3D::from_component_byte_view: length mismatch")
  }
  let fields = layout.fields
  if fields.length() != 3 {
    abort("transform3d_gpu_layout: expected 3 fields")
  }
  {
    position: get_vec3_byte_view(bytes, fields[0].offset),
    rotation: get_vec4_byte_view(bytes, fields[1].offset),
    scale: get_vec3_byte_view(bytes, fields[2].offset),
  }
}

///|
fn trs_translation_matrix(t : @v3.Vector3F) -> @m44.Matrix4F {
  @m44.Matrix4::new_col_major(
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
    t.x(),
    t.y(),
    t.z(),
    (1.0 : Float),
  )
}

///|
fn trs_scale_matrix(s : @v3.Vector3F) -> @m44.Matrix4F {
  @m44.Matrix4::new_col_major(
    s.x(),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    s.y(),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    s.z(),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
  )
}

///|
/// Column-major rotation from unit quaternion `(x, y, z, w)` (same axis order as [`rotation`]).
fn quaternion_to_rotation_matrix(q : @v4.Vector4F) -> @m44.Matrix4F {
  let x = q.x()
  let y = q.y()
  let z = q.z()
  let w = q.w()
  let xx = x * x
  let yy = y * y
  let zz = z * z
  let xy = x * y
  let xz = x * z
  let yz = y * z
  let wx = w * x
  let wy = w * y
  let wz = w * z
  let r00 = (1.0 : Float) - (2.0 : Float) * (yy + zz)
  let r01 = (2.0 : Float) * (xy - wz)
  let r02 = (2.0 : Float) * (xz + wy)
  let r10 = (2.0 : Float) * (xy + wz)
  let r11 = (1.0 : Float) - (2.0 : Float) * (xx + zz)
  let r12 = (2.0 : Float) * (yz - wx)
  let r20 = (2.0 : Float) * (xz - wy)
  let r21 = (2.0 : Float) * (yz + wx)
  let r22 = (1.0 : Float) - (2.0 : Float) * (xx + yy)
  @m44.Matrix4::new_col_major(
    r00,
    r10,
    r20,
    (0.0 : Float),
    r01,
    r11,
    r21,
    (0.0 : Float),
    r02,
    r12,
    r22,
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
  )
}

///|
/// Local model matrix: column vectors, `translation * rotation * scale`.
pub fn Transform3D::to_local_matrix(self : Transform3D) -> @m44.Matrix4F {
  let s = trs_scale_matrix(self.scale)
  let r = quaternion_to_rotation_matrix(self.rotation)
  let t = trs_translation_matrix(self.position)
  t.mat_mul(r.mat_mul(s))
}
