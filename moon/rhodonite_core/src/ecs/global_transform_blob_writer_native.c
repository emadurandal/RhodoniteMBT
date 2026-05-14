#include <stdint.h>
#include <string.h>

#include "moonbit.h"

typedef struct RhodoniteMutArrayViewU8 {
  int32_t start;
  int32_t end;
  moonbit_bytes_t bytes;
} RhodoniteMutArrayViewU8;

static uint32_t rhodonite_get_u32_le(uint8_t const* p) {
  return ((uint32_t)p[0]) |
         ((uint32_t)p[1] << 8) |
         ((uint32_t)p[2] << 16) |
         ((uint32_t)p[3] << 24);
}

static void rhodonite_put_u32_le(uint8_t* p, uint32_t value) {
  p[0] = (uint8_t)value;
  p[1] = (uint8_t)(value >> 8);
  p[2] = (uint8_t)(value >> 16);
  p[3] = (uint8_t)(value >> 24);
}

static uint32_t rhodonite_f32_bits(float value) {
  uint32_t bits;
  memcpy(&bits, &value, sizeof(bits));
  return bits;
}

static uint32_t rhodonite_f32_to_f16_bits(float value) {
  uint32_t bits = rhodonite_f32_bits(value);
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

void rhodonite_global_transform_element_setter_set_dense_f32(
  RhodoniteMutArrayViewU8 bytes,
  int32_t index,
  float value,
  int32_t first_word,
  int32_t words_per_entity,
  int32_t scalar_index
) {
  uint8_t* out = bytes.bytes + bytes.start;
  int32_t word_offset = index * words_per_entity + scalar_index - first_word;
  rhodonite_put_u32_le(out + (word_offset * 4), rhodonite_f32_bits(value));
}

void rhodonite_global_transform_element_setter_set_dense_f16(
  RhodoniteMutArrayViewU8 bytes,
  int32_t index,
  float value,
  int32_t first_word,
  int32_t words_per_entity,
  int32_t scalar_index
) {
  uint8_t* out = bytes.bytes + bytes.start;
  int32_t word_offset = index * words_per_entity +
                        (scalar_index >> 1) -
                        first_word;
  uint8_t* word = out + (word_offset * 4);
  uint32_t old = rhodonite_get_u32_le(word);
  uint32_t half = rhodonite_f32_to_f16_bits(value);
  uint32_t next = (scalar_index & 1) == 0
    ? ((old & 0xffff0000u) | half)
    : ((old & 0x0000ffffu) | (half << 16));
  rhodonite_put_u32_le(word, next);
}

void rhodonite_global_transform_element_setter_set_mixed(
  RhodoniteMutArrayViewU8 bytes,
  moonbit_bytes_t refs,
  int32_t index,
  float value,
  int32_t first_word,
  int32_t scalar_index
) {
  uint8_t* out = bytes.bytes + bytes.start;
  int32_t ref_base = index * 8;
  uint8_t const* ref = refs + ref_base;
  int32_t format = (int32_t)rhodonite_get_u32_le(ref);
  int32_t word_offset = (int32_t)rhodonite_get_u32_le(ref + 4) - first_word;

  if (format == 1) {
    uint8_t* word = out + ((word_offset + (scalar_index >> 1)) * 4);
    uint32_t old = rhodonite_get_u32_le(word);
    uint32_t half = rhodonite_f32_to_f16_bits(value);
    uint32_t next = (scalar_index & 1) == 0
      ? ((old & 0xffff0000u) | half)
      : ((old & 0x0000ffffu) | (half << 16));
    rhodonite_put_u32_le(word, next);
  } else {
    rhodonite_put_u32_le(
      out + ((word_offset + scalar_index) * 4),
      rhodonite_f32_bits(value)
    );
  }
}
