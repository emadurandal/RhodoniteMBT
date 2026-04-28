///| [SDL3 SDL_metal.h](https://github.com/libsdl-org/SDL/blob/main/include/SDL3/SDL_metal.h) 最小 FFI。

///|
extern "C" fn sdl_metal_create_view(w : @lib.SDL_Window) -> @c.OpaquePtr = "SDL_Metal_CreateView"

///|
extern "C" fn sdl_metal_destroy_view(v : @c.OpaquePtr) -> Unit = "SDL_Metal_DestroyView"

///|
extern "C" fn sdl_metal_get_layer(v : @c.OpaquePtr) -> @w.HTMLCanvasElement = "SDL_Metal_GetLayer"

///|
extern "C" fn sdl_metal_get_layer_ptr(v : @c.OpaquePtr) -> @c.OpaquePtr = "SDL_Metal_GetLayer"
