/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "unlit material description exposes constructor accessors" {
  let desc = UnlitMaterialDesc::new(0.2, 0.4, 0.6, alpha=0.8, flags=3U)
  assert_true(desc.base_color_r() == 0.2)
  assert_true(desc.base_color_g() == 0.4)
  assert_true(desc.base_color_b() == 0.6)
  assert_true(desc.alpha() == 0.8)
  assert_true(desc.flags() == 3U)
}

///|
test "cube mesh descriptor exposes position-only shared-corner geometry" {
  let desc = cube_mesh_desc(desc=CubeMeshDesc::new(half_extent=0.5))
  let vertices = desc.vertices()
  let indices = desc.indices_u16()
  assert_true(cube_vertex_count() == 8)
  assert_true(desc.index_count() == 36)
  assert_true(vertices.length() == 8 * primitive_position3_vertex_stride())
  assert_true(indices.length() == 36 * 2)
  assert_true(@writes.get_f32_le(vertices, 0) == -0.5)
  assert_true(@writes.get_f32_le(vertices, 4) == -0.5)
  assert_true(@writes.get_f32_le(vertices, 8) == -0.5)
  assert_true(@writes.get_f32_le(vertices, 84) == -0.5)
  assert_true(@writes.get_f32_le(vertices, 88) == 0.5)
  assert_true(@writes.get_f32_le(vertices, 92) == 0.5)
  assert_true(indices[0].to_uint() == 0U)
  assert_true(indices[2].to_uint() == 1U)
  assert_true(indices[70].to_uint() == 3U)
}

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
