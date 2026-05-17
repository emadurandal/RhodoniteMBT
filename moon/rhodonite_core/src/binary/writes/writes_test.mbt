///|
test "put_u16_le_mut_view writes through view offset" {
  let bytes = FixedArray::make(6, (0 : Byte))
  let view = bytes.mut_view(start=1, end=5)
  put_u16_le_mut_view(view, 1, 0xABCDU)
  assert_true(bytes[2].to_uint() == 0xCDU)
  assert_true(bytes[3].to_uint() == 0xABU)
}

///|
test "put_u32_le_mut_view writes through view offset" {
  let bytes = FixedArray::make(8, (0 : Byte))
  let view = bytes.mut_view(start=2, end=8)
  put_u32_le_mut_view(view, 1, 0x78563412U)
  assert_true(bytes[3].to_uint() == 0x12U)
  assert_true(bytes[4].to_uint() == 0x34U)
  assert_true(bytes[5].to_uint() == 0x56U)
  assert_true(bytes[6].to_uint() == 0x78U)
}
