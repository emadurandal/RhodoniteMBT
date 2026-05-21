/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "renderer instance bytes store transform refs and colors" {
  let world = @ecs.World::new()
  let entities = world.spawn_transform_global_batch(2, fn(
    _i,
    _entity,
    _tf_row,
    _gt_row,
  ) {
    ()
  })
  let bytes = build_renderer_instance_bytes(world, entities, [
    RendererInstanceColor::{ r: 0.25, g: 0.5, b: 0.75 },
    RendererInstanceColor::{ r: 0.125, g: 0.375, b: 0.625 },
  ])
  let refs = world.extract_global_transform_refs(entities)
  assert_true(bytes.length() == 48)
  for i = 0; i < 8; i = i + 1 {
    assert_true(bytes[i] == refs[i])
    assert_true(bytes[24 + i] == refs[8 + i])
  }
  assert_true(@writes.get_f32_le(bytes, 8) == 0.25)
  assert_true(@writes.get_f32_le(bytes, 12) == 0.5)
  assert_true(@writes.get_f32_le(bytes, 16) == 0.75)
  assert_true(@writes.get_f32_le(bytes, 32) == 0.125)
  assert_true(@writes.get_f32_le(bytes, 36) == 0.375)
  assert_true(@writes.get_f32_le(bytes, 40) == 0.625)
}
