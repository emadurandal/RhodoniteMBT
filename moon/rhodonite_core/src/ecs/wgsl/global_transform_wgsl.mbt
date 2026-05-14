///|
/// Returns WGSL helper definitions for loading the builtin packed `GlobalTransform`
/// blob from a storage-buffer `array<u32>`.
///
/// The caller owns the storage binding declaration. For the default examples this
/// means declaring `var<storage, read> transform_words: array<u32>;` and calling
/// `global_transform_helpers_default()`.
pub fn global_transform_helpers(transform_words_var~ : String) -> String {
  let f16_code = @comp.global_transform_format_code(@comp.Affine3x4F16)
  let prelude =
    #|struct RnGlobalTransformRows {
    #|  row0: vec4<f32>,
    #|  row1: vec4<f32>,
    #|  row2: vec4<f32>,
    #|}
    #|
    #|fn rn_load_global_transform(transform_ref: vec2<u32>) -> RnGlobalTransformRows {
    #|  let format = transform_ref.x;
    #|  let word_offset = transform_ref.y;
    #|  var rows: RnGlobalTransformRows;
    #|  if (format ==
  let f16_header = " " + f16_code.to_string() + "u) {\n"
  let f16_tail =
    #|    rows.row0 = vec4<f32>(r0xy.x, r0xy.y, r0zw.x, r0zw.y);
    #|    rows.row1 = vec4<f32>(r1xy.x, r1xy.y, r1zw.x, r1zw.y);
    #|    rows.row2 = vec4<f32>(r2xy.x, r2xy.y, r2zw.x, r2zw.y);
    #|  } else {
  let f16_rows = "    let r0xy = unpack2x16float(" +
    transform_words_var +
    "[word_offset + 0u]);\n" +
    "    let r0zw = unpack2x16float(" +
    transform_words_var +
    "[word_offset + 1u]);\n" +
    "    let r1xy = unpack2x16float(" +
    transform_words_var +
    "[word_offset + 2u]);\n" +
    "    let r1zw = unpack2x16float(" +
    transform_words_var +
    "[word_offset + 3u]);\n" +
    "    let r2xy = unpack2x16float(" +
    transform_words_var +
    "[word_offset + 4u]);\n" +
    "    let r2zw = unpack2x16float(" +
    transform_words_var +
    "[word_offset + 5u]);\n" +
    f16_tail
  let f32_rows = "    rows.row0 = vec4<f32>(\n" +
    "      bitcast<f32>(" +
    transform_words_var +
    "[word_offset + 0u]),\n" +
    "      bitcast<f32>(" +
    transform_words_var +
    "[word_offset + 1u]),\n" +
    "      bitcast<f32>(" +
    transform_words_var +
    "[word_offset + 2u]),\n" +
    "      bitcast<f32>(" +
    transform_words_var +
    "[word_offset + 3u]),\n" +
    "    );\n" +
    "    rows.row1 = vec4<f32>(\n" +
    "      bitcast<f32>(" +
    transform_words_var +
    "[word_offset + 4u]),\n" +
    "      bitcast<f32>(" +
    transform_words_var +
    "[word_offset + 5u]),\n" +
    "      bitcast<f32>(" +
    transform_words_var +
    "[word_offset + 6u]),\n" +
    "      bitcast<f32>(" +
    transform_words_var +
    "[word_offset + 7u]),\n" +
    "    );\n" +
    "    rows.row2 = vec4<f32>(\n" +
    "      bitcast<f32>(" +
    transform_words_var +
    "[word_offset + 8u]),\n" +
    "      bitcast<f32>(" +
    transform_words_var +
    "[word_offset + 9u]),\n" +
    "      bitcast<f32>(" +
    transform_words_var +
    "[word_offset + 10u]),\n" +
    "      bitcast<f32>(" +
    transform_words_var +
    "[word_offset + 11u]),\n" +
    "    );\n"
  let epilogue =
    #|  }
    #|  return rows;
    #|}
    #|
    #|fn rn_transform_point(rows: RnGlobalTransformRows, local_pos: vec3<f32>) -> vec4<f32> {
    #|  let local_h = vec4<f32>(local_pos, 1.0);
    #|  return vec4<f32>(
    #|    dot(rows.row0, local_h),
    #|    dot(rows.row1, local_h),
    #|    dot(rows.row2, local_h),
    #|    1.0,
    #|  );
    #|}
    #|
  prelude + f16_header + f16_rows + f32_rows + epilogue
}

///|
/// Returns WGSL helpers that read from a storage-buffer variable named `transform_words`.
pub fn global_transform_helpers_default() -> String {
  global_transform_helpers(transform_words_var="transform_words")
}
