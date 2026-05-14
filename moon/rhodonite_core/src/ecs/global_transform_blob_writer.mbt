///|
pub(all) struct GlobalTransformDenseLayout {
  format : @comp.GlobalTransformGpuFormat
  words_per_entity : Int
}

///|
pub(all) struct GlobalTransformUploadRange {
  first_word : Int
  word_count : Int
}

///|
pub(all) struct GlobalTransformRun {
  first_index : Int
  end_index : Int
  format : @comp.GlobalTransformGpuFormat
  first_word : Int
  words_per_entity : Int
}

///|
pub struct GlobalTransformBlobWriter {
  priv bytes : MutArrayView[Byte]
  priv refs : FixedArray[Byte]
  priv count : Int
  priv first_word : Int
  priv dense_layout : GlobalTransformDenseLayout?
}

///|
fn global_transform_f32_to_f16_bits(value : Float) -> UInt {
  let bits = value.reinterpret_as_uint()
  let sign = (bits >> 16) & 0x8000U
  let exp = ((bits >> 23) & 0xFFU).reinterpret_as_int()
  let mant = bits & 0x7FFFFFU
  if exp == 255 {
    if mant == 0U {
      return sign | 0x7C00U
    }
    return sign | 0x7E00U
  }
  let half_exp = exp - 127 + 15
  if half_exp >= 31 {
    return sign | 0x7C00U
  }
  if half_exp <= 0 {
    if half_exp < -10 {
      return sign
    }
    let mantissa = mant | 0x800000U
    let shift = 14 - half_exp
    let mut half_mant = mantissa >> shift
    if ((mantissa >> (shift - 1)) & 1U) != 0U {
      half_mant = half_mant + 1U
    }
    return sign | half_mant
  }
  let mut half = sign | (half_exp.reinterpret_as_uint() << 10) | (mant >> 13)
  if ((mant >> 12) & 1U) != 0U {
    half = half + 1U
  }
  half
}

///|
fn put_global_transform_f32_word(
  bytes : MutArrayView[Byte],
  word_offset : Int,
  value : Float,
) -> Unit {
  @writes.put_u32_le_mut_view(
    bytes,
    word_offset * 4,
    value.reinterpret_as_uint(),
  )
}

///|
fn put_global_transform_packed_f16x2(
  bytes : MutArrayView[Byte],
  word_offset : Int,
  x : Float,
  y : Float,
) -> Unit {
  let packed = global_transform_f32_to_f16_bits(x) |
    (global_transform_f32_to_f16_bits(y) << 16)
  @writes.put_u32_le_mut_view(bytes, word_offset * 4, packed)
}

///|
fn GlobalTransformBlobWriter::format_and_relative_word_offset(
  self : GlobalTransformBlobWriter,
  index : Int,
) -> (@comp.GlobalTransformGpuFormat, Int) {
  if index < 0 || index >= self.count {
    abort("GlobalTransformBlobWriter: index out of range")
  }
  match self.dense_layout {
    Some(layout) =>
      (layout.format, index * layout.words_per_entity - self.first_word)
    None => {
      let base = index * 8
      if base + 8 > self.refs.length() {
        abort("GlobalTransformBlobWriter: refs length mismatch")
      }
      (
        @comp.global_transform_format_from_code(
          @writes.get_u32_le(self.refs, base),
        ),
        @writes.get_u32_le(self.refs, base + 4).reinterpret_as_int() -
        self.first_word,
      )
    }
  }
}

///|
pub fn global_transform_words_for_format(
  format : @comp.GlobalTransformGpuFormat,
) -> Int {
  @comp.global_transform_word_count(format)
}

///|
pub fn detect_dense_global_transform_layout(
  refs : FixedArray[Byte],
  count : Int,
) -> GlobalTransformDenseLayout? {
  if count < 0 || refs.length() < count * 8 {
    return None
  }
  if count == 0 {
    return None
  }
  let format_code = @writes.get_u32_le(refs, 0)
  if format_code != 0U && format_code != 1U {
    return None
  }
  let format = @comp.global_transform_format_from_code(format_code)
  let words_per_entity = @comp.global_transform_word_count(format)
  for i = 0; i < count; i = i + 1 {
    let base = i * 8
    if @writes.get_u32_le(refs, base) != format_code {
      return None
    }
    if @writes.get_u32_le(refs, base + 4).reinterpret_as_int() !=
      i * words_per_entity {
      return None
    }
  }
  Some({ format, words_per_entity })
}

///|
pub fn compute_global_transform_upload_range(
  refs : FixedArray[Byte],
  count : Int,
  dense_layout : GlobalTransformDenseLayout?,
) -> GlobalTransformUploadRange {
  if count <= 0 {
    return { first_word: 0, word_count: 0 }
  }
  match dense_layout {
    Some(layout) =>
      { first_word: 0, word_count: count * layout.words_per_entity }
    None => {
      if refs.length() < count * 8 {
        abort("compute_global_transform_upload_range: refs length mismatch")
      }
      let mut first_word = 0
      let mut end_word = 0
      for i = 0; i < count; i = i + 1 {
        let base = i * 8
        let format = @comp.global_transform_format_from_code(
          @writes.get_u32_le(refs, base),
        )
        let word_offset = @writes.get_u32_le(refs, base + 4).reinterpret_as_int()
        let word_end = word_offset + @comp.global_transform_word_count(format)
        if i == 0 || word_offset < first_word {
          first_word = word_offset
        }
        if word_end > end_word {
          end_word = word_end
        }
      }
      { first_word, word_count: end_word - first_word }
    }
  }
}

///|
pub fn detect_global_transform_runs(
  refs : FixedArray[Byte],
  count : Int,
) -> Array[GlobalTransformRun] {
  if count < 0 || refs.length() < count * 8 {
    abort("detect_global_transform_runs: refs length mismatch")
  }
  let runs : Array[GlobalTransformRun] = []
  let mut i = 0
  while i < count {
    let ref_base = i * 8
    let format = @comp.global_transform_format_from_code(
      @writes.get_u32_le(refs, ref_base),
    )
    let words_per_entity = @comp.global_transform_word_count(format)
    let first_index = i
    let first_word = @writes.get_u32_le(refs, ref_base + 4).reinterpret_as_int()
    i = i + 1
    while i < count {
      let next_ref_base = i * 8
      if @comp.global_transform_format_from_code(
          @writes.get_u32_le(refs, next_ref_base),
        ) !=
        format {
        break
      }
      if @writes.get_u32_le(refs, next_ref_base + 4).reinterpret_as_int() !=
        first_word + (i - first_index) * words_per_entity {
        break
      }
      i = i + 1
    }
    runs.push({
      first_index,
      end_index: i,
      format,
      first_word,
      words_per_entity,
    })
  }
  runs
}

///|
pub fn GlobalTransformBlobWriter::set_element_at(
  self : GlobalTransformBlobWriter,
  index : Int,
  row : Int,
  column : Int,
  value : Float,
) -> Unit {
  if row < 0 || row > 2 || column < 0 || column > 3 {
    abort("GlobalTransformBlobWriter::set_element_at: invalid row or column")
  }
  let (format, word_offset) = self.format_and_relative_word_offset(index)
  match format {
    Affine3x4F32 =>
      put_global_transform_f32_word(
        self.bytes,
        word_offset + row * 4 + column,
        value,
      )
    Affine3x4F16 => {
      let word = word_offset + row * 2 + column / 2
      let byte_offset = word * 4
      let old = @writes.get_u32_le_mut_view(self.bytes, byte_offset)
      let half = global_transform_f32_to_f16_bits(value)
      let next = if column % 2 == 0 {
        (old & 0xFFFF0000U) | half
      } else {
        (old & 0x0000FFFFU) | (half << 16)
      }
      @writes.put_u32_le_mut_view(self.bytes, byte_offset, next)
    }
  }
}

///|
pub fn GlobalTransformBlobWriter::set_affine3x4_at(
  self : GlobalTransformBlobWriter,
  index : Int,
  m00 : Float,
  m01 : Float,
  m02 : Float,
  m03 : Float,
  m10 : Float,
  m11 : Float,
  m12 : Float,
  m13 : Float,
  m20 : Float,
  m21 : Float,
  m22 : Float,
  m23 : Float,
) -> Unit {
  let (format, word_offset) = self.format_and_relative_word_offset(index)
  match format {
    Affine3x4F32 => {
      put_global_transform_f32_word(self.bytes, word_offset + 0, m00)
      put_global_transform_f32_word(self.bytes, word_offset + 1, m01)
      put_global_transform_f32_word(self.bytes, word_offset + 2, m02)
      put_global_transform_f32_word(self.bytes, word_offset + 3, m03)
      put_global_transform_f32_word(self.bytes, word_offset + 4, m10)
      put_global_transform_f32_word(self.bytes, word_offset + 5, m11)
      put_global_transform_f32_word(self.bytes, word_offset + 6, m12)
      put_global_transform_f32_word(self.bytes, word_offset + 7, m13)
      put_global_transform_f32_word(self.bytes, word_offset + 8, m20)
      put_global_transform_f32_word(self.bytes, word_offset + 9, m21)
      put_global_transform_f32_word(self.bytes, word_offset + 10, m22)
      put_global_transform_f32_word(self.bytes, word_offset + 11, m23)
    }
    Affine3x4F16 => {
      put_global_transform_packed_f16x2(self.bytes, word_offset + 0, m00, m01)
      put_global_transform_packed_f16x2(self.bytes, word_offset + 1, m02, m03)
      put_global_transform_packed_f16x2(self.bytes, word_offset + 2, m10, m11)
      put_global_transform_packed_f16x2(self.bytes, word_offset + 3, m12, m13)
      put_global_transform_packed_f16x2(self.bytes, word_offset + 4, m20, m21)
      put_global_transform_packed_f16x2(self.bytes, word_offset + 5, m22, m23)
    }
  }
}

///|
pub fn write_global_transform_blob_by_refs(
  bytes : MutArrayView[Byte],
  refs : FixedArray[Byte],
  count : Int,
  first_word : Int,
  dense_layout : GlobalTransformDenseLayout?,
  write : (GlobalTransformBlobWriter) -> Unit,
) -> Unit {
  write({ bytes, refs, count, first_word, dense_layout })
}

///|
pub fn World::write_global_transform_blob_range_by_refs(
  self : World,
  refs : FixedArray[Byte],
  count : Int,
  range : GlobalTransformUploadRange,
  dense_layout : GlobalTransformDenseLayout?,
  write : (GlobalTransformBlobWriter) -> Unit,
) -> Array[GpuWriteView] {
  self.write_global_transform_blob_range_views(
    range.first_word,
    range.word_count,
    fn(bytes) {
      write_global_transform_blob_by_refs(
        bytes,
        refs,
        count,
        range.first_word,
        dense_layout,
        write,
      )
    },
  )
}
