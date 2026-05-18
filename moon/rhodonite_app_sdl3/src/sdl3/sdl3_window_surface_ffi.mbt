///| SDL3 window properties for native Wayland and X11 Vulkan surfaces.

///|
fn string_to_cbytes(str : String) -> Bytes {
  let s = @utf8.encode(str).to_array().filter(fn(c) { c != 0 })
  s.push(0)
  Bytes::from_array(s)
}

///|
/// Applies Linux video driver hints before `SDL_Init`.
extern "C" fn rhodonite_sdl_preinit_linux_video() -> Unit = "rhodonite_sdl_preinit_linux_video"

///|
/// Applies Linux video driver hints before `SDL_Init`.
pub fn preinit_linux_sdl_video() -> Unit {
  rhodonite_sdl_preinit_linux_video()
}

///|
extern "C" fn rhodonite_sdl_log_video_driver() -> Unit = "rhodonite_sdl_log_video_driver"

///|
/// Logs the active SDL video driver (wayland, x11, etc.) to stderr.
pub fn log_sdl_video_driver() -> Unit {
  rhodonite_sdl_log_video_driver()
}

///|
/// Creates an SDL window configured for external Vulkan presentation on Linux.
pub fn create_linux_wgpu_sdl_window(
  title : String,
  width : Int,
  height : Int,
) -> @lib.SDL_Window {
  rhodonite_sdl_create_linux_wgpu_window(string_to_cbytes(title), width, height)
}

///|
#borrow(title)
extern "C" fn rhodonite_sdl_create_linux_wgpu_window(
  title : Bytes,
  width : Int,
  height : Int,
) -> @lib.SDL_Window = "rhodonite_sdl_create_linux_wgpu_window"

///|
extern "C" fn rhodonite_sdl_pump_events_rounds(rounds : Int) -> Unit = "rhodonite_sdl_pump_events_rounds"

///|
#borrow(window)
extern "C" fn rhodonite_sdl_prepare_shown_window(
  window : @lib.SDL_Window,
) -> Unit = "rhodonite_sdl_prepare_shown_window"

///|
#borrow(window)
extern "C" fn rhodonite_sdl_sync_window_after_external_present(
  window : @lib.SDL_Window,
) -> Unit = "rhodonite_sdl_sync_window_after_external_present"

///|
#borrow(window)
extern "C" fn rhodonite_sdl_log_window_state(window : @lib.SDL_Window) -> Unit = "rhodonite_sdl_log_window_state"

///|
#borrow(message)
extern "C" fn rhodonite_sdl_log_stderr(message : Bytes) -> Unit = "rhodonite_sdl_log_stderr"

///|
fn sdl_log_stderr(message : String) -> Unit {
  rhodonite_sdl_log_stderr(string_to_cbytes(message))
}

///|
/// Native windowing backend used to create a wgpu surface on Linux.
pub(all) enum NativeWindowSurfaceKind {
  Wayland
  Xlib
} derive(Eq)

///|
/// Wayland handles (`wl_display*`, `wl_surface*`) read from an SDL window.
pub struct WaylandWindowSurface {
  display : @wgpu_objects.OpaquePtr
  surface : @wgpu_objects.OpaquePtr
}

///|
/// Xlib handles (`Display*`, `Window`) read from an SDL window.
pub struct XlibWindowSurface {
  display : @wgpu_objects.OpaquePtr
  window : UInt64
}

///|
extern "C" fn rhodonite_sdl_get_window_wayland_display(
  window : @lib.SDL_Window,
) -> @wgpu_objects.OpaquePtr = "rhodonite_sdl_get_window_wayland_display"

///|
extern "C" fn rhodonite_sdl_get_window_wayland_surface(
  window : @lib.SDL_Window,
) -> @wgpu_objects.OpaquePtr = "rhodonite_sdl_get_window_wayland_surface"

///|
extern "C" fn rhodonite_sdl_get_window_x11_display(
  window : @lib.SDL_Window,
) -> @wgpu_objects.OpaquePtr = "rhodonite_sdl_get_window_x11_display"

///|
extern "C" fn rhodonite_sdl_get_window_x11_window(
  window : @lib.SDL_Window,
) -> Int64 = "rhodonite_sdl_get_window_x11_window"

///|
/// Returns Wayland handles when the SDL window is backed by Wayland.
pub fn query_wayland_window_surface(
  window : @lib.SDL_Window,
) -> WaylandWindowSurface? {
  let display = rhodonite_sdl_get_window_wayland_display(window)
  let surface = rhodonite_sdl_get_window_wayland_surface(window)
  if @wgpu_objects.opaque_ptr_is_null(display) ||
    @wgpu_objects.opaque_ptr_is_null(surface) {
    None
  } else {
    Some(WaylandWindowSurface::{ display, surface })
  }
}

///|
/// Returns Xlib handles when the SDL window is backed by X11.
pub fn query_xlib_window_surface(
  window : @lib.SDL_Window,
) -> XlibWindowSurface? {
  let display = rhodonite_sdl_get_window_x11_display(window)
  let window_id = rhodonite_sdl_get_window_x11_window(window)
  if @wgpu_objects.opaque_ptr_is_null(display) || window_id == 0L {
    None
  } else {
    Some(XlibWindowSurface::{
      display,
      window: window_id.reinterpret_as_uint64(),
    })
  }
}

///|
/// Detects whether the SDL window exposes Wayland or X11 handles for wgpu.
pub fn query_native_window_surface_kind(
  window : @lib.SDL_Window,
) -> (NativeWindowSurfaceKind, WaylandWindowSurface?, XlibWindowSurface?) {
  match query_wayland_window_surface(window) {
    Some(wayland) => (NativeWindowSurfaceKind::Wayland, Some(wayland), None)
    None =>
      match query_xlib_window_surface(window) {
        Some(xlib) => (NativeWindowSurfaceKind::Xlib, None, Some(xlib))
        None => (NativeWindowSurfaceKind::Wayland, None, None)
      }
  }
}

///|
/// Pumps SDL events so Wayland/X11 can map a newly shown window.
pub fn pump_sdl_events_for_compositor(rounds : Int) -> Unit {
  rhodonite_sdl_pump_events_rounds(rounds)
}

///|
/// Commits external GPU presentation to the host windowing system (Wayland/X11).
pub fn sync_sdl_window_after_external_present(window : @lib.SDL_Window) -> Unit {
  rhodonite_sdl_sync_window_after_external_present(window)
}

///|
/// Logs SDL window visibility and size to stderr for native startup diagnostics.
pub fn log_sdl_window_state(window : @lib.SDL_Window) -> Unit {
  rhodonite_sdl_log_window_state(window)
}
