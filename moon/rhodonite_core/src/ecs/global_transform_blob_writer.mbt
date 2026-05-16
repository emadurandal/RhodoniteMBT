///|
/// Defines `GlobalTransformDenseLayout`.
pub(all) struct GlobalTransformDenseLayout {
  format : @comp.GlobalTransformGpuFormat
  words_per_entity : Int
}

///|
/// Defines `GlobalTransformUploadRange`.
pub(all) struct GlobalTransformUploadRange {
  first_word : Int
  word_count : Int
}

///|
/// Defines `GlobalTransformRun`.
pub(all) struct GlobalTransformRun {
  first_index : Int
  end_index : Int
  format : @comp.GlobalTransformGpuFormat
  first_word : Int
  words_per_entity : Int
}

///|
/// Defines `GlobalTransformBlobWriter`.
pub struct GlobalTransformBlobWriter {
  priv bytes : MutArrayView[Byte]
  priv refs : FixedArray[Byte]
  priv count : Int
  priv first_word : Int
  priv dense_layout : GlobalTransformDenseLayout?
}

///|
/// Implements `put_global_transform_f32_word`.
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
/// Implements `put_global_transform_packed_f16x2`.
fn put_global_transform_packed_f16x2(
  bytes : MutArrayView[Byte],
  word_offset : Int,
  x : Float,
  y : Float,
) -> Unit {
  let packed = @comp.global_transform_f32_to_f16_bits(x) |
    (@comp.global_transform_f32_to_f16_bits(y) << 16)
  @writes.put_u32_le_mut_view(bytes, word_offset * 4, packed)
}

///|
/// Implements `GlobalTransformBlobWriter::format_and_relative_word_offset`.
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
/// Implements `detect_dense_global_transform_layout`.
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
/// Implements `compute_global_transform_upload_range`.
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
/// Implements `detect_global_transform_runs`.
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
/// Implements `GlobalTransformBlobWriter::set_element_at`.
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
      let half = @comp.global_transform_f32_to_f16_bits(value)
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
#cfg(target="js")
extern "js" fn global_transform_element_setter_js(
  bytes : MutArrayView[Byte],
  refs : FixedArray[Byte],
  count : Int,
  first_word : Int,
  dense_format_code : Int,
  words_per_entity : Int,
  scalar_index : Int,
) -> (Int, Float) -> Unit =
  #| (
  #|   bytes,
  #|   refs,
  #|   count,
  #|   firstWord,
  #|   denseFormatCode,
  #|   wordsPerEntity,
  #|   scalarIndex,
  #| ) => {
  #|   const src = bytes.buf;
  #|   const start = bytes.start;
  #|   const byteLength = bytes.end - bytes.start;
  #|   if (!ArrayBuffer.isView(src)) {
  #|     throw new Error("GlobalTransform element setter requires typed byte storage.");
  #|   }
  #|   const words = new Uint32Array(src.buffer, src.byteOffset + start, byteLength >> 2);
  #|   const floats = new Float32Array(src.buffer, src.byteOffset + start, byteLength >> 2);
  #|   const halfLane = scalarIndex & 1;
  #|   const makeF16Bits = () => {
  #|     let cache = globalThis.__rhodonite_f32_to_f16_scratch;
  #|     if (!cache) {
  #|       const scratchF32 = new Float32Array(1);
  #|       const scratchU32 = new Uint32Array(scratchF32.buffer);
  #|       cache = globalThis.__rhodonite_f32_to_f16_scratch = {
  #|         scratchF32,
  #|         scratchU32,
  #|       };
  #|     }
  #|     return (value) => {
  #|       cache.scratchF32[0] = Math.fround(value);
  #|       const bits = cache.scratchU32[0] >>> 0;
  #|       const sign = (bits >>> 16) & 0x8000;
  #|       const exp = (bits >>> 23) & 0xff;
  #|       const mant = bits & 0x007fffff;
  #|       if (exp === 255) {
  #|         return mant === 0 ? sign | 0x7c00 : sign | 0x7e00;
  #|       }
  #|       const halfExp = exp - 127 + 15;
  #|       if (halfExp >= 31) {
  #|         return sign | 0x7c00;
  #|       }
  #|       if (halfExp <= 0) {
  #|         if (halfExp < -10) {
  #|           return sign;
  #|         }
  #|         const mantissa = mant | 0x00800000;
  #|         const shift = 14 - halfExp;
  #|         let halfMant = mantissa >>> shift;
  #|         if (((mantissa >>> (shift - 1)) & 1) !== 0) {
  #|           halfMant += 1;
  #|         }
  #|         return sign | halfMant;
  #|       }
  #|       let half = sign | (halfExp << 10) | (mant >>> 13);
  #|       if (((mant >>> 12) & 1) !== 0) {
  #|         half += 1;
  #|       }
  #|       return half;
  #|     };
  #|   };
  #|   if (denseFormatCode === 0) {
  #|     const baseWord = scalarIndex - firstWord;
  #|     return (index, value) => {
  #|       if (index < 0 || index >= count) throw new RangeError("GlobalTransform index out of range");
  #|       floats[index * wordsPerEntity + baseWord] = value;
  #|     };
  #|   }
  #|   if (denseFormatCode === 1) {
  #|     const baseWord = (scalarIndex >> 1) - firstWord;
  #|     const f32ToF16Bits = makeF16Bits();
  #|     return (index, value) => {
  #|       if (index < 0 || index >= count) throw new RangeError("GlobalTransform index out of range");
  #|       const word = index * wordsPerEntity + baseWord;
  #|       const half = f32ToF16Bits(value);
  #|       words[word] = halfLane === 0
  #|         ? ((words[word] & 0xffff0000) | half)
  #|         : ((words[word] & 0x0000ffff) | (half << 16));
  #|     };
  #|   }
  #|   if (!ArrayBuffer.isView(refs)) {
  #|     throw new Error("GlobalTransform mixed refs require typed ref storage.");
  #|   }
  #|   const refWords = new Uint32Array(refs.buffer, refs.byteOffset, refs.byteLength >> 2);
  #|   const f32ToF16Bits = makeF16Bits();
  #|   return (index, value) => {
  #|     if (index < 0 || index >= count) throw new RangeError("GlobalTransform index out of range");
  #|     const refBase = index * 2;
  #|     const format = refWords[refBase] ?? 0;
  #|     const wordOffset = (refWords[refBase + 1] ?? 0) - firstWord;
  #|     if (format === 1) {
  #|       const word = wordOffset + (scalarIndex >> 1);
  #|       const half = f32ToF16Bits(value);
  #|       words[word] = halfLane === 0
  #|         ? ((words[word] & 0xffff0000) | half)
  #|         : ((words[word] & 0x0000ffff) | (half << 16));
  #|     } else {
  #|       floats[wordOffset + scalarIndex] = value;
  #|     }
  #|   };
  #| }

///|
#cfg(target="native")
#borrow(bytes)
extern "C" fn global_transform_element_setter_set_dense_f32_native(
  bytes : MutArrayView[Byte],
  index : Int,
  value : Float,
  first_word : Int,
  words_per_entity : Int,
  scalar_index : Int,
) -> Unit = "rhodonite_global_transform_element_setter_set_dense_f32"

///|
#cfg(target="native")
#borrow(bytes)
extern "C" fn global_transform_element_setter_set_dense_f16_native(
  bytes : MutArrayView[Byte],
  index : Int,
  value : Float,
  first_word : Int,
  words_per_entity : Int,
  scalar_index : Int,
) -> Unit = "rhodonite_global_transform_element_setter_set_dense_f16"

///|
#cfg(target="native")
#borrow(bytes, refs)
extern "C" fn global_transform_element_setter_set_mixed_native(
  bytes : MutArrayView[Byte],
  refs : FixedArray[Byte],
  index : Int,
  value : Float,
  first_word : Int,
  scalar_index : Int,
) -> Unit = "rhodonite_global_transform_element_setter_set_mixed"

///|

///|
/// Implements `GlobalTransformBlobWriter::element_setter`.
#cfg(target="js")
pub fn GlobalTransformBlobWriter::element_setter(
  self : GlobalTransformBlobWriter,
  row : Int,
  column : Int,
) -> (Int, Float) -> Unit {
  if row < 0 || row > 2 || column < 0 || column > 3 {
    abort("GlobalTransformBlobWriter::element_setter: invalid row or column")
  }
  let scalar_index = row * 4 + column
  match self.dense_layout {
    Some(layout) => {
      let dense_format_code = match layout.format {
        Affine3x4F32 => 0
        Affine3x4F16 => 1
      }
      global_transform_element_setter_js(
        self.bytes,
        self.refs,
        self.count,
        self.first_word,
        dense_format_code,
        layout.words_per_entity,
        scalar_index,
      )
    }
    None =>
      global_transform_element_setter_js(
        self.bytes,
        self.refs,
        self.count,
        self.first_word,
        -1,
        0,
        scalar_index,
      )
  }
}

///|

///|
/// Implements `GlobalTransformBlobWriter::element_setter`.
#cfg(target="native")
pub fn GlobalTransformBlobWriter::element_setter(
  self : GlobalTransformBlobWriter,
  row : Int,
  column : Int,
) -> (Int, Float) -> Unit {
  if row < 0 || row > 2 || column < 0 || column > 3 {
    abort("GlobalTransformBlobWriter::element_setter: invalid row or column")
  }
  let scalar_index = row * 4 + column
  match self.dense_layout {
    Some(layout) =>
      match layout.format {
        Affine3x4F32 =>
          ///|
          /// Implements `this function`.
          fn(index, value) {
            if index < 0 || index >= self.count {
              abort("GlobalTransform element setter: index out of range")
            }
            global_transform_element_setter_set_dense_f32_native(
              self.bytes,
              index,
              value,
              self.first_word,
              layout.words_per_entity,
              scalar_index,
            )
          }
        Affine3x4F16 =>
          ///|
          /// Implements `this function`.
          fn(index, value) {
            if index < 0 || index >= self.count {
              abort("GlobalTransform element setter: index out of range")
            }
            global_transform_element_setter_set_dense_f16_native(
              self.bytes,
              index,
              value,
              self.first_word,
              layout.words_per_entity,
              scalar_index,
            )
          }
      }
    None =>
      ///|
      /// Implements `this function`.
      fn(index, value) {
        if index < 0 || index >= self.count {
          abort("GlobalTransform element setter: index out of range")
        }
        global_transform_element_setter_set_mixed_native(
          self.bytes,
          self.refs,
          index,
          value,
          self.first_word,
          scalar_index,
        )
      }
  }
}

///|

///|
/// Implements `GlobalTransformBlobWriter::element_setter`.
#cfg(not(any(target="js", target="native")))
pub fn GlobalTransformBlobWriter::element_setter(
  self : GlobalTransformBlobWriter,
  row : Int,
  column : Int,
) -> (Int, Float) -> Unit {
  if row < 0 || row > 2 || column < 0 || column > 3 {
    abort("GlobalTransformBlobWriter::element_setter: invalid row or column")
  }
  let scalar_index = row * 4 + column
  match self.dense_layout {
    Some(layout) =>
      match layout.format {
        Affine3x4F32 =>
          ///|
          /// Implements `this function`.
          fn(index, value) {
            if index < 0 || index >= self.count {
              abort("GlobalTransform element setter: index out of range")
            }
            put_global_transform_f32_word(
              self.bytes,
              index * layout.words_per_entity + scalar_index - self.first_word,
              value,
            )
          }
        Affine3x4F16 =>
          ///|
          /// Implements `this function`.
          fn(index, value) {
            if index < 0 || index >= self.count {
              abort("GlobalTransform element setter: index out of range")
            }
            let word = index * layout.words_per_entity +
              scalar_index / 2 -
              self.first_word
            let byte_offset = word * 4
            let old = @writes.get_u32_le_mut_view(self.bytes, byte_offset)
            let half = @comp.global_transform_f32_to_f16_bits(value)
            let next = if scalar_index % 2 == 0 {
              (old & 0xFFFF0000U) | half
            } else {
              (old & 0x0000FFFFU) | (half << 16)
            }
            @writes.put_u32_le_mut_view(self.bytes, byte_offset, next)
          }
      }
    None =>
      ///|
      /// Implements `this function`.
      fn(index, value) {
        if index < 0 || index >= self.count {
          abort("GlobalTransform element setter: index out of range")
        }
        let base = index * 8
        if base + 8 > self.refs.length() {
          abort("GlobalTransform element setter: refs length mismatch")
        }
        let format = @comp.global_transform_format_from_code(
          @writes.get_u32_le(self.refs, base),
        )
        let word_offset = @writes.get_u32_le(self.refs, base + 4).reinterpret_as_int() -
          self.first_word
        match format {
          Affine3x4F32 =>
            put_global_transform_f32_word(
              self.bytes,
              word_offset + scalar_index,
              value,
            )
          Affine3x4F16 => {
            let word = word_offset + scalar_index / 2
            let byte_offset = word * 4
            let old = @writes.get_u32_le_mut_view(self.bytes, byte_offset)
            let half = @comp.global_transform_f32_to_f16_bits(value)
            let next = if scalar_index % 2 == 0 {
              (old & 0xFFFF0000U) | half
            } else {
              (old & 0x0000FFFFU) | (half << 16)
            }
            @writes.put_u32_le_mut_view(self.bytes, byte_offset, next)
          }
        }
      }
  }
}

///|
/// Implements `GlobalTransformBlobWriter::set_affine3x4_at`.
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
/// Implements `write_global_transform_blob_by_refs`.
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
/// Implements `World::write_global_transform_blob_range_by_refs`.
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
    ///|
    /// Implements `this function`.
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
