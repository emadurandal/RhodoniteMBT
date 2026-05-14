#include <math.h>
#include <stdint.h>
#include <string.h>

#include "moonbit.h"

typedef struct RhodoniteArrayViewU8 {
  int32_t start;
  int32_t end;
  moonbit_bytes_t bytes;
} RhodoniteArrayViewU8;

static uint16_t rhodonite_f32_to_f16_bits(float value) {
  uint32_t bits;
  memcpy(&bits, &value, sizeof(bits));
  uint32_t sign = (bits >> 16) & 0x8000u;
  int32_t exp = (int32_t)((bits >> 23) & 0xffu);
  uint32_t mant = bits & 0x7fffffu;
  if (exp == 255) {
    return (uint16_t)(sign | (mant == 0 ? 0x7c00u : 0x7e00u));
  }
  int32_t half_exp = exp - 127 + 15;
  if (half_exp >= 31) {
    return (uint16_t)(sign | 0x7c00u);
  }
  if (half_exp <= 0) {
    if (half_exp < -10) {
      return (uint16_t)sign;
    }
    uint32_t mantissa = mant | 0x800000u;
    int32_t shift = 14 - half_exp;
    uint32_t half_mant = mantissa >> shift;
    if (((mantissa >> (shift - 1)) & 1u) != 0) {
      half_mant += 1u;
    }
    return (uint16_t)(sign | half_mant);
  }
  uint32_t half = sign | ((uint32_t)half_exp << 10) | (mant >> 13);
  if (((mant >> 12) & 1u) != 0) {
    half += 1u;
  }
  return (uint16_t)half;
}

static void put_u16_le(uint8_t* bytes, int32_t off, uint16_t value) {
  bytes[off] = (uint8_t)(value & 0xffu);
  bytes[off + 1] = (uint8_t)((value >> 8) & 0xffu);
}

static void put_u32_le(uint8_t* bytes, int32_t off, uint32_t value) {
  bytes[off] = (uint8_t)(value & 0xffu);
  bytes[off + 1] = (uint8_t)((value >> 8) & 0xffu);
  bytes[off + 2] = (uint8_t)((value >> 16) & 0xffu);
  bytes[off + 3] = (uint8_t)((value >> 24) & 0xffu);
}

static uint32_t get_u32_le(const uint8_t* bytes, int32_t off) {
  return (uint32_t)bytes[off] |
         ((uint32_t)bytes[off + 1] << 8) |
         ((uint32_t)bytes[off + 2] << 16) |
         ((uint32_t)bytes[off + 3] << 24);
}

static uint32_t f32_bits(float value) {
  uint32_t bits;
  memcpy(&bits, &value, sizeof(bits));
  return bits;
}

static void put_f32_word(uint8_t* bytes, int32_t word_offset, float value) {
  put_u32_le(bytes, word_offset * 4, f32_bits(value));
}

static void put_packed_f16x2(
  uint8_t* bytes,
  int32_t byte_offset,
  float x,
  float y
) {
  put_u16_le(bytes, byte_offset, rhodonite_f32_to_f16_bits(x));
  put_u16_le(bytes, byte_offset + 2, rhodonite_f32_to_f16_bits(y));
}

void rhodonite_mass_cubes_write_transform_blob_dense(
  RhodoniteArrayViewU8 view,
  uint32_t format_code,
  int32_t words_per_entity,
  int32_t entity_count,
  int32_t per_side,
  double t,
  int32_t full_rows,
  float cube_scale,
  double grid_spacing
) {
  uint8_t* bytes = view.bytes + view.start;
  double wave_time = t * 1.8;
  double sin_step = sin(0.09);
  double cos_step = cos(0.09);
  if (format_code == 1u) {
    if (!full_rows) {
      double wave_sin = sin(wave_time);
      double wave_cos = cos(wave_time);
      for (int32_t i = 0; i < entity_count; i++) {
        float y = (float)(wave_sin * 0.12);
        put_packed_f16x2(bytes, (i * words_per_entity + 3) * 4, 0.0f, y);
        double next_sin = wave_sin * cos_step + wave_cos * sin_step;
        wave_cos = wave_cos * cos_step - wave_sin * sin_step;
        wave_sin = next_sin;
      }
      return;
    }
    double half = ((double)per_side - 1.0) * 0.5;
    int32_t local_index = 0;
    int32_t row = 0;
    while (local_index < entity_count) {
      int32_t remaining = entity_count - local_index;
      int32_t row_count = per_side < remaining ? per_side : remaining;
      float x = (float)(-half * grid_spacing);
      float z = (float)(((double)row - half) * grid_spacing);
      double wave_sin = sin((double)local_index * 0.09 + wave_time);
      double wave_cos = cos((double)local_index * 0.09 + wave_time);
      for (int32_t ix = 0; ix < row_count; ix++) {
        int32_t base = local_index * words_per_entity * 4;
        float y = (float)(wave_sin * 0.12);
        put_packed_f16x2(bytes, base + 0, cube_scale, 0.0f);
        put_packed_f16x2(bytes, base + 4, 0.0f, x);
        put_packed_f16x2(bytes, base + 8, 0.0f, cube_scale);
        put_packed_f16x2(bytes, base + 12, 0.0f, y);
        put_packed_f16x2(bytes, base + 16, 0.0f, 0.0f);
        put_packed_f16x2(bytes, base + 20, cube_scale, z);
        double next_sin = wave_sin * cos_step + wave_cos * sin_step;
        wave_cos = wave_cos * cos_step - wave_sin * sin_step;
        wave_sin = next_sin;
        local_index++;
        x = (float)((double)x + grid_spacing);
      }
      row++;
    }
    return;
  }
  if (!full_rows) {
    double wave_sin = sin(wave_time);
    double wave_cos = cos(wave_time);
    for (int32_t i = 0; i < entity_count; i++) {
      put_f32_word(bytes, i * words_per_entity + 7, (float)(wave_sin * 0.12));
      double next_sin = wave_sin * cos_step + wave_cos * sin_step;
      wave_cos = wave_cos * cos_step - wave_sin * sin_step;
      wave_sin = next_sin;
    }
    return;
  }
  double half = ((double)per_side - 1.0) * 0.5;
  int32_t local_index = 0;
  int32_t row = 0;
  while (local_index < entity_count) {
    int32_t remaining = entity_count - local_index;
    int32_t row_count = per_side < remaining ? per_side : remaining;
    float x = (float)(-half * grid_spacing);
    float z = (float)(((double)row - half) * grid_spacing);
    double wave_sin = sin((double)local_index * 0.09 + wave_time);
    double wave_cos = cos((double)local_index * 0.09 + wave_time);
    for (int32_t ix = 0; ix < row_count; ix++) {
      int32_t base = local_index * words_per_entity;
      float y = (float)(wave_sin * 0.12);
      put_f32_word(bytes, base + 0, cube_scale);
      put_u32_le(bytes, (base + 1) * 4, 0);
      put_u32_le(bytes, (base + 2) * 4, 0);
      put_f32_word(bytes, base + 3, x);
      put_u32_le(bytes, (base + 4) * 4, 0);
      put_f32_word(bytes, base + 5, cube_scale);
      put_u32_le(bytes, (base + 6) * 4, 0);
      put_f32_word(bytes, base + 7, y);
      put_u32_le(bytes, (base + 8) * 4, 0);
      put_u32_le(bytes, (base + 9) * 4, 0);
      put_f32_word(bytes, base + 10, cube_scale);
      put_f32_word(bytes, base + 11, z);
      double next_sin = wave_sin * cos_step + wave_cos * sin_step;
      wave_cos = wave_cos * cos_step - wave_sin * sin_step;
      wave_sin = next_sin;
      local_index++;
      x = (float)((double)x + grid_spacing);
    }
    row++;
  }
}

void rhodonite_mass_cubes_write_transform_blob_refs(
  RhodoniteArrayViewU8 view,
  moonbit_bytes_t refs,
  int32_t upload_first_word,
  int32_t entity_count,
  int32_t per_side,
  double t,
  int32_t full_rows,
  float cube_scale,
  double grid_spacing
) {
  uint8_t* bytes = view.bytes + view.start;
  double wave_time = t * 1.8;
  double sin_step = sin(0.09);
  double cos_step = cos(0.09);
  if (!full_rows) {
    double wave_sin = sin(wave_time);
    double wave_cos = cos(wave_time);
    for (int32_t i = 0; i < entity_count; i++) {
      int32_t ref_base = i * 8;
      uint32_t format_code = get_u32_le(refs, ref_base);
      int32_t word_offset =
        (int32_t)get_u32_le(refs, ref_base + 4) - upload_first_word;
      float y = (float)(wave_sin * 0.12);
      if (format_code == 1u) {
        put_packed_f16x2(bytes, (word_offset + 3) * 4, 0.0f, y);
      } else {
        put_f32_word(bytes, word_offset + 7, y);
      }
      double next_sin = wave_sin * cos_step + wave_cos * sin_step;
      wave_cos = wave_cos * cos_step - wave_sin * sin_step;
      wave_sin = next_sin;
    }
    return;
  }
  double half = ((double)per_side - 1.0) * 0.5;
  int32_t local_index = 0;
  int32_t row = 0;
  while (local_index < entity_count) {
    int32_t remaining = entity_count - local_index;
    int32_t row_count = per_side < remaining ? per_side : remaining;
    float x = (float)(-half * grid_spacing);
    float z = (float)(((double)row - half) * grid_spacing);
    double wave_sin = sin((double)local_index * 0.09 + wave_time);
    double wave_cos = cos((double)local_index * 0.09 + wave_time);
    for (int32_t ix = 0; ix < row_count; ix++) {
      int32_t ref_base = local_index * 8;
      uint32_t format_code = get_u32_le(refs, ref_base);
      int32_t word_offset =
        (int32_t)get_u32_le(refs, ref_base + 4) - upload_first_word;
      float y = (float)(wave_sin * 0.12);
      if (format_code == 1u) {
        int32_t base = word_offset * 4;
        put_packed_f16x2(bytes, base + 0, cube_scale, 0.0f);
        put_packed_f16x2(bytes, base + 4, 0.0f, x);
        put_packed_f16x2(bytes, base + 8, 0.0f, cube_scale);
        put_packed_f16x2(bytes, base + 12, 0.0f, y);
        put_packed_f16x2(bytes, base + 16, 0.0f, 0.0f);
        put_packed_f16x2(bytes, base + 20, cube_scale, z);
      } else {
        put_f32_word(bytes, word_offset + 0, cube_scale);
        put_u32_le(bytes, (word_offset + 1) * 4, 0);
        put_u32_le(bytes, (word_offset + 2) * 4, 0);
        put_f32_word(bytes, word_offset + 3, x);
        put_u32_le(bytes, (word_offset + 4) * 4, 0);
        put_f32_word(bytes, word_offset + 5, cube_scale);
        put_u32_le(bytes, (word_offset + 6) * 4, 0);
        put_f32_word(bytes, word_offset + 7, y);
        put_u32_le(bytes, (word_offset + 8) * 4, 0);
        put_u32_le(bytes, (word_offset + 9) * 4, 0);
        put_f32_word(bytes, word_offset + 10, cube_scale);
        put_f32_word(bytes, word_offset + 11, z);
      }
      double next_sin = wave_sin * cos_step + wave_cos * sin_step;
      wave_cos = wave_cos * cos_step - wave_sin * sin_step;
      wave_sin = next_sin;
      local_index++;
      x = (float)((double)x + grid_spacing);
    }
    row++;
  }
}
