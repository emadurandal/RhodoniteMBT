///| [SDL3 SDL_metal.h](https://github.com/libsdl-org/SDL/blob/main/include/SDL3/SDL_metal.h) minimal FFI.

///|
/// Creates an SDL Metal view for a native SDL window.
extern "C" fn sdl_metal_create_view(w : @lib.SDL_Window) -> @c.OpaquePtr = "SDL_Metal_CreateView"

///|
/// Destroys an SDL Metal view created by `sdl_metal_create_view`.
extern "C" fn sdl_metal_destroy_view(v : @c.OpaquePtr) -> Unit = "SDL_Metal_DestroyView"

///|
/// Returns the CAMetalLayer pointer as the WebGPU canvas object handle.
extern "C" fn sdl_metal_get_layer(v : @c.OpaquePtr) -> @wgpu.HTMLCanvasElement = "SDL_Metal_GetLayer"

///|
/// Returns the raw CAMetalLayer pointer for null checks.
extern "C" fn sdl_metal_get_layer_ptr(v : @c.OpaquePtr) -> @c.OpaquePtr = "SDL_Metal_GetLayer"
