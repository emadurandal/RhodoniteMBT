/*
 * SDL3 window property helpers for native Wayland/X11 surface creation.
 */

#include <stddef.h>
#include <stdint.h>

#if defined(__linux__)

#include <SDL3/SDL.h>

void rhodonite_sdl_preinit_linux_video(void) {
  const char *driver = SDL_getenv("SDL_VIDEODRIVER");
  if (driver != NULL && driver[0] != '\0') {
    SDL_SetHint(SDL_HINT_VIDEO_DRIVER, driver);
    return;
  }
  /* Prefer native Wayland (Ubuntu 24.04+ default). Use SDL_VIDEODRIVER=x11 for X11-only. */
  if (SDL_getenv("WAYLAND_DISPLAY") != NULL) {
    SDL_SetHint(SDL_HINT_VIDEO_DRIVER, "wayland");
    return;
  }
  if (SDL_getenv("DISPLAY") != NULL) {
    SDL_SetHint(SDL_HINT_VIDEO_DRIVER, "x11");
  }
}

void *rhodonite_sdl_get_window_pointer_property(SDL_Window *window,
                                                const char *name) {
  SDL_PropertiesID props = SDL_GetWindowProperties(window);
  if (props == 0) {
    return NULL;
  }
  return SDL_GetPointerProperty(props, name, NULL);
}

Sint64 rhodonite_sdl_get_window_number_property(SDL_Window *window,
                                                const char *name) {
  SDL_PropertiesID props = SDL_GetWindowProperties(window);
  if (props == 0) {
    return 0;
  }
  return SDL_GetNumberProperty(props, name, 0);
}

void *rhodonite_sdl_get_window_wayland_display(SDL_Window *window) {
  return rhodonite_sdl_get_window_pointer_property(
      window, SDL_PROP_WINDOW_WAYLAND_DISPLAY_POINTER);
}

void *rhodonite_sdl_get_window_wayland_surface(SDL_Window *window) {
  return rhodonite_sdl_get_window_pointer_property(
      window, SDL_PROP_WINDOW_WAYLAND_SURFACE_POINTER);
}

void *rhodonite_sdl_get_window_x11_display(SDL_Window *window) {
  return rhodonite_sdl_get_window_pointer_property(
      window, SDL_PROP_WINDOW_X11_DISPLAY_POINTER);
}

Sint64 rhodonite_sdl_get_window_x11_window(SDL_Window *window) {
  return rhodonite_sdl_get_window_number_property(
      window, SDL_PROP_WINDOW_X11_WINDOW_NUMBER);
}

SDL_Window *rhodonite_sdl_create_linux_wgpu_window(const char *title, int width,
                                                   int height) {
  SDL_PropertiesID props = SDL_CreateProperties();
  if (props == 0) {
    return NULL;
  }
  SDL_SetStringProperty(props, SDL_PROP_WINDOW_CREATE_TITLE_STRING, title);
  SDL_SetNumberProperty(props, SDL_PROP_WINDOW_CREATE_WIDTH_NUMBER, width);
  SDL_SetNumberProperty(props, SDL_PROP_WINDOW_CREATE_HEIGHT_NUMBER, height);
  SDL_SetBooleanProperty(props, SDL_PROP_WINDOW_CREATE_RESIZABLE_BOOLEAN, true);
  SDL_SetBooleanProperty(
      props, SDL_PROP_WINDOW_CREATE_EXTERNAL_GRAPHICS_CONTEXT_BOOLEAN, true);
  SDL_Window *window = SDL_CreateWindowWithProperties(props);
  SDL_DestroyProperties(props);
  return window;
}

void rhodonite_sdl_prepare_shown_window(SDL_Window *window) {
  if (window == NULL) {
    return;
  }
  SDL_SetWindowPosition(window, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED);
  SDL_ShowWindow(window);
  SDL_RaiseWindow(window);
  SDL_SetWindowFocusable(window, true);
  SDL_SyncWindow(window);
}

#else

void rhodonite_sdl_preinit_linux_video(void) {}

void *rhodonite_sdl_get_window_wayland_display(void *window) {
  (void)window;
  return NULL;
}

void *rhodonite_sdl_get_window_wayland_surface(void *window) {
  (void)window;
  return NULL;
}

void *rhodonite_sdl_get_window_x11_display(void *window) {
  (void)window;
  return NULL;
}

int64_t rhodonite_sdl_get_window_x11_window(void *window) {
  (void)window;
  return 0;
}

void *rhodonite_sdl_create_linux_wgpu_window(const char *title, int width,
                                             int height) {
  (void)title;
  (void)width;
  (void)height;
  return NULL;
}

void rhodonite_sdl_prepare_shown_window(void *window) { (void)window; }

#endif
