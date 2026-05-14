///|
#cfg(target="js")
extern "js" fn monotonic_ms() -> Double =
  #| () => performance.now()

///|
#cfg(target="native")
extern "C" fn sdl_get_ticks() -> UInt64 = "SDL_GetTicks"

///|
#cfg(target="native")
fn monotonic_ms() -> Double {
  sdl_get_ticks().to_double()
}

///|
#cfg(not(any(target="js", target="native")))
fn monotonic_ms() -> Double {
  0.0
}

///|
/// Number of root entities (grid layout). Increase to stress CPU/GPU; keep within device limits.
let entity_count : Int = 800_000

///|
/// Canvas resolution (matches demo HTML).
let canvas_width : UInt = 800U

///|
let canvas_height : UInt = 600U

///|
let vertex_stride_local : Int = 12

///|
let instance_stride : Int = 24

///|
let verts_per_cube : Int = 8

///|
let index_u16_count : Int = 36

///|
let index_buffer_byte_length : UInt64 = (index_u16_count * 2).to_uint64()

///|
let camera_elevation_rad : Double = 0.42

///|
let grid_spacing : Double = 0.14

///|
let cube_scale : Float = 0.055

///|
struct DenseTransformLayout {
  format : @comp.GlobalTransformGpuFormat
  words_per_entity : Int
}

///|
/// Smallest `s` with `s * s >= n` for a roughly square XZ grid.
fn grid_side_len(n : Int) -> Int {
  let mut s = 1
  while s * s < n {
    s = s + 1
  }
  s
}

///|
/// View-space **z** extrema of the grid AABB corners after `view_rot` (before extra Z pull).
fn view_space_z_range_corners(
  view_rot : @m44.Matrix44D,
  extent_xz : Double,
  wave_y : Double,
) -> (Double, Double) {
  let sx_arr = [-1.0, 1.0]
  let sz_arr = [-1.0, 1.0]
  let wy_arr = [-1.0, 1.0]
  let mut i = 0
  let mut z_min = (0.0 : Double)
  let mut z_max = (0.0 : Double)
  for sx = 0; sx < 2; sx = sx + 1 {
    for sy = 0; sy < 2; sy = sy + 1 {
      for sz = 0; sz < 2; sz = sz + 1 {
        let wx = sx_arr[sx] * extent_xz
        let wy = wy_arr[sy] * wave_y
        let wz = sz_arr[sz] * extent_xz
        let v = view_rot.mul_vec4(@v4.Vector4::new(wx, wy, wz, (1.0 : Double)))
        let z = v.z()
        if i == 0 {
          z_min = z
          z_max = z
        } else {
          if z < z_min {
            z_min = z
          }
          if z > z_max {
            z_max = z
          }
        }
        i = i + 1
      }
    }
  }
  (z_min, z_max)
}

///|
/// View-space **y** extrema of the same world AABB corners (for ortho `bottom`/`top`).
fn view_space_y_range_corners(
  view_rot : @m44.Matrix44D,
  extent_xz : Double,
  wave_y : Double,
) -> (Double, Double) {
  let sx_arr = [-1.0, 1.0]
  let sz_arr = [-1.0, 1.0]
  let wy_arr = [-1.0, 1.0]
  let mut i = 0
  let mut y_min = (0.0 : Double)
  let mut y_max = (0.0 : Double)
  for sx = 0; sx < 2; sx = sx + 1 {
    for sy = 0; sy < 2; sy = sy + 1 {
      for sz = 0; sz < 2; sz = sz + 1 {
        let wx = sx_arr[sx] * extent_xz
        let wy = wy_arr[sy] * wave_y
        let wz = sz_arr[sz] * extent_xz
        let v = view_rot.mul_vec4(@v4.Vector4::new(wx, wy, wz, (1.0 : Double)))
        let y = v.y()
        if i == 0 {
          y_min = y
          y_max = y
        } else {
          if y < y_min {
            y_min = y
          }
          if y > y_max {
            y_max = y
          }
        }
        i = i + 1
      }
    }
  }
  (y_min, y_max)
}

///|
/// Ortho frustum that fits the tilted XZ grid in view space and matches canvas aspect.
///
/// WebGPU clips to `0 ≤ clip.z ≤ clip.w`. [`Matrix44::ortho`] maps view **z** in
/// `[-far, -near]` to NDC depth `[0, 1]`. This grid can reach **positive** view **z**,
/// so we pull along **−Z** and extend **far** so the whole slab stays inside the clip volume.
fn camera_uniform_bytes() -> FixedArray[Byte] {
  let view_rot = @m44.Matrix44::rotation_x(camera_elevation_rad).mat_mul(
    @m44.Matrix44::translation(0.0, 0.0, -16.0, 1.0, 0.0),
  )
  let per_side = grid_side_len(entity_count)
  let half = (per_side - 1).to_double() * 0.5
  let extent_xz = half * grid_spacing
  let wave = 0.12
  let margin = cube_scale.to_double() * 2.5
  /// World **y** bound: wave motion + scaled unit cube local **y** (±1 in mesh space).
  let wave_y = wave + cube_scale.to_double() * 1.1
  let (y_lo, y_hi) = view_space_y_range_corners(view_rot, extent_xz, wave_y)
  let cy = (y_lo + y_hi) * 0.5
  let hy = (y_hi - y_lo) * 0.5 + margin
  let hx = extent_xz + margin
  let aspect = canvas_width.to_double() / canvas_height.to_double()
  let mut half_w = hx
  let mut half_h = hy
  if half_w / half_h < aspect {
    half_w = half_h * aspect
  } else {
    half_h = half_w / aspect
  }
  let left = -half_w
  let right = half_w
  let bottom = cy - half_h
  let top = cy + half_h
  let (z_lo, z_hi) = view_space_z_range_corners(view_rot, extent_xz, wave_y)
  let pull_z = if z_hi > -0.15 { -z_hi - 1.0 } else { 0.0 }
  let view = @m44.Matrix44::translation(0.0, 0.0, pull_z, 1.0, 0.0).mat_mul(
    view_rot,
  )
  let z_min_pulled = z_lo + pull_z
  let far_need = -z_min_pulled + 8.0
  let far_clip = if far_need > 80.0 { far_need } else { 80.0 }
  let proj = @m44.Matrix44::ortho(left, right, bottom, top, 0.1, far_clip)
  let vp = proj.mat_mul(view)
  let bytes = FixedArray::make(256, (0 : Byte))
  put_mat4_col_major_f64_to_bytes(bytes, vp)
  bytes
}

///|
fn cube_local_corners() -> Array[(Double, Double, Double)] {
  [
    (-1.0, -1.0, -1.0),
    (1.0, -1.0, -1.0),
    (1.0, 1.0, -1.0),
    (-1.0, 1.0, -1.0),
    (-1.0, -1.0, 1.0),
    (1.0, -1.0, 1.0),
    (1.0, 1.0, 1.0),
    (-1.0, 1.0, 1.0),
  ]
}

///|
fn index_cube_u16_bytes() -> FixedArray[Byte] {
  let buf = FixedArray::make(72, (0 : Byte))
  let idx : Array[UInt] = [
    0U, 1U, 2U, 2U, 3U, 0U, 4U, 5U, 6U, 6U, 7U, 4U, 0U, 4U, 7U, 7U, 3U, 0U, 1U, 5U,
    6U, 6U, 2U, 1U, 0U, 1U, 5U, 5U, 4U, 0U, 3U, 2U, 6U, 6U, 7U, 3U,
  ]
  for i = 0; i < index_u16_count; i = i + 1 {
    @writes.put_u16_le(buf, i * 2, idx[i])
  }
  buf
}

///|
fn write_vertex_positions_only(buf : FixedArray[Byte], scale : Double) -> Unit {
  let corners = cube_local_corners()
  for vi = 0; vi < verts_per_cube; vi = vi + 1 {
    let (lx, ly, lz) = corners[vi]
    let base = vi * vertex_stride_local
    @writes.put_f32_le(buf, base + 0, lx * scale)
    @writes.put_f32_le(buf, base + 4, ly * scale)
    @writes.put_f32_le(buf, base + 8, lz * scale)
  }
}

///|
fn put_mat4_col_major_f64_to_bytes(
  out : FixedArray[Byte],
  m : @m44.Matrix44D,
) -> Unit {
  let d = m.data()
  for i = 0; i < 16; i = i + 1 {
    @writes.put_f32_le(out, i * 4, d[i])
  }
}

///|
fn instance_color_rgb(idx : Int) -> (Double, Double, Double) {
  let i = idx % 125
  let r = (i % 5).to_double() * 0.22 + 0.12
  let g = (i / 5 % 5).to_double() * 0.22 + 0.08
  let b = (i / 25 % 5).to_double() * 0.22 + 0.1
  (r, g, b)
}

///|
fn grid_xz_for_index(idx : Int, per_side : Int) -> (Float, Float) {
  let ix = idx % per_side
  let iz = idx / per_side
  let half = (per_side - 1).to_double() * 0.5
  let fx = ix.to_double() - half
  let fz = iz.to_double() - half
  (Float::from_double(fx * grid_spacing), Float::from_double(fz * grid_spacing))
}

///|
#cfg(not(any(target="js", target="native")))
fn f32_to_f16_bits(value : Float) -> UInt {
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
#cfg(not(any(target="js", target="native")))
fn put_packed_f16x2_mut_view(
  buf : MutArrayView[Byte],
  byte_offset : Int,
  x : Float,
  y : Float,
) -> Unit {
  let packed = f32_to_f16_bits(x) | (f32_to_f16_bits(y) << 16)
  @writes.put_u32_le_mut_view(buf, byte_offset, packed)
}

///|
#cfg(not(any(target="js", target="native")))
fn put_f32_word_mut_view(
  buf : MutArrayView[Byte],
  word_offset : Int,
  value : Float,
) -> Unit {
  @writes.put_u32_le_mut_view(buf, word_offset * 4, value.reinterpret_as_uint())
}

///|
fn detect_dense_transform_layout(
  refs : FixedArray[Byte],
  count : Int,
) -> DenseTransformLayout? {
  if refs.length() < count * 8 {
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
#cfg(target="js")
extern "js" fn write_mass_cubes_transform_blob_dense_js(
  bytes : MutArrayView[Byte],
  format_code : UInt,
  words_per_entity : Int,
  entity_count : Int,
  per_side : Int,
  t : Double,
  full_rows : Bool,
  cube_scale : Float,
  grid_spacing : Double,
) -> Unit =
  #| (
  #|   bytes,
  #|   formatCode,
  #|   wordsPerEntity,
  #|   entityCount,
  #|   perSide,
  #|   t,
  #|   fullRows,
  #|   cubeScale,
  #|   gridSpacing,
  #| ) => {
  #|   const src = bytes.buf;
  #|   const start = bytes.start;
  #|   const byteLength = bytes.end - bytes.start;
  #|   if (!ArrayBuffer.isView(src)) {
  #|     throw new Error("MassCubes dense transform blob requires typed byte storage.");
  #|   }
  #|   const waveTime = t * 1.8;
  #|   const sinStep = Math.sin(0.09);
  #|   const cosStep = Math.cos(0.09);
  #|   const isF16 = formatCode === 1;
  #|   let f32ToF16Bits = null;
  #|   const makeF16Bits = () => {
  #|     let cache = globalThis.__rhodonite_f32_to_f16_table;
  #|     if (!cache) {
  #|       const base = new Uint16Array(512);
  #|       const shift = new Uint8Array(512);
  #|       for (let i = 0; i < 256; i++) {
  #|         const e = i - 127;
  #|         if (e < -24) {
  #|           base[i] = 0x0000;
  #|           base[i | 0x100] = 0x8000;
  #|           shift[i] = 24;
  #|           shift[i | 0x100] = 24;
  #|         } else if (e < -14) {
  #|           const b = 0x0400 >> (-e - 14);
  #|           const s = -e - 1;
  #|           base[i] = b;
  #|           base[i | 0x100] = b | 0x8000;
  #|           shift[i] = s;
  #|           shift[i | 0x100] = s;
  #|         } else if (e <= 15) {
  #|           const b = (e + 15) << 10;
  #|           base[i] = b;
  #|           base[i | 0x100] = b | 0x8000;
  #|           shift[i] = 13;
  #|           shift[i | 0x100] = 13;
  #|         } else if (e < 128) {
  #|           base[i] = 0x7c00;
  #|           base[i | 0x100] = 0xfc00;
  #|           shift[i] = 24;
  #|           shift[i | 0x100] = 24;
  #|         } else {
  #|           base[i] = 0x7c00;
  #|           base[i | 0x100] = 0xfc00;
  #|           shift[i] = 13;
  #|           shift[i | 0x100] = 13;
  #|         }
  #|       }
  #|       const scratchF32 = new Float32Array(1);
  #|       const scratchU32 = new Uint32Array(scratchF32.buffer);
  #|       cache = globalThis.__rhodonite_f32_to_f16_table = {
  #|         base,
  #|         shift,
  #|         scratchF32,
  #|         scratchU32,
  #|       };
  #|     }
  #|     return (value) => {
  #|       cache.scratchF32[0] = Math.fround(value);
  #|       const bits = cache.scratchU32[0] >>> 0;
  #|       const index = (bits >>> 23) & 0x1ff;
  #|       return cache.base[index] + ((bits & 0x007fffff) >>> cache.shift[index]);
  #|     };
  #|   };
  #|   if (isF16) {
  #|     let halfRows = null;
  #|     const Float16ArrayCtor = globalThis.Float16Array;
  #|     if (typeof Float16ArrayCtor === "function") {
  #|       halfRows = new Float16ArrayCtor(src.buffer, src.byteOffset + start, byteLength >> 1);
  #|     } else {
  #|       halfRows = new Uint16Array(src.buffer, src.byteOffset + start, byteLength >> 1);
  #|       f32ToF16Bits = makeF16Bits();
  #|     }
  #|     const writeHalf = f32ToF16Bits === null
  #|       ? (index, value) => { halfRows[index] = value; }
  #|       : (index, value) => { halfRows[index] = f32ToF16Bits(value); };
  #|     if (!fullRows) {
  #|       let waveSin = Math.sin(waveTime);
  #|       let waveCos = Math.cos(waveTime);
  #|       for (let i = 0; i < entityCount; i++) {
  #|         writeHalf(i * 12 + 7, waveSin * 0.12);
  #|         const nextSin = waveSin * cosStep + waveCos * sinStep;
  #|         waveCos = waveCos * cosStep - waveSin * sinStep;
  #|         waveSin = nextSin;
  #|       }
  #|       return;
  #|     }
  #|     const half = (perSide - 1) * 0.5;
  #|     let localIndex = 0;
  #|     let row = 0;
  #|     while (localIndex < entityCount) {
  #|       const rowCount = Math.min(perSide, entityCount - localIndex);
  #|       let x = -half * gridSpacing;
  #|       const z = (row - half) * gridSpacing;
  #|       let waveSin = Math.sin(localIndex * 0.09 + waveTime);
  #|       let waveCos = Math.cos(localIndex * 0.09 + waveTime);
  #|       for (let ix = 0; ix < rowCount; ix++) {
  #|         const out = localIndex * 12;
  #|         writeHalf(out, cubeScale);
  #|         writeHalf(out + 1, 0);
  #|         writeHalf(out + 2, 0);
  #|         writeHalf(out + 3, x);
  #|         writeHalf(out + 4, 0);
  #|         writeHalf(out + 5, cubeScale);
  #|         writeHalf(out + 6, 0);
  #|         writeHalf(out + 7, waveSin * 0.12);
  #|         writeHalf(out + 8, 0);
  #|         writeHalf(out + 9, 0);
  #|         writeHalf(out + 10, cubeScale);
  #|         writeHalf(out + 11, z);
  #|         const nextSin = waveSin * cosStep + waveCos * sinStep;
  #|         waveCos = waveCos * cosStep - waveSin * sinStep;
  #|         waveSin = nextSin;
  #|         localIndex++;
  #|         x += gridSpacing;
  #|       }
  #|       row++;
  #|     }
  #|     return;
  #|   }
  #|   const floats = new Float32Array(src.buffer, src.byteOffset + start, byteLength >> 2);
  #|   if (!fullRows) {
  #|     let waveSin = Math.sin(waveTime);
  #|     let waveCos = Math.cos(waveTime);
  #|     for (let i = 0; i < entityCount; i++) {
  #|       floats[i * wordsPerEntity + 7] = waveSin * 0.12;
  #|       const nextSin = waveSin * cosStep + waveCos * sinStep;
  #|       waveCos = waveCos * cosStep - waveSin * sinStep;
  #|       waveSin = nextSin;
  #|     }
  #|     return;
  #|   }
  #|   const half = (perSide - 1) * 0.5;
  #|   let localIndex = 0;
  #|   let row = 0;
  #|   while (localIndex < entityCount) {
  #|     const rowCount = Math.min(perSide, entityCount - localIndex);
  #|     let x = -half * gridSpacing;
  #|     const z = (row - half) * gridSpacing;
  #|     let waveSin = Math.sin(localIndex * 0.09 + waveTime);
  #|     let waveCos = Math.cos(localIndex * 0.09 + waveTime);
  #|     for (let ix = 0; ix < rowCount; ix++) {
  #|       const out = localIndex * wordsPerEntity;
  #|       floats[out] = cubeScale;
  #|       floats[out + 1] = 0;
  #|       floats[out + 2] = 0;
  #|       floats[out + 3] = x;
  #|       floats[out + 4] = 0;
  #|       floats[out + 5] = cubeScale;
  #|       floats[out + 6] = 0;
  #|       floats[out + 7] = waveSin * 0.12;
  #|       floats[out + 8] = 0;
  #|       floats[out + 9] = 0;
  #|       floats[out + 10] = cubeScale;
  #|       floats[out + 11] = z;
  #|       const nextSin = waveSin * cosStep + waveCos * sinStep;
  #|       waveCos = waveCos * cosStep - waveSin * sinStep;
  #|       waveSin = nextSin;
  #|       localIndex++;
  #|       x += gridSpacing;
  #|     }
  #|     row++;
  #|   }
  #| }

///|
#cfg(target="js")
fn write_mass_cubes_transform_blob_dense(
  bytes : MutArrayView[Byte],
  layout : DenseTransformLayout,
  per_side : Int,
  t : Double,
  full_rows : Bool,
) -> Unit {
  write_mass_cubes_transform_blob_dense_js(
    bytes,
    @comp.global_transform_format_code(layout.format),
    layout.words_per_entity,
    entity_count,
    per_side,
    t,
    full_rows,
    cube_scale,
    grid_spacing,
  )
}

///|
#cfg(target="native")
#borrow(bytes)
extern "C" fn write_mass_cubes_transform_blob_dense_native(
  bytes : MutArrayView[Byte],
  format_code : UInt,
  words_per_entity : Int,
  entity_count : Int,
  per_side : Int,
  t : Double,
  full_rows : Bool,
  cube_scale : Float,
  grid_spacing : Double,
) -> Unit = "rhodonite_mass_cubes_write_transform_blob_dense"

///|
#cfg(target="native")
fn write_mass_cubes_transform_blob_dense(
  bytes : MutArrayView[Byte],
  layout : DenseTransformLayout,
  per_side : Int,
  t : Double,
  full_rows : Bool,
) -> Unit {
  write_mass_cubes_transform_blob_dense_native(
    bytes,
    @comp.global_transform_format_code(layout.format),
    layout.words_per_entity,
    entity_count,
    per_side,
    t,
    full_rows,
    cube_scale,
    grid_spacing,
  )
}

///|
#cfg(not(any(target="js", target="native")))
fn write_mass_cubes_transform_blob_dense(
  bytes : MutArrayView[Byte],
  layout : DenseTransformLayout,
  per_side : Int,
  t : Double,
  full_rows : Bool,
) -> Unit {
  let wave_time = t * 1.8
  let sin_step = @math.sin(0.09)
  let cos_step = @math.cos(0.09)
  let zero = (0.0 : Float)
  match layout.format {
    Affine3x4F16 => {
      if !full_rows {
        let mut i = 0
        let mut wave_sin = @math.sin(wave_time)
        let mut wave_cos = @math.cos(wave_time)
        while i < entity_count {
          let y = Float::from_double(wave_sin * 0.12)
          put_packed_f16x2_mut_view(
            bytes,
            (i * layout.words_per_entity + 3) * 4,
            zero,
            y,
          )
          let next_sin = wave_sin * cos_step + wave_cos * sin_step
          wave_cos = wave_cos * cos_step - wave_sin * sin_step
          wave_sin = next_sin
          i = i + 1
        }
        return
      }
      let half = (per_side - 1).to_double() * 0.5
      let step = Float::from_double(grid_spacing)
      let mut local_index = 0
      let mut row = 0
      while local_index < entity_count {
        let remaining = entity_count - local_index
        let row_count = if per_side < remaining { per_side } else { remaining }
        let mut x = Float::from_double((0.0 - half) * grid_spacing)
        let z = Float::from_double((row.to_double() - half) * grid_spacing)
        let phase = local_index.to_double() * 0.09 + wave_time
        let mut wave_sin = @math.sin(phase)
        let mut wave_cos = @math.cos(phase)
        for _ix = 0; _ix < row_count; _ix = _ix + 1 {
          let base = local_index * layout.words_per_entity * 4
          let y = Float::from_double(wave_sin * 0.12)
          put_packed_f16x2_mut_view(bytes, base + 0, cube_scale, zero)
          put_packed_f16x2_mut_view(bytes, base + 4, zero, x)
          put_packed_f16x2_mut_view(bytes, base + 8, zero, cube_scale)
          put_packed_f16x2_mut_view(bytes, base + 12, zero, y)
          put_packed_f16x2_mut_view(bytes, base + 16, zero, zero)
          put_packed_f16x2_mut_view(bytes, base + 20, cube_scale, z)
          let next_sin = wave_sin * cos_step + wave_cos * sin_step
          wave_cos = wave_cos * cos_step - wave_sin * sin_step
          wave_sin = next_sin
          local_index = local_index + 1
          x = x + step
        }
        row = row + 1
      }
    }
    Affine3x4F32 => {
      if !full_rows {
        let mut i = 0
        let mut wave_sin = @math.sin(wave_time)
        let mut wave_cos = @math.cos(wave_time)
        while i < entity_count {
          let y = Float::from_double(wave_sin * 0.12)
          put_f32_word_mut_view(bytes, i * layout.words_per_entity + 7, y)
          let next_sin = wave_sin * cos_step + wave_cos * sin_step
          wave_cos = wave_cos * cos_step - wave_sin * sin_step
          wave_sin = next_sin
          i = i + 1
        }
        return
      }
      let half = (per_side - 1).to_double() * 0.5
      let step = Float::from_double(grid_spacing)
      let mut local_index = 0
      let mut row = 0
      while local_index < entity_count {
        let remaining = entity_count - local_index
        let row_count = if per_side < remaining { per_side } else { remaining }
        let mut x = Float::from_double((0.0 - half) * grid_spacing)
        let z = Float::from_double((row.to_double() - half) * grid_spacing)
        let phase = local_index.to_double() * 0.09 + wave_time
        let mut wave_sin = @math.sin(phase)
        let mut wave_cos = @math.cos(phase)
        for _ix = 0; _ix < row_count; _ix = _ix + 1 {
          let base = local_index * layout.words_per_entity
          let y = Float::from_double(wave_sin * 0.12)
          put_f32_word_mut_view(bytes, base + 0, cube_scale)
          @writes.put_u32_le_mut_view(bytes, (base + 1) * 4, 0U)
          @writes.put_u32_le_mut_view(bytes, (base + 2) * 4, 0U)
          put_f32_word_mut_view(bytes, base + 3, x)
          @writes.put_u32_le_mut_view(bytes, (base + 4) * 4, 0U)
          put_f32_word_mut_view(bytes, base + 5, cube_scale)
          @writes.put_u32_le_mut_view(bytes, (base + 6) * 4, 0U)
          put_f32_word_mut_view(bytes, base + 7, y)
          @writes.put_u32_le_mut_view(bytes, (base + 8) * 4, 0U)
          @writes.put_u32_le_mut_view(bytes, (base + 9) * 4, 0U)
          put_f32_word_mut_view(bytes, base + 10, cube_scale)
          put_f32_word_mut_view(bytes, base + 11, z)
          let next_sin = wave_sin * cos_step + wave_cos * sin_step
          wave_cos = wave_cos * cos_step - wave_sin * sin_step
          wave_sin = next_sin
          local_index = local_index + 1
          x = x + step
        }
        row = row + 1
      }
    }
  }
}

///|
fn write_dense_global_transform_views(
  world : @ecs.World,
  layout : DenseTransformLayout,
  per_side : Int,
  t : Double,
  full_rows : Bool,
) -> Array[@ecs.GpuWriteView] {
  world.write_global_transform_blob_range_views(
    0,
    entity_count * layout.words_per_entity,
    fn(bytes) {
      write_mass_cubes_transform_blob_dense(
        bytes, layout, per_side, t, full_rows,
      )
    },
  )
}

///|
fn animate_transforms_query(
  world : @ecs.World,
  tf_id : @ecs.ComponentTypeId,
  per_side : Int,
  t : Double,
) -> Unit {
  ignore(tf_id)
  world.update_transform3d_positions(fn(entity) {
    let idx = entity.index
    let (gx, gz) = grid_xz_for_index(idx, per_side)
    let phase = idx.to_double() * 0.09 + t * 1.8
    let wy = @math.sin(phase) * 0.12
    (gx, Float::from_double(wy), gz)
  })
}

///|
fn update_and_drain_global_transforms(
  world : @ecs.World,
  tf : @ecs.ComponentTypeId,
  gt : @ecs.ComponentTypeId,
  per_side : Int,
  t : Double,
  dense_transform_layout : DenseTransformLayout?,
  full_rows : Bool,
) -> Array[@ecs.GpuWriteView] {
  match dense_transform_layout {
    Some(layout) =>
      write_dense_global_transform_views(world, layout, per_side, t, full_rows)
    None => {
      ignore(gt)
      animate_transforms_query(world, tf, per_side, t)
      world.update_global_transforms_from_transforms()
      world.drain_global_transform_blob_write_views()
    }
  }
}

///|
fn upload_global_transform_writes(
  queue : @wgpu.GPUQueue,
  transform_storage : @wgpu.GPUBuffer,
  writes : Array[@ecs.GpuWriteView],
) -> Unit {
  for wi = 0; wi < writes.length(); wi = wi + 1 {
    let w = writes[wi]
    queue.write_buffer_from_array_view(
      transform_storage,
      w.byte_offset.to_uint64(),
      w.bytes,
    )
  }
}

///|
pub(all) struct WebGPURenderer {
  context : @wgpu.GPUCanvasContext
  device : @wgpu.GPUDevice
  queue : @wgpu.GPUQueue
  pipeline : @wgpu.GPURenderPipeline
  depth_texture : @wgpu.GPUTexture
  depth_view : @wgpu.GPUTextureView
  vertex_buffer : @wgpu.GPUBuffer
  instance_buffer : @wgpu.GPUBuffer
  index_buffer : @wgpu.GPUBuffer
  transform_storage : @wgpu.GPUBuffer
  camera_uniform : @wgpu.GPUBuffer
  bind_transforms : @wgpu.GPUBindGroup
  bind_camera : @wgpu.GPUBindGroup
  layout_transforms : @wgpu.GPUBindGroupLayout
  layout_camera : @wgpu.GPUBindGroupLayout
  world : @ecs.World
  gt : @ecs.ComponentTypeId
  tf : @ecs.ComponentTypeId
  per_side : Int
  dense_transform_layout : DenseTransformLayout?
  bind_group_offsets : Array[UInt]
  frame : @ref.Ref[Int]
  perf_last_frame_start_ms : @ref.Ref[Double]
}

///|
fn ecs_mass_shader_wgsl() -> String {
  let code =
    #|struct CameraUniform {
    #|  view_proj: mat4x4<f32>,
    #|}
    #|
    #|@group(0) @binding(0) var<storage, read> transform_words: array<u32>;
    #|@group(1) @binding(0) var<uniform> camera: CameraUniform;
    #|
    #|struct VertexOut {
    #|  @builtin(position) position: vec4<f32>,
    #|  @location(0) color: vec3<f32>,
    #|};
    #|
    #|@vertex
    #|fn vertexMain(
    #|  @location(0) local_pos: vec3<f32>,
    #|  @location(1) transform_ref: vec2<u32>,
    #|  @location(2) color: vec3<f32>,
    #|) -> VertexOut {
    #|  let format = transform_ref.x;
    #|  let word_offset = transform_ref.y;
    #|  var row0: vec4<f32>;
    #|  var row1: vec4<f32>;
    #|  var row2: vec4<f32>;
    #|  if (format == 1u) {
    #|    let r0xy = unpack2x16float(transform_words[word_offset + 0u]);
    #|    let r0zw = unpack2x16float(transform_words[word_offset + 1u]);
    #|    let r1xy = unpack2x16float(transform_words[word_offset + 2u]);
    #|    let r1zw = unpack2x16float(transform_words[word_offset + 3u]);
    #|    let r2xy = unpack2x16float(transform_words[word_offset + 4u]);
    #|    let r2zw = unpack2x16float(transform_words[word_offset + 5u]);
    #|    row0 = vec4<f32>(r0xy.x, r0xy.y, r0zw.x, r0zw.y);
    #|    row1 = vec4<f32>(r1xy.x, r1xy.y, r1zw.x, r1zw.y);
    #|    row2 = vec4<f32>(r2xy.x, r2xy.y, r2zw.x, r2zw.y);
    #|  } else {
    #|    row0 = vec4<f32>(
    #|      bitcast<f32>(transform_words[word_offset + 0u]),
    #|      bitcast<f32>(transform_words[word_offset + 1u]),
    #|      bitcast<f32>(transform_words[word_offset + 2u]),
    #|      bitcast<f32>(transform_words[word_offset + 3u]),
    #|    );
    #|    row1 = vec4<f32>(
    #|      bitcast<f32>(transform_words[word_offset + 4u]),
    #|      bitcast<f32>(transform_words[word_offset + 5u]),
    #|      bitcast<f32>(transform_words[word_offset + 6u]),
    #|      bitcast<f32>(transform_words[word_offset + 7u]),
    #|    );
    #|    row2 = vec4<f32>(
    #|      bitcast<f32>(transform_words[word_offset + 8u]),
    #|      bitcast<f32>(transform_words[word_offset + 9u]),
    #|      bitcast<f32>(transform_words[word_offset + 10u]),
    #|      bitcast<f32>(transform_words[word_offset + 11u]),
    #|    );
    #|  }
    #|  let local_h = vec4<f32>(local_pos, 1.0);
    #|  let world_pos = vec4<f32>(
    #|    dot(row0, local_h),
    #|    dot(row1, local_h),
    #|    dot(row2, local_h),
    #|    1.0,
    #|  );
    #|  let clip = camera.view_proj * world_pos;
    #|  var o: VertexOut;
    #|  o.position = clip;
    #|  o.color = color;
    #|  return o;
    #|}
    #|
    #|@fragment
    #|fn fragmentMain(@location(0) color: vec3<f32>) -> @location(0) vec4<f32> {
    #|  return vec4<f32>(color, 1.0);
    #|}
    #|
  code
}

///|
#cfg(target="js")
extern "js" fn ecs_mass_cubes_perf_overlay_js(
  fps : Double,
  cpu_ms : Double,
) -> Unit =
  #| (fps, cpuMs) => {
  #|   const el = document.getElementById("ecs-mass-cubes-perf");
  #|   if (!el) return;
  #|   el.textContent =
  #|     "FPS " +
  #|     fps.toFixed(1) +
  #|     "  ·  CPU " +
  #|     cpuMs.toFixed(2) +
  #|     " ms / frame (submit まで)";
  #| }

///|
#cfg(target="js")
fn ecs_mass_cubes_perf_overlay(fps : Double, cpu_ms : Double) -> Unit {
  ecs_mass_cubes_perf_overlay_js(fps, cpu_ms)
}

///|
#cfg(not(target="js"))
fn ecs_mass_cubes_perf_overlay(_fps : Double, _cpu_ms : Double) -> Unit {
  ignore(_fps)
  ignore(_cpu_ms)
  ()
}

///|
#cfg(target="native")
fn ecs_mass_cubes_perf_console_log(
  fps : Double,
  cpu_ms : Double,
  frame_idx : Int,
) -> Unit {
  if frame_idx < 2 || frame_idx % 30 != 0 {
    return
  }
  println(
    "ecs-mass-cubes: FPS=" +
    fps.to_string() +
    "  CPU=" +
    cpu_ms.to_string() +
    " ms/frame (until submit)",
  )
}

///|
#cfg(not(target="native"))
fn ecs_mass_cubes_perf_console_log(
  _fps : Double,
  _cpu_ms : Double,
  _frame_idx : Int,
) -> Unit {
  ignore(_fps)
  ignore(_cpu_ms)
  ignore(_frame_idx)
  ()
}

///|
pub fn create_renderer(context : @wgpu.GPUContext) -> WebGPURenderer? {
  let (device, canvas_context, format, queue) = context.get()
  let shader = device.create_shader_module(ecs_mass_shader_wgsl())
  let vertex_layout_vertices : @wgpu.GPUVertexBufferLayout = {
    array_stride: vertex_stride_local.to_uint64(),
    step_mode: @wgpu.GPUVertexStepMode::Vertex,
    attributes: [
      {
        format: @wgpu.GPUVertexFormat::Float32x3,
        offset: 0UL,
        shader_location: 0U,
      },
    ],
  }
  let vertex_layout_instances : @wgpu.GPUVertexBufferLayout = {
    array_stride: instance_stride.to_uint64(),
    step_mode: @wgpu.GPUVertexStepMode::Instance,
    attributes: [
      {
        format: @wgpu.GPUVertexFormat::Uint32x2,
        offset: 0UL,
        shader_location: 1U,
      },
      {
        format: @wgpu.GPUVertexFormat::Float32x3,
        offset: 8UL,
        shader_location: 2U,
      },
    ],
  }
  let pipeline_descriptor : @wgpu.GPURenderPipelineDescriptor = {
    vertex: shader,
    fragment: shader,
    topology: @wgpu.GPUPrimitiveTopology::TriangleList,
    formats: [format],
    vertex_buffers: [vertex_layout_vertices, vertex_layout_instances],
    depth_stencil_format: Some("depth24plus"),
  }
  let pipeline = device.create_render_pipeline(pipeline_descriptor)
  @wgpu.shaderModule_release(shader)
  let layout_transforms = pipeline.get_bind_group_layout(0U)
  let layout_camera = pipeline.get_bind_group_layout(1U)
  let world = @ecs.World::new_with_global_transform_format(Affine3x4F16)
  let gt = world.global_transform_component()
  let tf = world.transform_component()
  let per_side = grid_side_len(entity_count)
  let inst_bytes_len = entity_count * instance_stride
  let instance_bytes = FixedArray::make(inst_bytes_len, (0 : Byte))
  let entities = world.spawn_transform_global_batch(entity_count, fn(
    i,
    e,
    tf_row,
    _gt_row,
  ) {
    let (gx, gz) = grid_xz_for_index(i, per_side)
    @comp.Transform3D::write_trs_to_component_mut_view(
      tf_row,
      gx,
      (0.0 : Float),
      gz,
      0.0,
      0.0,
      0.0,
      1.0,
      cube_scale,
      cube_scale,
      cube_scale,
    )
    let base = i * instance_stride
    let (cr, cg, cb) = instance_color_rgb(e.index)
    @writes.put_f32_le(instance_bytes, base + 8, cr)
    @writes.put_f32_le(instance_bytes, base + 12, cg)
    @writes.put_f32_le(instance_bytes, base + 16, cb)
  })
  world.write_global_transform_refs_into(
    entities, instance_bytes, instance_stride, 0,
  )
  let transform_refs = world.extract_global_transform_refs(entities)
  let dense_transform_layout = detect_dense_transform_layout(
    transform_refs, entity_count,
  )
  let storage_bytes = (world.global_transform_blob_word_capacity() * 4).to_uint64()
  let s_usage = @wgpu.GPU_BUFFER_USAGE_STORAGE | @wgpu.GPU_BUFFER_USAGE_COPY_DST
  let transform_storage = device.create_buffer(storage_bytes, s_usage)
  let cam_usage = @wgpu.GPU_BUFFER_USAGE_UNIFORM |
    @wgpu.GPU_BUFFER_USAGE_COPY_DST
  let camera_uniform = device.create_buffer(256UL, cam_usage)
  queue.write_buffer_from_fixed_array(
    camera_uniform,
    0UL,
    camera_uniform_bytes(),
  )
  let bind_transforms = device.create_bind_group({
    layout: layout_transforms,
    entries: [
      {
        binding: 0U,
        resource: @wgpu.GPUBindingResource::Buffer(transform_storage),
      },
    ],
  })
  let bind_camera = device.create_bind_group({
    layout: layout_camera,
    entries: [
      {
        binding: 0U,
        resource: @wgpu.GPUBindingResource::Buffer(camera_uniform),
      },
    ],
  })
  let vusage = @wgpu.GPU_BUFFER_USAGE_VERTEX | @wgpu.GPU_BUFFER_USAGE_COPY_DST
  let vertex_byte_len = (verts_per_cube * vertex_stride_local).to_uint64()
  let vertex_buffer = device.create_buffer(vertex_byte_len, vusage)
  let vertex_bytes = FixedArray::make(
    verts_per_cube * vertex_stride_local,
    (0 : Byte),
  )
  write_vertex_positions_only(vertex_bytes, 0.42)
  queue.write_buffer_from_fixed_array(vertex_buffer, 0UL, vertex_bytes)
  let instance_buffer = device.create_buffer(inst_bytes_len.to_uint64(), vusage)
  queue.write_buffer_from_fixed_array(instance_buffer, 0UL, instance_bytes)
  let iusage = @wgpu.GPU_BUFFER_USAGE_INDEX | @wgpu.GPU_BUFFER_USAGE_COPY_DST
  let index_buffer = device.create_buffer(index_buffer_byte_length, iusage)
  let index_bytes = index_cube_u16_bytes()
  queue.write_buffer_from_fixed_array(index_buffer, 0UL, index_bytes)
  let depth_texture = device.create_texture(
    canvas_width,
    canvas_height,
    "depth24plus",
    @wgpu.GPU_TEXTURE_USAGE_RENDER_ATTACHMENT,
  )
  let depth_view = depth_texture.create_view()
  let writes0 = update_and_drain_global_transforms(
    world, tf, gt, per_side, 0.0, dense_transform_layout, true,
  )
  upload_global_transform_writes(queue, transform_storage, writes0)
  Some({
    context: canvas_context,
    device,
    queue,
    pipeline,
    depth_texture,
    depth_view,
    vertex_buffer,
    instance_buffer,
    index_buffer,
    transform_storage,
    camera_uniform,
    bind_transforms,
    bind_camera,
    layout_transforms,
    layout_camera,
    world,
    gt,
    tf,
    per_side,
    dense_transform_layout,
    bind_group_offsets: [],
    frame: @ref.new(0),
    perf_last_frame_start_ms: @ref.new(-1.0),
  })
}

///|
pub fn render_frame(renderer : WebGPURenderer) -> Unit {
  let t_frame_start = monotonic_ms()
  let last_start = renderer.perf_last_frame_start_ms.val
  let fps = if last_start >= 0.0 {
    let wall_dt = t_frame_start - last_start
    if wall_dt > 1.0e-9 {
      1000.0 / wall_dt
    } else {
      0.0
    }
  } else {
    0.0
  }
  renderer.perf_last_frame_start_ms.val = t_frame_start
  renderer.frame.val = renderer.frame.val + 1
  let t = renderer.frame.val.to_double() * 0.018
  let gt = renderer.gt
  let tf = renderer.tf
  let writes = update_and_drain_global_transforms(
    renderer.world,
    tf,
    gt,
    renderer.per_side,
    t,
    renderer.dense_transform_layout,
    false,
  )
  upload_global_transform_writes(
    renderer.queue,
    renderer.transform_storage,
    writes,
  )
  let texture = renderer.context.get_current_texture()
  let color_view = texture.create_view()
  let encoder = renderer.device.create_command_encoder()
  let render_pass = encoder.begin_render_pass({
    color_attachments: [
      Some({
        view: color_view,
        clear_value: Some({ r: 0.03, g: 0.04, b: 0.09, a: 1.0 }),
        load_op: @wgpu.GPULoadOp::Clear,
        store_op: @wgpu.GPUStoreOp::Store,
      }),
    ],
    depth_stencil_attachment: Some({
      view: renderer.depth_view,
      depth_clear_value: Some(1.0),
      depth_load_op: @wgpu.GPULoadOp::Clear,
      depth_store_op: @wgpu.GPUStoreOp::Store,
    }),
  })
  render_pass.set_pipeline(renderer.pipeline)
  render_pass.set_bind_group(
    0U,
    renderer.bind_transforms,
    renderer.bind_group_offsets,
  )
  render_pass.set_bind_group(
    1U,
    renderer.bind_camera,
    renderer.bind_group_offsets,
  )
  render_pass.set_index_buffer(
    renderer.index_buffer,
    @wgpu.GPUIndexFormat::Uint16,
    0UL,
    index_buffer_byte_length,
  )
  render_pass.set_vertex_buffer(
    0,
    renderer.vertex_buffer,
    0UL,
    (verts_per_cube * vertex_stride_local).to_uint64(),
  )
  render_pass.set_vertex_buffer(
    1,
    renderer.instance_buffer,
    0UL,
    (entity_count * instance_stride).to_uint64(),
  )
  render_pass.draw_indexed(index_u16_count, instance_count=entity_count)
  render_pass.end()
  render_pass.release()
  let command_buffer = encoder.finish()
  renderer.queue.submit(command_buffer)
  encoder.release()
  let cpu_ms = monotonic_ms() - t_frame_start
  ecs_mass_cubes_perf_overlay(fps, cpu_ms)
  ecs_mass_cubes_perf_console_log(fps, cpu_ms, renderer.frame.val)
  @wgpu.textureView_release(color_view)
  renderer.context.present()
}

///|
pub fn WebGPURenderer::release(self : WebGPURenderer) -> Unit {
  @wgpu.bindGroup_release(self.bind_transforms)
  @wgpu.bindGroup_release(self.bind_camera)
  @wgpu.bindGroupLayout_release(self.layout_transforms)
  @wgpu.bindGroupLayout_release(self.layout_camera)
  self.index_buffer.release()
  self.instance_buffer.release()
  self.vertex_buffer.release()
  self.transform_storage.release()
  self.camera_uniform.release()
  @wgpu.textureView_release(self.depth_view)
  self.depth_texture.release()
  self.pipeline.release()
}

///|
pub fn webgpu_renderer_release(renderer : WebGPURenderer) -> Unit {
  renderer.release()
}
