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
  if (count <= 0 || per_side <= 0) {
    return;
  }

  float s = (float)scale;
  double half = ((double)per_side - 1.0) * 0.5;
  double x0 = -half * spacing;
  double sin_step = sin(0.09);
  double cos_step = cos(0.09);

  int32_t i = 0;
  int32_t iz = 0;
  while (i < count) {
    int32_t row_count = count - i;
    if (row_count > per_side) {
      row_count = per_side;
    }

    double x = x0;
    float z = (float)(((double)iz - half) * spacing);
    double wave_s = sin((double)i * 0.09 + time);
    double wave_c = cos((double)i * 0.09 + time);

    for (int32_t ix = 0; ix < row_count; ix++) {
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
      out[12] = (float)x;
      out[13] = (float)(wave_s * 0.12);
      out[14] = z;
      out[15] = 1.0f;

      double next_s = wave_s * cos_step + wave_c * sin_step;
      wave_c = wave_c * cos_step - wave_s * sin_step;
      wave_s = next_s;
      x += spacing;
      i++;
    }
    iz++;
  }
}

void rhodonite_ecs_write_global_transforms_dense_grid_wave_y_f32(
  moonbit_bytes_t data,
  int32_t count,
  int32_t per_side,
  double time
) {
  if (count <= 0 || per_side <= 0) {
    return;
  }

  double sin_step = sin(0.09);
  double cos_step = cos(0.09);
  int32_t i = 0;
  while (i < count) {
    int32_t row_count = count - i;
    if (row_count > per_side) {
      row_count = per_side;
    }

    double wave_s = sin((double)i * 0.09 + time);
    double wave_c = cos((double)i * 0.09 + time);
    for (int32_t ix = 0; ix < row_count; ix++) {
      float* out = (float*)(data + ((int64_t)i * 64));
      out[13] = (float)(wave_s * 0.12);

      double next_s = wave_s * cos_step + wave_c * sin_step;
      wave_c = wave_c * cos_step - wave_s * sin_step;
      wave_s = next_s;
      i++;
    }
  }
}
