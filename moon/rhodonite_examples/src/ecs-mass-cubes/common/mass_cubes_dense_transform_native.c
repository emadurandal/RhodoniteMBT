#include <math.h>
#include <stdint.h>
#include <string.h>

#include "moonbit.h"

typedef struct RhodoniteMutArrayViewU8 {
  int32_t start;
  int32_t end;
  moonbit_bytes_t bytes;
} RhodoniteMutArrayViewU8;

static uint32_t rhodonite_mass_cubes_get_u32_le(uint8_t const* p) {
  return ((uint32_t)p[0]) |
         ((uint32_t)p[1] << 8) |
         ((uint32_t)p[2] << 16) |
         ((uint32_t)p[3] << 24);
}

static void rhodonite_mass_cubes_put_u32_le(uint8_t* p, uint32_t value) {
  p[0] = (uint8_t)value;
  p[1] = (uint8_t)(value >> 8);
  p[2] = (uint8_t)(value >> 16);
  p[3] = (uint8_t)(value >> 24);
}

static uint32_t rhodonite_mass_cubes_f32_bits(float value) {
  uint32_t bits;
  memcpy(&bits, &value, sizeof(bits));
  return bits;
}

static uint32_t rhodonite_mass_cubes_f32_to_f16_bits(float value) {
  uint32_t bits = rhodonite_mass_cubes_f32_bits(value);
  uint32_t sign = (bits >> 16) & 0x8000u;
  uint32_t mant = bits & 0x007fffffu;
  int32_t exp = (int32_t)((bits >> 23) & 0xffu);

  if (exp == 255) {
    return mant == 0 ? sign | 0x7c00u : sign | 0x7e00u;
  }

  int32_t half_exp = exp - 127 + 15;
  if (half_exp >= 31) {
    return sign | 0x7c00u;
  }

  if (half_exp <= 0) {
    if (half_exp < -10) {
      return sign;
    }
    uint32_t mantissa = mant | 0x00800000u;
    int32_t shift = 14 - half_exp;
    uint32_t half_mant = mantissa >> shift;
    if (((mantissa >> (shift - 1)) & 1u) != 0u) {
      half_mant += 1u;
    }
    return sign | half_mant;
  }

  uint32_t half = sign | ((uint32_t)half_exp << 10) | (mant >> 13);
  if (((mant >> 12) & 1u) != 0u) {
    half += 1u;
  }
  return half;
}

void rhodonite_mass_cubes_write_dense_y_transform_wave(
  RhodoniteMutArrayViewU8 bytes,
  int32_t count,
  int32_t first_word,
  int32_t words_per_entity,
  int32_t format_code,
  double wave_time
) {
  uint8_t* out = bytes.bytes + bytes.start;
  double sin_step = sin(0.09);
  double cos_step = cos(0.09);
  double wave_sin = sin(wave_time);
  double wave_cos = cos(wave_time);

  if (format_code == 1) {
    int32_t base_word = 3 - first_word;
    for (int32_t i = 0; i < count; i++) {
      int32_t word_offset = i * words_per_entity + base_word;
      uint8_t* word = out + word_offset * 4;
      uint32_t old = rhodonite_mass_cubes_get_u32_le(word);
      uint32_t half = rhodonite_mass_cubes_f32_to_f16_bits(
        (float)(wave_sin * 0.12)
      );
      rhodonite_mass_cubes_put_u32_le(
        word,
        (old & 0x0000ffffu) | (half << 16)
      );
      double next_sin = wave_sin * cos_step + wave_cos * sin_step;
      wave_cos = wave_cos * cos_step - wave_sin * sin_step;
      wave_sin = next_sin;
    }
    return;
  }

  int32_t base_word = 7 - first_word;
  for (int32_t i = 0; i < count; i++) {
    int32_t word_offset = i * words_per_entity + base_word;
    rhodonite_mass_cubes_put_u32_le(
      out + word_offset * 4,
      rhodonite_mass_cubes_f32_bits((float)(wave_sin * 0.12))
    );
    double next_sin = wave_sin * cos_step + wave_cos * sin_step;
    wave_cos = wave_cos * cos_step - wave_sin * sin_step;
    wave_sin = next_sin;
  }
}
