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
#borrow(window)
extern "C" fn rhodonite_sdl_prepare_shown_window(
  window : @lib.SDL_Window,
) -> Unit = "rhodonite_sdl_prepare_shown_window"

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
