///|
test "global_transform_put_f16_le_mut_view writes through view offset" {
  let bytes = FixedArray::make(6, (0 : Byte))
  let view = bytes.mut_view(start=1, end=5)
  let expected = global_transform_f32_to_f16_bits(0.125)
  global_transform_put_f16_le_mut_view(view, 1, 0.125)
  assert_true(bytes[2].to_uint() == (expected & 0xFFU))
  assert_true(bytes[3].to_uint() == ((expected >> 8) & 0xFFU))
}
