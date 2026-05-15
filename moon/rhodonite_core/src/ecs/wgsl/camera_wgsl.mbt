///|
/// Implements `camera_words_binding`.
pub fn camera_words_binding(
  group : UInt,
  binding : UInt,
  var_name : String,
) -> String {
  "@group(" +
  group.to_string() +
  ") @binding(" +
  binding.to_string() +
  ") var<storage, read> " +
  var_name +
  ": array<u32>;\n"
}

///|
/// Implements `camera_words_binding_default`.
pub fn camera_words_binding_default() -> String {
  camera_words_binding(1U, 0U, "camera_words")
}

///|
/// Implements `camera_helpers`.
pub fn camera_helpers(camera_words_var~ : String) -> String {
  let header =
    #|struct RnCamera {
    #|  view_proj: mat4x4<f32>,
    #|  view: mat4x4<f32>,
    #|  proj: mat4x4<f32>,
    #|  inv_view_proj: mat4x4<f32>,
    #|  world_pos_near: vec4<f32>,
    #|  params: vec4<f32>,
    #|}
    #|
    #|fn rn_load_camera_mat4(word_offset: u32) -> mat4x4<f32> {
    #|  return mat4x4<f32>(
    #|    vec4<f32>(
  let w = camera_words_var
  let body0 = "      bitcast<f32>(" +
    w +
    "[word_offset + 0u]),\n" +
    "      bitcast<f32>(" +
    w +
    "[word_offset + 1u]),\n" +
    "      bitcast<f32>(" +
    w +
    "[word_offset + 2u]),\n" +
    "      bitcast<f32>(" +
    w +
    "[word_offset + 3u]),\n" +
    "    ),\n" +
    "    vec4<f32>(\n" +
    "      bitcast<f32>(" +
    w +
    "[word_offset + 4u]),\n" +
    "      bitcast<f32>(" +
    w +
    "[word_offset + 5u]),\n" +
    "      bitcast<f32>(" +
    w +
    "[word_offset + 6u]),\n" +
    "      bitcast<f32>(" +
    w +
    "[word_offset + 7u]),\n" +
    "    ),\n" +
    "    vec4<f32>(\n" +
    "      bitcast<f32>(" +
    w +
    "[word_offset + 8u]),\n" +
    "      bitcast<f32>(" +
    w +
    "[word_offset + 9u]),\n" +
    "      bitcast<f32>(" +
    w +
    "[word_offset + 10u]),\n" +
    "      bitcast<f32>(" +
    w +
    "[word_offset + 11u]),\n" +
    "    ),\n" +
    "    vec4<f32>(\n" +
    "      bitcast<f32>(" +
    w +
    "[word_offset + 12u]),\n" +
    "      bitcast<f32>(" +
    w +
    "[word_offset + 13u]),\n" +
    "      bitcast<f32>(" +
    w +
    "[word_offset + 14u]),\n" +
    "      bitcast<f32>(" +
    w +
    "[word_offset + 15u]),\n" +
    "    ),\n" +
    "  );\n" +
    "}\n\n" +
    "fn rn_load_camera(word_offset: u32) -> RnCamera {\n" +
    "  var camera: RnCamera;\n" +
    "  camera.view_proj = rn_load_camera_mat4(word_offset + 0u);\n" +
    "  camera.view = rn_load_camera_mat4(word_offset + 16u);\n" +
    "  camera.proj = rn_load_camera_mat4(word_offset + 32u);\n" +
    "  camera.inv_view_proj = rn_load_camera_mat4(word_offset + 48u);\n" +
    "  camera.world_pos_near = vec4<f32>(\n" +
    "    bitcast<f32>(" +
    w +
    "[word_offset + 64u]),\n" +
    "    bitcast<f32>(" +
    w +
    "[word_offset + 65u]),\n" +
    "    bitcast<f32>(" +
    w +
    "[word_offset + 66u]),\n" +
    "    bitcast<f32>(" +
    w +
    "[word_offset + 67u]),\n" +
    "  );\n" +
    "  camera.params = vec4<f32>(\n" +
    "    bitcast<f32>(" +
    w +
    "[word_offset + 68u]),\n" +
    "    bitcast<f32>(" +
    w +
    "[word_offset + 69u]),\n" +
    "    bitcast<f32>(" +
    w +
    "[word_offset + 70u]),\n" +
    "    bitcast<f32>(" +
    w +
    "[word_offset + 71u]),\n" +
    "  );\n" +
    "  return camera;\n" +
    "}\n"
  header + body0
}

///|
/// Implements `camera_helpers_default`.
pub fn camera_helpers_default() -> String {
  camera_helpers(camera_words_var="camera_words")
}
