/*
 * SDL3 window property helpers for native Wayland/X11 surface creation.
 */

#include <SDL3/SDL.h>
#include <stdio.h>

void rhodonite_sdl_log_stderr(const char *message);

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

void rhodonite_sdl_log_video_driver(void) {
  const char *driver = SDL_GetCurrentVideoDriver();
  if (driver != NULL && driver[0] != '\0') {
    fprintf(stderr, "SDL video driver: %s\n", driver);
    fflush(stderr);
  } else {
    rhodonite_sdl_log_stderr("SDL video driver: (none)");
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
  return SDL_CreateWindowWithProperties(props);
}

void rhodonite_sdl_pump_events_rounds(int rounds) {
  for (int i = 0; i < rounds; ++i) {
    SDL_PumpEvents();
  }
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
  for (int i = 0; i < 64; ++i) {
    SDL_PumpEvents();
    SDL_Delay(1);
  }
}

void rhodonite_sdl_sync_window_after_external_present(SDL_Window *window) {
  if (window == NULL) {
    return;
  }
  SDL_SyncWindow(window);
  SDL_PumpEvents();
}

void rhodonite_sdl_log_window_state(SDL_Window *window) {
  if (window == NULL) {
    rhodonite_sdl_log_stderr("SDL window state: null window");
    return;
  }
  const Uint32 flags = SDL_GetWindowFlags(window);
  int w = 0;
  int h = 0;
  int pw = 0;
  int ph = 0;
  SDL_GetWindowSize(window, &w, &h);
  SDL_GetWindowSizeInPixels(window, &pw, &ph);
  fprintf(stderr,
          "SDL window state: flags=0x%08x logical=%dx%d pixels=%dx%d hidden=%d "
          "minimized=%d\n",
          flags, w, h, pw, ph, (flags & SDL_WINDOW_HIDDEN) ? 1 : 0,
          (flags & SDL_WINDOW_MINIMIZED) ? 1 : 0);
  fflush(stderr);
}

void rhodonite_sdl_log_stderr(const char *message) {
  if (message != NULL) {
    fputs(message, stderr);
    fputc('\n', stderr);
    fflush(stderr);
  }
}
