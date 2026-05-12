///|
/// Library-local transform: TRS as views over one tightly packed `f32` row in archetype SoA (`CpuOnly`).

///|
pub(all) struct Transform3D {
  position : @v3.Vector3Ref[Byte]
  rotation : @v4.Vector4Ref[Byte]
  scale : @v3.Vector3Ref[Byte]
}

///|
/// Tight packing: `vec3 position` (12B) + `vec4 rotation` (16B) + `vec3 scale` (12B) = 40B;
/// stride **48** (8B tail pad) so [`GpuLayout::is_valid`] holds (multiple of 16).
pub fn transform3d_gpu_layout() -> GpuLayout {
  {
    fields: [
      { name: "position", kind: Vec3F32Packed, offset: 0, size: 12, align: 4 },
      { name: "rotation", kind: Vec4F32, offset: 12, size: 16, align: 4 },
      { name: "scale", kind: Vec3F32Packed, offset: 28, size: 12, align: 4 },
    ],
    stride: 48,
    align: 16,
  }
}

///|
fn transform3d_from_row_mut(row : MutArrayView[Byte]) -> Transform3D {
  let layout = transform3d_gpu_layout()
  if row.length() != layout.stride {
    abort("Transform3D: row length mismatch")
  }
  let f = layout.fields
  if f.length() != 3 {
    abort("transform3d_gpu_layout: expected 3 fields")
  }
  let pos = row.mut_view(start=f[0].offset, end=f[0].offset + f[0].size)
  let rot = row.mut_view(start=f[1].offset, end=f[1].offset + f[1].size)
  let scl = row.mut_view(start=f[2].offset, end=f[2].offset + f[2].size)
  {
    position: @v3.Vector3Ref::from_mut_view(pos),
    rotation: @v4.Vector4Ref::from_mut_view(rot),
    scale: @v3.Vector3Ref::from_mut_view(scl),
  }
}

///|
/// Encodes one archetype row using [`transform3d_gpu_layout`] stride and field offsets.
pub fn Transform3D::to_component_bytes(self : Transform3D) -> FixedArray[Byte] {
  let layout = transform3d_gpu_layout()
  let buf = gpu_component_bytes(layout.stride)
  let f = layout.fields
  if f.length() != 3 {
    abort("transform3d_gpu_layout: expected 3 fields")
  }
  put_gpu_f32(buf, f[0].offset + 0, self.position.x().to_double())
  put_gpu_f32(buf, f[0].offset + 4, self.position.y().to_double())
  put_gpu_f32(buf, f[0].offset + 8, self.position.z().to_double())
  put_gpu_f32(buf, f[1].offset + 0, self.rotation.x().to_double())
  put_gpu_f32(buf, f[1].offset + 4, self.rotation.y().to_double())
  put_gpu_f32(buf, f[1].offset + 8, self.rotation.z().to_double())
  put_gpu_f32(buf, f[1].offset + 12, self.rotation.w().to_double())
  put_gpu_f32(buf, f[2].offset + 0, self.scale.x().to_double())
  put_gpu_f32(buf, f[2].offset + 4, self.scale.y().to_double())
  put_gpu_f32(buf, f[2].offset + 8, self.scale.z().to_double())
  buf
}

///|
/// Encodes TRS scalars into GPU component bytes using [`transform3d_gpu_layout`].
pub fn transform3d_trs_bytes(
  px : Float,
  py : Float,
  pz : Float,
  qx : Double,
  qy : Double,
  qz : Double,
  qw : Double,
  sx : Float,
  sy : Float,
  sz : Float,
) -> FixedArray[Byte] {
  let layout = transform3d_gpu_layout()
  let buf = gpu_component_bytes(layout.stride)
  let f = layout.fields
  if f.length() != 3 {
    abort("transform3d layout")
  }
  put_gpu_f32(buf, f[0].offset + 0, px.to_double())
  put_gpu_f32(buf, f[0].offset + 4, py.to_double())
  put_gpu_f32(buf, f[0].offset + 8, pz.to_double())
  put_gpu_f32(buf, f[1].offset + 0, qx)
  put_gpu_f32(buf, f[1].offset + 4, qy)
  put_gpu_f32(buf, f[1].offset + 8, qz)
  put_gpu_f32(buf, f[1].offset + 12, qw)
  put_gpu_f32(buf, f[2].offset + 0, sx.to_double())
  put_gpu_f32(buf, f[2].offset + 4, sy.to_double())
  put_gpu_f32(buf, f[2].offset + 8, sz.to_double())
  buf
}

///|
/// Decodes TRS from a zero-copy [`MutArrayView`] over one archetype row.
pub fn Transform3D::from_component_mut_view(
  row : MutArrayView[Byte],
) -> Transform3D {
  transform3d_from_row_mut(row)
}

///|
/// Decodes a read-only component row and returns its local model matrix.
pub fn Transform3D::local_matrix_from_component_view(
  row : ArrayView[Byte],
) -> @m44.Matrix44F {
  let layout = transform3d_gpu_layout()
  if row.length() != layout.stride {
    abort("Transform3D::local_matrix_from_component_view: row length mismatch")
  }
  let f = layout.fields
  if f.length() != 3 {
    abort("transform3d_gpu_layout: expected 3 fields")
  }
  let px = get_gpu_f32_byte_view(row, f[0].offset + 0)
  let py = get_gpu_f32_byte_view(row, f[0].offset + 4)
  let pz = get_gpu_f32_byte_view(row, f[0].offset + 8)
  let qx = get_gpu_f32_byte_view(row, f[1].offset + 0)
  let qy = get_gpu_f32_byte_view(row, f[1].offset + 4)
  let qz = get_gpu_f32_byte_view(row, f[1].offset + 8)
  let qw = get_gpu_f32_byte_view(row, f[1].offset + 12)
  let sx = get_gpu_f32_byte_view(row, f[2].offset + 0)
  let sy = get_gpu_f32_byte_view(row, f[2].offset + 4)
  let sz = get_gpu_f32_byte_view(row, f[2].offset + 8)
  transform3d_local_matrix_from_trs(px, py, pz, qx, qy, qz, qw, sx, sy, sz)
}

///|
fn transform3d_local_matrix_from_trs(
  px : Float,
  py : Float,
  pz : Float,
  qx : Float,
  qy : Float,
  qz : Float,
  qw : Float,
  sx : Float,
  sy : Float,
  sz : Float,
) -> @m44.Matrix44F {
  let xx = qx * qx
  let yy = qy * qy
  let zz = qz * qz
  let xy = qx * qy
  let xz = qx * qz
  let yz = qy * qz
  let wx = qw * qx
  let wy = qw * qy
  let wz = qw * qz
  let r00 = (1.0 : Float) - (2.0 : Float) * (yy + zz)
  let r01 = (2.0 : Float) * (xy - wz)
  let r02 = (2.0 : Float) * (xz + wy)
  let r10 = (2.0 : Float) * (xy + wz)
  let r11 = (1.0 : Float) - (2.0 : Float) * (xx + zz)
  let r12 = (2.0 : Float) * (yz - wx)
  let r20 = (2.0 : Float) * (xz - wy)
  let r21 = (2.0 : Float) * (yz + wx)
  let r22 = (1.0 : Float) - (2.0 : Float) * (xx + yy)
  @m44.Matrix44::new_col_major(
    r00 * sx,
    r10 * sx,
    r20 * sx,
    (0.0 : Float),
    r01 * sy,
    r11 * sy,
    r21 * sy,
    (0.0 : Float),
    r02 * sz,
    r12 * sz,
    r22 * sz,
    (0.0 : Float),
    px,
    py,
    pz,
    (1.0 : Float),
  )
}

///|
/// Local model matrix: column vectors, `translation * rotation * scale`.
pub fn Transform3D::to_local_matrix(self : Transform3D) -> @m44.Matrix44F {
  transform3d_local_matrix_from_trs(
    self.position.x(),
    self.position.y(),
    self.position.z(),
    self.rotation.x(),
    self.rotation.y(),
    self.rotation.z(),
    self.rotation.w(),
    self.scale.x(),
    self.scale.y(),
    self.scale.z(),
  )
}
