#include <stdint.h>

#include "moonbit.h"

typedef struct RhodoniteMutArrayViewU8 {
  int32_t start;
  int32_t end;
  moonbit_bytes_t bytes;
} RhodoniteMutArrayViewU8;

void rhodonite_binary_put_u16_le_mut_view(
  RhodoniteMutArrayViewU8 buf,
  int32_t off,
  uint32_t value
) {
  uint8_t* out = buf.bytes + buf.start + off;
  out[0] = (uint8_t)value;
  out[1] = (uint8_t)(value >> 8);
}

void rhodonite_binary_put_u32_le_mut_view(
  RhodoniteMutArrayViewU8 buf,
  int32_t off,
  uint32_t value
) {
  uint8_t* out = buf.bytes + buf.start + off;
  out[0] = (uint8_t)value;
  out[1] = (uint8_t)(value >> 8);
  out[2] = (uint8_t)(value >> 16);
  out[3] = (uint8_t)(value >> 24);
}
