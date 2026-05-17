///|
/// Implements `bytes4`.
fn bytes4(a : Byte, b : Byte, c : Byte, d : Byte) -> FixedArray[Byte] {
  ([a, b, c, d] : FixedArray[Byte])
}

///|
/// Test phase used for ordinary update systems.
fn update_phase() -> PhaseKey {
  PhaseKey::new("test/update")
}

///|
/// Test phase used for systems that run after update systems.
fn post_update_phase() -> PhaseKey {
  PhaseKey::new("test/post_update")
}

///|
/// Implements `u16_le`.
fn u16_le(bytes : ArrayView[Byte], offset : Int) -> UInt {
  bytes[offset].to_uint() | (bytes[offset + 1].to_uint() << 8)
}

///|
/// Implements `transform3d_bytes_identity`.
fn transform3d_bytes_identity() -> FixedArray[Byte] {
  let layout = @comp.transform3d_gpu_layout()
  let buf = @comp.gpu_component_bytes(layout.stride)
  let f = layout.fields
  if f.length() != 3 {
    abort("transform3d layout")
  }
  @comp.put_gpu_f32(buf, f[0].offset + 0, 0.0)
  @comp.put_gpu_f32(buf, f[0].offset + 4, 0.0)
  @comp.put_gpu_f32(buf, f[0].offset + 8, 0.0)
  @comp.put_gpu_f32(buf, f[1].offset + 0, 0.0)
  @comp.put_gpu_f32(buf, f[1].offset + 4, 0.0)
  @comp.put_gpu_f32(buf, f[1].offset + 8, 0.0)
  @comp.put_gpu_f32(buf, f[1].offset + 12, 1.0)
  @comp.put_gpu_f32(buf, f[2].offset + 0, 1.0)
  @comp.put_gpu_f32(buf, f[2].offset + 4, 1.0)
  @comp.put_gpu_f32(buf, f[2].offset + 8, 1.0)
  buf
}

///|
/// Implements `transform3d_bytes_translation`.
fn transform3d_bytes_translation(
  x : Float,
  y : Float,
  z : Float,
) -> FixedArray[Byte] {
  let layout = @comp.transform3d_gpu_layout()
  let buf = @comp.gpu_component_bytes(layout.stride)
  let f = layout.fields
  if f.length() != 3 {
    abort("transform3d layout")
  }
  @comp.put_gpu_f32(buf, f[0].offset + 0, x.to_double())
  @comp.put_gpu_f32(buf, f[0].offset + 4, y.to_double())
  @comp.put_gpu_f32(buf, f[0].offset + 8, z.to_double())
  @comp.put_gpu_f32(buf, f[1].offset + 0, 0.0)
  @comp.put_gpu_f32(buf, f[1].offset + 4, 0.0)
  @comp.put_gpu_f32(buf, f[1].offset + 8, 0.0)
  @comp.put_gpu_f32(buf, f[1].offset + 12, 1.0)
  @comp.put_gpu_f32(buf, f[2].offset + 0, 1.0)
  @comp.put_gpu_f32(buf, f[2].offset + 4, 1.0)
  @comp.put_gpu_f32(buf, f[2].offset + 8, 1.0)
  buf
}
