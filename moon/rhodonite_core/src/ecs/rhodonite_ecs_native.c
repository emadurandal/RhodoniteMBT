#include <math.h>
#include <stdint.h>

#include "moonbit.h"

void rhodonite_ecs_write_global_transforms_dense_grid_wave_f32(
  moonbit_bytes_t data,
  int32_t count,
  int32_t per_side,
  double time,
  double scale,
  double spacing
) {
  float s = (float)scale;
  double half = ((double)per_side - 1.0) * 0.5;
  for (int32_t i = 0; i < count; i++) {
    int32_t ix = i % per_side;
    int32_t iz = i / per_side;
    float* out = (float*)(data + ((int64_t)i * 64));
    out[0] = s;
    out[1] = 0.0f;
    out[2] = 0.0f;
    out[3] = 0.0f;
    out[4] = 0.0f;
    out[5] = s;
    out[6] = 0.0f;
    out[7] = 0.0f;
    out[8] = 0.0f;
    out[9] = 0.0f;
    out[10] = s;
    out[11] = 0.0f;
    out[12] = (float)(((double)ix - half) * spacing);
    out[13] = (float)(sin((double)i * 0.09 + time) * 0.12);
    out[14] = (float)(((double)iz - half) * spacing);
    out[15] = 1.0f;
  }
}
