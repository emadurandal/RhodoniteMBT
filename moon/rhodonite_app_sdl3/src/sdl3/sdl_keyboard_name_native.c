#include <moonbit.h>
#include <stdint.h>
#include <string.h>

extern const char *SDL_GetScancodeName(uint32_t scancode);
extern const char *SDL_GetKeyName(uint32_t key);

static const char *rhodonite_sdl_browser_code_from_scancode_value(
  uint32_t scancode
) {
  switch (scancode) {
  case 4: return "KeyA";
  case 5: return "KeyB";
  case 6: return "KeyC";
  case 7: return "KeyD";
  case 8: return "KeyE";
  case 9: return "KeyF";
  case 10: return "KeyG";
  case 11: return "KeyH";
  case 12: return "KeyI";
  case 13: return "KeyJ";
  case 14: return "KeyK";
  case 15: return "KeyL";
  case 16: return "KeyM";
  case 17: return "KeyN";
  case 18: return "KeyO";
  case 19: return "KeyP";
  case 20: return "KeyQ";
  case 21: return "KeyR";
  case 22: return "KeyS";
  case 23: return "KeyT";
  case 24: return "KeyU";
  case 25: return "KeyV";
  case 26: return "KeyW";
  case 27: return "KeyX";
  case 28: return "KeyY";
  case 29: return "KeyZ";
  case 30: return "Digit1";
  case 31: return "Digit2";
  case 32: return "Digit3";
  case 33: return "Digit4";
  case 34: return "Digit5";
  case 35: return "Digit6";
  case 36: return "Digit7";
  case 37: return "Digit8";
  case 38: return "Digit9";
  case 39: return "Digit0";
  case 40: return "Enter";
  case 41: return "Escape";
  case 42: return "Backspace";
  case 43: return "Tab";
  case 44: return "Space";
  case 45: return "Minus";
  case 46: return "Equal";
  case 47: return "BracketLeft";
  case 48: return "BracketRight";
  case 49: return "Backslash";
  case 51: return "Semicolon";
  case 52: return "Quote";
  case 53: return "Backquote";
  case 54: return "Comma";
  case 55: return "Period";
  case 56: return "Slash";
  case 57: return "CapsLock";
  case 58: return "F1";
  case 59: return "F2";
  case 60: return "F3";
  case 61: return "F4";
  case 62: return "F5";
  case 63: return "F6";
  case 64: return "F7";
  case 65: return "F8";
  case 66: return "F9";
  case 67: return "F10";
  case 68: return "F11";
  case 69: return "F12";
  case 70: return "PrintScreen";
  case 71: return "ScrollLock";
  case 72: return "Pause";
  case 73: return "Insert";
  case 74: return "Home";
  case 75: return "PageUp";
  case 76: return "Delete";
  case 77: return "End";
  case 78: return "PageDown";
  case 79: return "ArrowRight";
  case 80: return "ArrowLeft";
  case 81: return "ArrowDown";
  case 82: return "ArrowUp";
  case 83: return "NumLock";
  case 84: return "NumpadDivide";
  case 85: return "NumpadMultiply";
  case 86: return "NumpadSubtract";
  case 87: return "NumpadAdd";
  case 88: return "NumpadEnter";
  case 89: return "Numpad1";
  case 90: return "Numpad2";
  case 91: return "Numpad3";
  case 92: return "Numpad4";
  case 93: return "Numpad5";
  case 94: return "Numpad6";
  case 95: return "Numpad7";
  case 96: return "Numpad8";
  case 97: return "Numpad9";
  case 98: return "Numpad0";
  case 99: return "NumpadDecimal";
  case 100: return "IntlBackslash";
  case 104: return "F13";
  case 105: return "F14";
  case 106: return "F15";
  case 107: return "F16";
  case 108: return "F17";
  case 109: return "F18";
  case 110: return "F19";
  case 111: return "F20";
  case 112: return "F21";
  case 113: return "F22";
  case 114: return "F23";
  case 115: return "F24";
  case 224: return "ControlLeft";
  case 225: return "ShiftLeft";
  case 226: return "AltLeft";
  case 227: return "MetaLeft";
  case 228: return "ControlRight";
  case 229: return "ShiftRight";
  case 230: return "AltRight";
  case 231: return "MetaRight";
  default: return "";
  }
}

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

moonbit_string_t rhodonite_sdl_browser_key_code_from_scancode(
  uint32_t scancode
) {
  return rhodonite_moonbit_string_from_borrowed_cstr(
    rhodonite_sdl_browser_code_from_scancode_value(scancode)
  );
}
