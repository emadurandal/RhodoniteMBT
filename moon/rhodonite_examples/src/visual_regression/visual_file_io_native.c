#include <errno.h>
#include <limits.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>

#include "moonbit.h"

static char *rhodonite_visual_string_to_c(moonbit_string_t s) {
  int32_t len = Moonbit_array_length(s);
  char *out = (char *)malloc((size_t)len + 1u);
  if (!out) {
    return NULL;
  }
  for (int32_t i = 0; i < len; i++) {
    out[i] = (char)(s[i] & 0xffu);
  }
  out[len] = '\0';
  return out;
}

static void rhodonite_visual_mkdir_p_for_file(const char *path) {
  char *copy = strdup(path);
  if (!copy) {
    return;
  }
  for (char *p = copy + 1; *p != '\0'; p++) {
    if (*p == '/') {
      *p = '\0';
      (void)mkdir(copy, 0777);
      *p = '/';
    }
  }
  free(copy);
}

moonbit_bytes_t rhodonite_visual_read_binary_file(moonbit_string_t path_s) {
  char *path = rhodonite_visual_string_to_c(path_s);
  if (!path) {
    return moonbit_make_bytes(0, 0);
  }
  FILE *f = fopen(path, "rb");
  free(path);
  if (!f) {
    return moonbit_make_bytes(0, 0);
  }
  if (fseek(f, 0, SEEK_END) != 0) {
    fclose(f);
    return moonbit_make_bytes(0, 0);
  }
  long len_l = ftell(f);
  if (len_l < 0 || len_l > INT32_MAX) {
    fclose(f);
    return moonbit_make_bytes(0, 0);
  }
  rewind(f);
  int32_t len = (int32_t)len_l;
  moonbit_bytes_t out = moonbit_make_bytes_raw(len);
  size_t read = fread(out, 1u, (size_t)len, f);
  fclose(f);
  if (read != (size_t)len) {
    return moonbit_make_bytes(0, 0);
  }
  return out;
}

void rhodonite_visual_write_binary_file(
  moonbit_string_t path_s,
  moonbit_bytes_t data
) {
  char *path = rhodonite_visual_string_to_c(path_s);
  if (!path) {
    return;
  }
  rhodonite_visual_mkdir_p_for_file(path);
  FILE *f = fopen(path, "wb");
  if (!f) {
    free(path);
    return;
  }
  int32_t len = Moonbit_array_length(data);
  (void)fwrite(data, 1u, (size_t)len, f);
  fclose(f);
  free(path);
}

bool rhodonite_visual_snapshot_update_enabled(void) {
  char const *value = getenv("RHODONITE_UPDATE_VISUAL_SNAPSHOTS");
  return value != NULL && value[0] != '\0';
}
