/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

/// Simple DirectMedia Layer
/// Copyright (C) 1997-2025 Sam Lantinga <slouken@libsdl.org>
///
/// This software is provided 'as-is', without any express or implied
/// warranty.  In no event will the authors be held liable for any damages
/// arising from the use of this software.
///
/// Permission is granted to anyone to use this software for any purpose,
/// including commercial applications, and to alter it and redistribute it
/// freely, subject to the following restrictions:
///
/// 1. The origin of this software must not be misrepresented; you must not
///    claim that you wrote the original software. If you use this software
///    in a product, an acknowledgment in the product documentation would be
///    appreciated but is not required.
/// 2. Altered source versions must be plainly marked as such, and must not be
///    misrepresented as being the original software.
/// 3. This notice may not be removed or altered from any source distribution.

///|
/// # CategoryRender
///
/// Header file for SDL 2D rendering functions.
///
/// This API supports the following features:
///
/// - single pixel points
/// - single pixel lines
/// - filled rectangles
/// - texture images
/// - 2D polygons
///
/// The primitives may be drawn in opaque, blended, or additive modes.
///
/// The texture images may be drawn in opaque, blended, or additive modes. They
/// can have an additional color tint or alpha modulation applied to them, and
/// may also be stretched with linear interpolation.
///
/// This API is designed to accelerate simple 2D operations. You may want more
/// functionality such as polygons and particle effects and in that case you
/// should use SDL's OpenGL/Direct3D support, the SDL3 GPU API, or one of the
/// many good 3D engines.
///
/// These functions must be called from the main thread. See this bug for
/// details: https://github.com/libsdl-org/SDL/issues/986
#external
pub type SDL_Renderer

///|
pub fn SDL_Renderer::is_null(self : Self) -> Bool {
  is_nullptr(self)
}

///|
#external
pub type SDL_Texture

///|
pub const SDL_SOFTWARE_RENDERER = "software"

///|
/// Vertex structure.
///
/// @since This struct is available since SDL 3.2.0.
///
/// ```c
/// typedef struct SDL_Vertex
/// {
///     SDL_FPoint position;
///     SDL_FColor color;
///     SDL_FPoint tex_coord;
/// } SDL_Vertex;
/// ```
pub(all) struct SDL_Vertex {
  position : SDL_FPoint
  color : SDL_FColor
  tex_coord : SDL_FPoint
}

///|
/// The access pattern allowed for a texture.
///
/// @since This enum is available since SDL 3.2.0.
///
/// ```c
/// typedef enum SDL_TextureAccess
/// {
///     SDL_TEXTUREACCESS_STATIC,
///     SDL_TEXTUREACCESS_STREAMING,
///     SDL_TEXTUREACCESS_TARGET
/// } SDL_TextureAccess;
/// ```
pub(all) enum SDL_TextureAccess {
  SDL_TEXTUREACCESS_STATIC
  SDL_TEXTUREACCESS_STREAMING
  SDL_TEXTUREACCESS_TARGET
}

///|
/// The addressing mode for a texture when used in SDL_RenderGeometry().
///
/// This affects how texture coordinates are interpreted outside of [0, 1]
///
/// @since This enum is available since SDL 3.4.0.
///
/// ```c
/// typedef enum SDL_TextureAddressMode
/// {
///     SDL_TEXTURE_ADDRESS_INVALID = -1,
///     SDL_TEXTURE_ADDRESS_AUTO,
///     SDL_TEXTURE_ADDRESS_CLAMP,
///     SDL_TEXTURE_ADDRESS_WRAP
/// } SDL_TextureAddressMode;
/// ```
pub(all) enum SDL_TextureAddressMode {
  SDL_TEXTURE_ADDRESS_AUTO
  SDL_TEXTURE_ADDRESS_CLAMP
  SDL_TEXTURE_ADDRESS_WRAP
  SDL_TEXTURE_ADDRESS_INVALID = 0xffff_ffff
}

///|
/// How the logical size is mapped to the output.
///
/// @since This enum is available since SDL 3.2.0.
///
/// ```c
/// typedef enum SDL_RendererLogicalPresentation
/// {
///     SDL_LOGICAL_PRESENTATION_DISABLED,
///     SDL_LOGICAL_PRESENTATION_STRETCH,
///     SDL_LOGICAL_PRESENTATION_LETTERBOX,
///     SDL_LOGICAL_PRESENTATION_OVERSCAN,
///     SDL_LOGICAL_PRESENTATION_INTEGER_SCALE
/// } SDL_RendererLogicalPresentation;
/// ```
pub(all) enum SDL_RendererLogicalPresentation {
  SDL_LOGICAL_PRESENTATION_DISABLED
  SDL_LOGICAL_PRESENTATION_STRETCH
  SDL_LOGICAL_PRESENTATION_LETTERBOX
  SDL_LOGICAL_PRESENTATION_OVERSCAN
  SDL_LOGICAL_PRESENTATION_INTEGER_SCALE
}

///|
/// Get the number of 2D rendering drivers available for the current display.
///
/// A render driver is a set of code that handles rendering and texture
/// management on a particular display. Normally there is only one, but some
/// drivers may have several available with different capabilities.
///
/// There may be none if SDL was compiled without render support.
///
/// @return the number of built in render drivers.
///
/// @threadsafety It is safe to call this function from any thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_CreateRenderer
/// @see SDL_GetRenderDriver
///
/// ```c
/// extern SDL_DECLSPEC int SDLCALL SDL_GetNumRenderDrivers(void);
/// ```
pub extern "C" fn sdl_GetNumRenderDrivers() -> Int = "SDL_GetNumRenderDrivers"

///|
/// Use this function to get the name of a built in 2D rendering driver.
///
/// The list of rendering drivers is given in the order that they are normally
/// initialized by default; the drivers that seem more reasonable to choose
/// first (as far as the SDL developers believe) are earlier in the list.
///
/// The names of drivers are all simple, low-ASCII identifiers, like "opengl",
/// "direct3d12" or "metal". These never have Unicode characters, and are not
/// meant to be proper names.
///
/// @param index the index of the rendering driver; the value ranges from 0 to
///              SDL_GetNumRenderDrivers() - 1.
/// @return the name of the rendering driver at the requested index, or NULL
///          if an invalid index was specified.
///
/// @threadsafety It is safe to call this function from any thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetNumRenderDrivers
///
/// ```c
/// extern SDL_DECLSPEC const char * SDLCALL SDL_GetRenderDriver(int index);
/// ```
pub fn sdl_GetRenderDriver(index : Int) -> String {
  let cstr = __SDL_GetRenderDriver(index)
  let res = cstr.to_string()
  free_cstr(cstr)
  res
}

///|
pub extern "C" fn __SDL_GetRenderDriver(index : Int) -> CStr = "SDL_GetRenderDriver"

///|
/// Create a window and default renderer.
///
/// @param title the title of the window, in UTF-8 encoding.
/// @param width the width of the window.
/// @param height the height of the window.
/// @param window_flags the flags used to create the window (see
///                     SDL_CreateWindow()).
/// @param window a pointer filled with the window, or NULL on error.
/// @param renderer a pointer filled with the renderer, or NULL on error.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_CreateRenderer
/// @see SDL_CreateWindow
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_CreateWindowAndRenderer(const char *title, int width, int height, SDL_WindowFlags window_flags, SDL_Window **window, SDL_Renderer **renderer);
/// ```
pub fn sdl_CreateWindowAndRenderer(
  title : String,
  width : Int,
  height : Int,
  window_flags : SDL_WindowFlags,
  window : FixedArray[SDL_Window],
  renderer : FixedArray[SDL_Renderer],
) -> Bool {
  let c_title = string_to_cbytes(title)
  __SDL_CreateWindowAndRenderer(
    c_title, width, height, window_flags, window, renderer,
  )
}

///|
#owned(title, window, renderer)
pub extern "C" fn __SDL_CreateWindowAndRenderer(
  title : Bytes,
  width : Int,
  height : Int,
  window_flags : SDL_WindowFlags,
  window : FixedArray[SDL_Window],
  renderer : FixedArray[SDL_Renderer],
) -> Bool = "SDL_CreateWindowAndRenderer"

///|
/// Create a 2D rendering context for a window.
///
/// If you want a specific renderer, you can specify its name here. A list of
/// available renderers can be obtained by calling SDL_GetRenderDriver()
/// multiple times, with indices from 0 to SDL_GetNumRenderDrivers()-1. If you
/// don't need a specific renderer, specify NULL and SDL will attempt to choose
/// the best option for you, based on what is available on the user's system.
///
/// If `name` is a comma-separated list, SDL will try each name, in the order
/// listed, until one succeeds or all of them fail.
///
/// By default the rendering size matches the window size in pixels, but you
/// can call SDL_SetRenderLogicalPresentation() to change the content size and
/// scaling options.
///
/// @param window the window where rendering is displayed.
/// @param name the name of the rendering driver to initialize, or NULL to let
///             SDL choose one.
/// @return a valid rendering context or NULL if there was an error; call
///          SDL_GetError() for more information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_CreateRendererWithProperties
/// @see SDL_CreateSoftwareRenderer
/// @see SDL_DestroyRenderer
/// @see SDL_GetNumRenderDrivers
/// @see SDL_GetRenderDriver
/// @see SDL_GetRendererName
///
/// ```c
/// extern SDL_DECLSPEC SDL_Renderer * SDLCALL SDL_CreateRenderer(SDL_Window *window, const char *name);
/// ```
pub fn sdl_CreateRenderer(window : SDL_Window, name : String) -> SDL_Renderer {
  let c_name = string_to_cbytes(name)
  __SDL_CreateRenderer(window, c_name)
}

///|
#owned(name)
pub extern "C" fn __SDL_CreateRenderer(
  window : SDL_Window,
  name : Bytes,
) -> SDL_Renderer = "SDL_CreateRenderer"

///|
/// Create a 2D rendering context for a window, with the specified properties.
///
/// These are the supported properties:
///
/// - `SDL_PROP_RENDERER_CREATE_NAME_STRING`: the name of the rendering driver
///   to use, if a specific one is desired
/// - `SDL_PROP_RENDERER_CREATE_WINDOW_POINTER`: the window where rendering is
///   displayed, required if this isn't a software renderer using a surface
/// - `SDL_PROP_RENDERER_CREATE_SURFACE_POINTER`: the surface where rendering
///   is displayed, if you want a software renderer without a window
/// - `SDL_PROP_RENDERER_CREATE_OUTPUT_COLORSPACE_NUMBER`: an SDL_Colorspace
///   value describing the colorspace for output to the display, defaults to
///   SDL_COLORSPACE_SRGB. The direct3d11, direct3d12, and metal renderers
///   support SDL_COLORSPACE_SRGB_LINEAR, which is a linear color space and
///   supports HDR output. If you select SDL_COLORSPACE_SRGB_LINEAR, drawing
///   still uses the sRGB colorspace, but values can go beyond 1.0 and float
///   (linear) format textures can be used for HDR content.
/// - `SDL_PROP_RENDERER_CREATE_PRESENT_VSYNC_NUMBER`: non-zero if you want
///   present synchronized with the refresh rate. This property can take any
///   value that is supported by SDL_SetRenderVSync() for the renderer.
///
/// With the SDL GPU renderer:
///
/// - `SDL_PROP_RENDERER_CREATE_GPU_SHADERS_SPIRV_BOOLEAN`: the app is able to
///   provide SPIR-V shaders to SDL_GPURenderState, optional.
/// - `SDL_PROP_RENDERER_CREATE_GPU_SHADERS_DXIL_BOOLEAN`: the app is able to
///   provide DXIL shaders to SDL_GPURenderState, optional.
/// - `SDL_PROP_RENDERER_CREATE_GPU_SHADERS_MSL_BOOLEAN`: the app is able to
///   provide MSL shaders to SDL_GPURenderState, optional.
///
/// With the vulkan renderer:
///
/// - `SDL_PROP_RENDERER_CREATE_VULKAN_INSTANCE_POINTER`: the VkInstance to use
///   with the renderer, optional.
/// - `SDL_PROP_RENDERER_CREATE_VULKAN_SURFACE_NUMBER`: the VkSurfaceKHR to use
///   with the renderer, optional.
/// - `SDL_PROP_RENDERER_CREATE_VULKAN_PHYSICAL_DEVICE_POINTER`: the
///   VkPhysicalDevice to use with the renderer, optional.
/// - `SDL_PROP_RENDERER_CREATE_VULKAN_DEVICE_POINTER`: the VkDevice to use
///   with the renderer, optional.
/// - `SDL_PROP_RENDERER_CREATE_VULKAN_GRAPHICS_QUEUE_FAMILY_INDEX_NUMBER`: the
///   queue family index used for rendering.
/// - `SDL_PROP_RENDERER_CREATE_VULKAN_PRESENT_QUEUE_FAMILY_INDEX_NUMBER`: the
///   queue family index used for presentation.
///
/// @param props the properties to use.
/// @return a valid rendering context or NULL if there was an error; call
///          SDL_GetError() for more information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_CreateProperties
/// @see SDL_CreateRenderer
/// @see SDL_CreateSoftwareRenderer
/// @see SDL_DestroyRenderer
/// @see SDL_GetRendererName
///
/// ```c
/// extern SDL_DECLSPEC SDL_Renderer * SDLCALL SDL_CreateRendererWithProperties(SDL_PropertiesID props);
/// ```
pub extern "C" fn sdl_CreateRendererWithProperties(
  props : SDL_PropertiesID,
) -> SDL_Renderer = "SDL_CreateRendererWithProperties"

///|
pub const SDL_PROP_RENDERER_CREATE_NAME_STRING = "SDL.renderer.create.name"

///|
pub const SDL_PROP_RENDERER_CREATE_WINDOW_POINTER = "SDL.renderer.create.window"

///|
pub const SDL_PROP_RENDERER_CREATE_SURFACE_POINTER = "SDL.renderer.create.surface"

///|
pub const SDL_PROP_RENDERER_CREATE_OUTPUT_COLORSPACE_NUMBER = "SDL.renderer.create.output_colorspace"

///|
pub const SDL_PROP_RENDERER_CREATE_PRESENT_VSYNC_NUMBER = "SDL.renderer.create.present_vsync"

///|
pub const SDL_PROP_RENDERER_CREATE_GPU_SHADERS_SPIRV_BOOLEAN = "SDL.renderer.create.gpu.shaders_spirv"

///|
pub const SDL_PROP_RENDERER_CREATE_GPU_SHADERS_DXIL_BOOLEAN = "SDL.renderer.create.gpu.shaders_dxil"

///|
pub const SDL_PROP_RENDERER_CREATE_GPU_SHADERS_MSL_BOOLEAN = "SDL.renderer.create.gpu.shaders_msl"

///|
pub const SDL_PROP_RENDERER_CREATE_VULKAN_INSTANCE_POINTER = "SDL.renderer.create.vulkan.instance"

///|
pub const SDL_PROP_RENDERER_CREATE_VULKAN_SURFACE_NUMBER = "SDL.renderer.create.vulkan.surface"

///|
pub const SDL_PROP_RENDERER_CREATE_VULKAN_PHYSICAL_DEVICE_POINTER = "SDL.renderer.create.vulkan.physical_device"

///|
pub const SDL_PROP_RENDERER_CREATE_VULKAN_DEVICE_POINTER = "SDL.renderer.create.vulkan.device"

///|
pub const SDL_PROP_RENDERER_CREATE_VULKAN_GRAPHICS_QUEUE_FAMILY_INDEX_NUMBER = "SDL.renderer.create.vulkan.graphics_queue_family_index"

///|
pub const SDL_PROP_RENDERER_CREATE_VULKAN_PRESENT_QUEUE_FAMILY_INDEX_NUMBER = "SDL.renderer.create.vulkan.present_queue_family_index"

///| Create a 2D GPU rendering context for a window, with support for the

///|
/// specified shader format.
///
/// This is a convenience function to create a SDL GPU backed renderer,
/// intended to be used with SDL_GPURenderState. The resulting renderer will
/// support shaders in one of the specified shader formats.
///
/// If no available GPU driver supports any of the specified shader formats,
/// this function will fail.
///
/// @param window the window where rendering is displayed.
/// @param format_flags a bitflag indicating which shader formats the app is
///                     able to provide.
/// @param device a pointer filled with the associated GPU device, or NULL on
///               error.
/// @return a valid rendering context or NULL if there was an error; call
///          SDL_GetError() for more information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.4.0.
///
/// @see SDL_CreateRendererWithProperties
/// @see SDL_GetGPUShaderFormats
/// @see SDL_CreateGPUShader
/// @see SDL_CreateGPURenderState
/// @see SDL_SetRenderGPUState
///
/// ```c
/// extern SDL_DECLSPEC SDL_Renderer * SDLCALL SDL_CreateGPURenderer(SDL_Window *window, SDL_GPUShaderFormat format_flags, SDL_GPUDevice **device);
/// ```
#owned(device)
pub extern "C" fn sdl_CreateGPURenderer(
  window : SDL_Window,
  format_flags : SDL_GPUShaderFormat,
  device : FixedArray[SDL_GPUDevice],
) -> SDL_Renderer = "SDL_CreateGPURenderer"

///|
/// Create a 2D software rendering context for a surface.
///
/// Two other API which can be used to create SDL_Renderer:
/// SDL_CreateRenderer() and SDL_CreateWindowAndRenderer(). These can _also_
/// create a software renderer, but they are intended to be used with an
/// SDL_Window as the final destination and not an SDL_Surface.
///
/// @param surface the SDL_Surface structure representing the surface where
///                rendering is done.
/// @return a valid rendering context or NULL if there was an error; call
///          SDL_GetError() for more information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_DestroyRenderer
///
/// ```c
/// extern SDL_DECLSPEC SDL_Renderer * SDLCALL SDL_CreateSoftwareRenderer(SDL_Surface *surface);
/// ```
pub extern "C" fn sdl_CreateSoftwareRenderer(
  surface : SDL_Surface,
) -> SDL_Renderer = "SDL_CreateSoftwareRenderer"

///|
/// Get the renderer associated with a window.
///
/// @param window the window to query.
/// @return the rendering context on success or NULL on failure; call
///          SDL_GetError() for more information.
///
/// @threadsafety It is safe to call this function from any thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// ```c
/// extern SDL_DECLSPEC SDL_Renderer * SDLCALL SDL_GetRenderer(SDL_Window *window);
/// ```
pub extern "C" fn sdl_GetRenderer(window : SDL_Window) -> SDL_Renderer = "SDL_GetRenderer"

///|
/// Get the window associated with a renderer.
///
/// @param renderer the renderer to query.
/// @return the window on success or NULL on failure; call SDL_GetError() for
///          more information.
///
/// @threadsafety It is safe to call this function from any thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// ```c
/// extern SDL_DECLSPEC SDL_Window * SDLCALL SDL_GetRenderWindow(SDL_Renderer *renderer);
/// ```
pub extern "C" fn sdl_GetRenderWindow(renderer : SDL_Renderer) -> SDL_Window = "SDL_GetRenderWindow"

///|
/// Get the name of a renderer.
///
/// @param renderer the rendering context.
/// @return the name of the selected renderer, or NULL on failure; call
///          SDL_GetError() for more information.
///
/// @threadsafety It is safe to call this function from any thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_CreateRenderer
/// @see SDL_CreateRendererWithProperties
///
/// ```c
/// extern SDL_DECLSPEC const char * SDLCALL SDL_GetRendererName(SDL_Renderer *renderer);
/// ```
pub fn sdl_GetRendererName(renderer : SDL_Renderer) -> String {
  let cstr = __SDL_GetRendererName(renderer)
  let res = cstr.to_string()
  free_cstr(cstr)
  res
}

///|
pub extern "C" fn __SDL_GetRendererName(renderer : SDL_Renderer) -> CStr = "SDL_GetRendererName"

///|
/// Get the properties associated with a renderer.
///
/// The following read-only properties are provided by SDL:
///
/// - `SDL_PROP_RENDERER_NAME_STRING`: the name of the rendering driver
/// - `SDL_PROP_RENDERER_WINDOW_POINTER`: the window where rendering is
///   displayed, if any
/// - `SDL_PROP_RENDERER_SURFACE_POINTER`: the surface where rendering is
///   displayed, if this is a software renderer without a window
/// - `SDL_PROP_RENDERER_VSYNC_NUMBER`: the current vsync setting
/// - `SDL_PROP_RENDERER_MAX_TEXTURE_SIZE_NUMBER`: the maximum texture width
///   and height
/// - `SDL_PROP_RENDERER_TEXTURE_FORMATS_POINTER`: a (const SDL_PixelFormat *)
///   array of pixel formats, terminated with SDL_PIXELFORMAT_UNKNOWN,
///   representing the available texture formats for this renderer.
/// - `SDL_PROP_RENDERER_OUTPUT_COLORSPACE_NUMBER`: an SDL_Colorspace value
///   describing the colorspace for output to the display, defaults to
///   SDL_COLORSPACE_SRGB.
/// - `SDL_PROP_RENDERER_HDR_ENABLED_BOOLEAN`: true if the output colorspace is
///   SDL_COLORSPACE_SRGB_LINEAR and the renderer is showing on a display with
///   HDR enabled. This property can change dynamically when
///   SDL_EVENT_WINDOW_HDR_STATE_CHANGED is sent.
/// - `SDL_PROP_RENDERER_SDR_WHITE_POINT_FLOAT`: the value of SDR white in the
///   SDL_COLORSPACE_SRGB_LINEAR colorspace. When HDR is enabled, this value is
///   automatically multiplied into the color scale. This property can change
///   dynamically when SDL_EVENT_WINDOW_HDR_STATE_CHANGED is sent.
/// - `SDL_PROP_RENDERER_HDR_HEADROOM_FLOAT`: the additional high dynamic range
///   that can be displayed, in terms of the SDR white point. When HDR is not
///   enabled, this will be 1.0. This property can change dynamically when
///   SDL_EVENT_WINDOW_HDR_STATE_CHANGED is sent.
///
/// With the direct3d renderer:
///
/// - `SDL_PROP_RENDERER_D3D9_DEVICE_POINTER`: the IDirect3DDevice9 associated
///   with the renderer
///
/// With the direct3d11 renderer:
///
/// - `SDL_PROP_RENDERER_D3D11_DEVICE_POINTER`: the ID3D11Device associated
///   with the renderer
/// - `SDL_PROP_RENDERER_D3D11_SWAPCHAIN_POINTER`: the IDXGISwapChain1
///   associated with the renderer. This may change when the window is resized.
///
/// With the direct3d12 renderer:
///
/// - `SDL_PROP_RENDERER_D3D12_DEVICE_POINTER`: the ID3D12Device associated
///   with the renderer
/// - `SDL_PROP_RENDERER_D3D12_SWAPCHAIN_POINTER`: the IDXGISwapChain4
///   associated with the renderer.
/// - `SDL_PROP_RENDERER_D3D12_COMMAND_QUEUE_POINTER`: the ID3D12CommandQueue
///   associated with the renderer
///
/// With the vulkan renderer:
///
/// - `SDL_PROP_RENDERER_VULKAN_INSTANCE_POINTER`: the VkInstance associated
///   with the renderer
/// - `SDL_PROP_RENDERER_VULKAN_SURFACE_NUMBER`: the VkSurfaceKHR associated
///   with the renderer
/// - `SDL_PROP_RENDERER_VULKAN_PHYSICAL_DEVICE_POINTER`: the VkPhysicalDevice
///   associated with the renderer
/// - `SDL_PROP_RENDERER_VULKAN_DEVICE_POINTER`: the VkDevice associated with
///   the renderer
/// - `SDL_PROP_RENDERER_VULKAN_GRAPHICS_QUEUE_FAMILY_INDEX_NUMBER`: the queue
///   family index used for rendering
/// - `SDL_PROP_RENDERER_VULKAN_PRESENT_QUEUE_FAMILY_INDEX_NUMBER`: the queue
///   family index used for presentation
/// - `SDL_PROP_RENDERER_VULKAN_SWAPCHAIN_IMAGE_COUNT_NUMBER`: the number of
///   swapchain images, or potential frames in flight, used by the Vulkan
///   renderer
///
/// With the gpu renderer:
///
/// - `SDL_PROP_RENDERER_GPU_DEVICE_POINTER`: the SDL_GPUDevice associated with
///   the renderer
///
/// @param renderer the rendering context.
/// @return a valid property ID on success or 0 on failure; call
///          SDL_GetError() for more information.
///
/// @threadsafety It is safe to call this function from any thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// ```c
/// extern SDL_DECLSPEC SDL_PropertiesID SDLCALL SDL_GetRendererProperties(SDL_Renderer *renderer);
/// ```
pub extern "C" fn sdl_GetRendererProperties(
  renderer : SDL_Renderer,
) -> SDL_PropertiesID = "SDL_GetRendererProperties"

///|
pub const SDL_PROP_RENDERER_NAME_STRING = "SDL.renderer.name"

///|
pub const SDL_PROP_RENDERER_WINDOW_POINTER = "SDL.renderer.window"

///|
pub const SDL_PROP_RENDERER_SURFACE_POINTER = "SDL.renderer.surface"

///|
pub const SDL_PROP_RENDERER_VSYNC_NUMBER = "SDL.renderer.vsync"

///|
pub const SDL_PROP_RENDERER_MAX_TEXTURE_SIZE_NUMBER = "SDL.renderer.max_texture_size"

///|
pub const SDL_PROP_RENDERER_TEXTURE_FORMATS_POINTER = "SDL.renderer.texture_formats"

///|
pub const SDL_PROP_RENDERER_OUTPUT_COLORSPACE_NUMBER = "SDL.renderer.output_colorspace"

///|
pub const SDL_PROP_RENDERER_HDR_ENABLED_BOOLEAN = "SDL.renderer.HDR_enabled"

///|
pub const SDL_PROP_RENDERER_SDR_WHITE_POINT_FLOAT = "SDL.renderer.SDR_white_point"

///|
pub const SDL_PROP_RENDERER_HDR_HEADROOM_FLOAT = "SDL.renderer.HDR_headroom"

///|
pub const SDL_PROP_RENDERER_D3D9_DEVICE_POINTER = "SDL.renderer.d3d9.device"

///|
pub const SDL_PROP_RENDERER_D3D11_DEVICE_POINTER = "SDL.renderer.d3d11.device"

///|
pub const SDL_PROP_RENDERER_D3D11_SWAPCHAIN_POINTER = "SDL.renderer.d3d11.swap_chain"

///|
pub const SDL_PROP_RENDERER_D3D12_DEVICE_POINTER = "SDL.renderer.d3d12.device"

///|
pub const SDL_PROP_RENDERER_D3D12_SWAPCHAIN_POINTER = "SDL.renderer.d3d12.swap_chain"

///|
pub const SDL_PROP_RENDERER_D3D12_COMMAND_QUEUE_POINTER = "SDL.renderer.d3d12.command_queue"

///|
pub const SDL_PROP_RENDERER_VULKAN_INSTANCE_POINTER = "SDL.renderer.vulkan.instance"

///|
pub const SDL_PROP_RENDERER_VULKAN_SURFACE_NUMBER = "SDL.renderer.vulkan.surface"

///|
pub const SDL_PROP_RENDERER_VULKAN_PHYSICAL_DEVICE_POINTER = "SDL.renderer.vulkan.physical_device"

///|
pub const SDL_PROP_RENDERER_VULKAN_DEVICE_POINTER = "SDL.renderer.vulkan.device"

///|
pub const SDL_PROP_RENDERER_VULKAN_GRAPHICS_QUEUE_FAMILY_INDEX_NUMBER = "SDL.renderer.vulkan.graphics_queue_family_index"

///|
pub const SDL_PROP_RENDERER_VULKAN_PRESENT_QUEUE_FAMILY_INDEX_NUMBER = "SDL.renderer.vulkan.present_queue_family_index"

///|
pub const SDL_PROP_RENDERER_VULKAN_SWAPCHAIN_IMAGE_COUNT_NUMBER = "SDL.renderer.vulkan.swapchain_image_count"

///|
pub const SDL_PROP_RENDERER_GPU_DEVICE_POINTER = "SDL.renderer.gpu.device"

///|
/// Get the output size in pixels of a rendering context.
///
/// This returns the true output size in pixels, ignoring any render targets or
/// logical size and presentation.
///
/// For the output size of the current rendering target, with logical size
/// adjustments, use SDL_GetCurrentRenderOutputSize() instead.
///
/// @param renderer the rendering context.
/// @param w a pointer filled in with the width in pixels.
/// @param h a pointer filled in with the height in pixels.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetCurrentRenderOutputSize
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetRenderOutputSize(SDL_Renderer *renderer, int *w, int *h);
/// ```
#owned(w, h)
pub extern "C" fn sdl_GetRenderOutputSize(
  renderer : SDL_Renderer,
  w : FixedArray[Int],
  h : FixedArray[Int],
) -> Bool = "SDL_GetRenderOutputSize"

///|
/// Get the current output size in pixels of a rendering context.
///
/// If a rendering target is active, this will return the size of the rendering
/// target in pixels, otherwise return the value of SDL_GetRenderOutputSize().
///
/// Rendering target or not, the output will be adjusted by the current logical
/// presentation state, dictated by SDL_SetRenderLogicalPresentation().
///
/// @param renderer the rendering context.
/// @param w a pointer filled in with the current width.
/// @param h a pointer filled in with the current height.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetRenderOutputSize
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetCurrentRenderOutputSize(SDL_Renderer *renderer, int *w, int *h);
/// ```
#owned(w, h)
pub extern "C" fn sdl_GetCurrentRenderOutputSize(
  renderer : SDL_Renderer,
  w : FixedArray[Int],
  h : FixedArray[Int],
) -> Bool = "SDL_GetCurrentRenderOutputSize"

///|
/// Create a texture for a rendering context.
///
/// The contents of a texture when first created are not defined.
///
/// @param renderer the rendering context.
/// @param format one of the enumerated values in SDL_PixelFormat.
/// @param access one of the enumerated values in SDL_TextureAccess.
/// @param w the width of the texture in pixels.
/// @param h the height of the texture in pixels.
/// @return the created texture or NULL on failure; call SDL_GetError() for
///          more information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_CreateTextureFromSurface
/// @see SDL_CreateTextureWithProperties
/// @see SDL_DestroyTexture
/// @see SDL_GetTextureSize
/// @see SDL_UpdateTexture
///
/// ```c
/// extern SDL_DECLSPEC SDL_Texture * SDLCALL SDL_CreateTexture(SDL_Renderer *renderer, SDL_PixelFormat format, SDL_TextureAccess access, int w, int h);
/// ```
pub extern "C" fn sdl_CreateTexture(
  renderer : SDL_Renderer,
  format : SDL_PixelFormat,
  access : SDL_TextureAccess,
  w : Int,
  h : Int,
) -> SDL_Texture = "SDL_CreateTexture"

///|
/// Create a texture from an existing surface.
///
/// The surface is not modified or freed by this function.
///
/// The SDL_TextureAccess hint for the created texture is
/// `SDL_TEXTUREACCESS_STATIC`.
///
/// The pixel format of the created texture may be different from the pixel
/// format of the surface, and can be queried using the
/// SDL_PROP_TEXTURE_FORMAT_NUMBER property.
///
/// @param renderer the rendering context.
/// @param surface the SDL_Surface structure containing pixel data used to fill
///                the texture.
/// @return the created texture or NULL on failure; call SDL_GetError() for
///          more information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_CreateTexture
/// @see SDL_CreateTextureWithProperties
/// @see SDL_DestroyTexture
///
/// ```c
/// extern SDL_DECLSPEC SDL_Texture * SDLCALL SDL_CreateTextureFromSurface(SDL_Renderer *renderer, SDL_Surface *surface);
/// ```
pub extern "C" fn sdl_CreateTextureFromSurface(
  renderer : SDL_Renderer,
  surface : SDL_Surface,
) -> SDL_Texture = "SDL_CreateTextureFromSurface"
