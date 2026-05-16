#include <moonbit.h>
#include <stdint.h>
#include <string.h>

extern const char *SDL_GetScancodeName(uint32_t scancode);
extern const char *SDL_GetKeyName(uint32_t key);

static moonbit_string_t rhodonite_moonbit_string_from_borrowed_cstr(
  const char *src
) {
  if (src == NULL) {
    src = "";
  }
  int32_t len = (int32_t)strlen(src);
  moonbit_string_t out = moonbit_make_string(len, 0);
  for (int32_t i = 0; i < len; i++) {
    out[i] = (uint16_t)(unsigned char)src[i];
  }
  return out;
}

moonbit_string_t rhodonite_sdl_get_scancode_name_borrowed(
  uint32_t scancode
) {
  return rhodonite_moonbit_string_from_borrowed_cstr(
    SDL_GetScancodeName(scancode)
  );
}

moonbit_string_t rhodonite_sdl_get_key_name_borrowed(uint32_t key) {
  return rhodonite_moonbit_string_from_borrowed_cstr(SDL_GetKeyName(key));
}
