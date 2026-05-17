#include <stdint.h>
#include <string.h>

static uint32_t rhodonite_f32_bits(float value) {
  uint32_t bits;
  memcpy(&bits, &value, sizeof(bits));
  return bits;
}

uint32_t rhodonite_global_transform_f32_to_f16_bits(float value) {
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
