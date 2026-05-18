///| [SDL3 SDL_metal.h](https://github.com/libsdl-org/SDL/blob/main/include/SDL3/SDL_metal.h) minimal FFI.

///|
/// Creates an SDL Metal view for a native SDL window.
extern "C" fn sdl_metal_create_view(
  w : @lib.SDL_Window,
) -> @wgpu_objects.OpaquePtr = "SDL_Metal_CreateView"

///|
/// Destroys an SDL Metal view created by `sdl_metal_create_view`.
#borrow(v)
extern "C" fn sdl_metal_destroy_view(v : @wgpu_objects.OpaquePtr) -> Unit = "SDL_Metal_DestroyView"

///|
/// Returns the CAMetalLayer pointer as the WebGPU canvas object handle.
#borrow(v)
extern "C" fn sdl_metal_get_layer(
  v : @wgpu_objects.OpaquePtr,
) -> @wgpu.HTMLCanvasElement = "SDL_Metal_GetLayer"

///|
/// Returns the raw CAMetalLayer pointer for null checks.
#borrow(v)
extern "C" fn sdl_metal_get_layer_ptr(
  v : @wgpu_objects.OpaquePtr,
) -> @wgpu_objects.OpaquePtr = "SDL_Metal_GetLayer"
