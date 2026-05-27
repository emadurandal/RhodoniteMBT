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
/// Create a texture for a rendering context with the specified properties.
///
/// These are the supported properties:
///
/// - `SDL_PROP_TEXTURE_CREATE_COLORSPACE_NUMBER`: an SDL_Colorspace value
///   describing the texture colorspace, defaults to SDL_COLORSPACE_SRGB_LINEAR
///   for floating point textures, SDL_COLORSPACE_HDR10 for 10-bit textures,
///   SDL_COLORSPACE_SRGB for other RGB textures and SDL_COLORSPACE_JPEG for
///   YUV textures.
/// - `SDL_PROP_TEXTURE_CREATE_FORMAT_NUMBER`: one of the enumerated values in
///   SDL_PixelFormat, defaults to the best RGBA format for the renderer
/// - `SDL_PROP_TEXTURE_CREATE_ACCESS_NUMBER`: one of the enumerated values in
///   SDL_TextureAccess, defaults to SDL_TEXTUREACCESS_STATIC
/// - `SDL_PROP_TEXTURE_CREATE_WIDTH_NUMBER`: the width of the texture in
///   pixels, required
/// - `SDL_PROP_TEXTURE_CREATE_HEIGHT_NUMBER`: the height of the texture in
///   pixels, required
/// - `SDL_PROP_TEXTURE_CREATE_SDR_WHITE_POINT_FLOAT`: for HDR10 and floating
///   point textures, this defines the value of 100% diffuse white, with higher
///   values being displayed in the High Dynamic Range headroom. This defaults
///   to 100 for HDR10 textures and 1.0 for floating point textures.
/// - `SDL_PROP_TEXTURE_CREATE_HDR_HEADROOM_FLOAT`: for HDR10 and floating
///   point textures, this defines the maximum dynamic range used by the
///   content, in terms of the SDR white point. This would be equivalent to
///   maxCLL / SDL_PROP_TEXTURE_CREATE_SDR_WHITE_POINT_FLOAT for HDR10 content.
///   If this is defined, any values outside the range supported by the display
///   will be scaled into the available HDR headroom, otherwise they are
///   clipped.
///
/// With the direct3d11 renderer:
///
/// - `SDL_PROP_TEXTURE_CREATE_D3D11_TEXTURE_POINTER`: the ID3D11Texture2D
///   associated with the texture, if you want to wrap an existing texture.
/// - `SDL_PROP_TEXTURE_CREATE_D3D11_TEXTURE_U_POINTER`: the ID3D11Texture2D
///   associated with the U plane of a YUV texture, if you want to wrap an
///   existing texture.
/// - `SDL_PROP_TEXTURE_CREATE_D3D11_TEXTURE_V_POINTER`: the ID3D11Texture2D
///   associated with the V plane of a YUV texture, if you want to wrap an
///   existing texture.
///
/// With the direct3d12 renderer:
///
/// - `SDL_PROP_TEXTURE_CREATE_D3D12_TEXTURE_POINTER`: the ID3D12Resource
///   associated with the texture, if you want to wrap an existing texture.
/// - `SDL_PROP_TEXTURE_CREATE_D3D12_TEXTURE_U_POINTER`: the ID3D12Resource
///   associated with the U plane of a YUV texture, if you want to wrap an
///   existing texture.
/// - `SDL_PROP_TEXTURE_CREATE_D3D12_TEXTURE_V_POINTER`: the ID3D12Resource
///   associated with the V plane of a YUV texture, if you want to wrap an
///   existing texture.
///
/// With the metal renderer:
///
/// - `SDL_PROP_TEXTURE_CREATE_METAL_PIXELBUFFER_POINTER`: the CVPixelBufferRef
///   associated with the texture, if you want to create a texture from an
///   existing pixel buffer.
///
/// With the opengl renderer:
///
/// - `SDL_PROP_TEXTURE_CREATE_OPENGL_TEXTURE_NUMBER`: the GLuint texture
///   associated with the texture, if you want to wrap an existing texture.
/// - `SDL_PROP_TEXTURE_CREATE_OPENGL_TEXTURE_UV_NUMBER`: the GLuint texture
///   associated with the UV plane of an NV12 texture, if you want to wrap an
///   existing texture.
/// - `SDL_PROP_TEXTURE_CREATE_OPENGL_TEXTURE_U_NUMBER`: the GLuint texture
///   associated with the U plane of a YUV texture, if you want to wrap an
///   existing texture.
/// - `SDL_PROP_TEXTURE_CREATE_OPENGL_TEXTURE_V_NUMBER`: the GLuint texture
///   associated with the V plane of a YUV texture, if you want to wrap an
///   existing texture.
///
/// With the opengles2 renderer:
///
/// - `SDL_PROP_TEXTURE_CREATE_OPENGLES2_TEXTURE_NUMBER`: the GLuint texture
///   associated with the texture, if you want to wrap an existing texture.
/// - `SDL_PROP_TEXTURE_CREATE_OPENGLES2_TEXTURE_NUMBER`: the GLuint texture
///   associated with the texture, if you want to wrap an existing texture.
/// - `SDL_PROP_TEXTURE_CREATE_OPENGLES2_TEXTURE_UV_NUMBER`: the GLuint texture
///   associated with the UV plane of an NV12 texture, if you want to wrap an
///   existing texture.
/// - `SDL_PROP_TEXTURE_CREATE_OPENGLES2_TEXTURE_U_NUMBER`: the GLuint texture
///   associated with the U plane of a YUV texture, if you want to wrap an
///   existing texture.
/// - `SDL_PROP_TEXTURE_CREATE_OPENGLES2_TEXTURE_V_NUMBER`: the GLuint texture
///   associated with the V plane of a YUV texture, if you want to wrap an
///   existing texture.
///
/// With the vulkan renderer:
///
/// - `SDL_PROP_TEXTURE_CREATE_VULKAN_TEXTURE_NUMBER`: the VkImage with layout
///   VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL associated with the texture, if
///   you want to wrap an existing texture.
///
/// @param renderer the rendering context.
/// @param props the properties to use.
/// @return the created texture or NULL on failure; call SDL_GetError() for
///          more information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_CreateProperties
/// @see SDL_CreateTexture
/// @see SDL_CreateTextureFromSurface
/// @see SDL_DestroyTexture
/// @see SDL_GetTextureSize
/// @see SDL_UpdateTexture
///
/// ```c
/// extern SDL_DECLSPEC SDL_Texture * SDLCALL SDL_CreateTextureWithProperties(SDL_Renderer *renderer, SDL_PropertiesID props);
/// ```
pub extern "C" fn sdl_CreateTextureWithProperties(
  renderer : SDL_Renderer,
  props : SDL_PropertiesID,
) -> SDL_Texture = "SDL_CreateTextureWithProperties"

///|
pub const SDL_PROP_TEXTURE_CREATE_COLORSPACE_NUMBER = "SDL.texture.create.colorspace"

///|
pub const SDL_PROP_TEXTURE_CREATE_FORMAT_NUMBER = "SDL.texture.create.format"

///|
pub const SDL_PROP_TEXTURE_CREATE_ACCESS_NUMBER = "SDL.texture.create.access"

///|
pub const SDL_PROP_TEXTURE_CREATE_WIDTH_NUMBER = "SDL.texture.create.width"

///|
pub const SDL_PROP_TEXTURE_CREATE_HEIGHT_NUMBER = "SDL.texture.create.height"

///|
pub const SDL_PROP_TEXTURE_CREATE_SDR_WHITE_POINT_FLOAT = "SDL.texture.create.SDR_white_point"

///|
pub const SDL_PROP_TEXTURE_CREATE_HDR_HEADROOM_FLOAT = "SDL.texture.create.HDR_headroom"

///|
pub const SDL_PROP_TEXTURE_CREATE_D3D11_TEXTURE_POINTER = "SDL.texture.create.d3d11.texture"

///|
pub const SDL_PROP_TEXTURE_CREATE_D3D11_TEXTURE_U_POINTER = "SDL.texture.create.d3d11.texture_u"

///|
pub const SDL_PROP_TEXTURE_CREATE_D3D11_TEXTURE_V_POINTER = "SDL.texture.create.d3d11.texture_v"

///|
pub const SDL_PROP_TEXTURE_CREATE_D3D12_TEXTURE_POINTER = "SDL.texture.create.d3d12.texture"

///|
pub const SDL_PROP_TEXTURE_CREATE_D3D12_TEXTURE_U_POINTER = "SDL.texture.create.d3d12.texture_u"

///|
pub const SDL_PROP_TEXTURE_CREATE_D3D12_TEXTURE_V_POINTER = "SDL.texture.create.d3d12.texture_v"

///|
pub const SDL_PROP_TEXTURE_CREATE_METAL_PIXELBUFFER_POINTER = "SDL.texture.create.metal.pixelbuffer"

///|
pub const SDL_PROP_TEXTURE_CREATE_OPENGL_TEXTURE_NUMBER = "SDL.texture.create.opengl.texture"

///|
pub const SDL_PROP_TEXTURE_CREATE_OPENGL_TEXTURE_UV_NUMBER = "SDL.texture.create.opengl.texture_uv"

///|
pub const SDL_PROP_TEXTURE_CREATE_OPENGL_TEXTURE_U_NUMBER = "SDL.texture.create.opengl.texture_u"

///|
pub const SDL_PROP_TEXTURE_CREATE_OPENGL_TEXTURE_V_NUMBER = "SDL.texture.create.opengl.texture_v"

///|
pub const SDL_PROP_TEXTURE_CREATE_OPENGLES2_TEXTURE_NUMBER = "SDL.texture.create.opengles2.texture"

///|
pub const SDL_PROP_TEXTURE_CREATE_OPENGLES2_TEXTURE_UV_NUMBER = "SDL.texture.create.opengles2.texture_uv"

///|
pub const SDL_PROP_TEXTURE_CREATE_OPENGLES2_TEXTURE_U_NUMBER = "SDL.texture.create.opengles2.texture_u"

///|
pub const SDL_PROP_TEXTURE_CREATE_OPENGLES2_TEXTURE_V_NUMBER = "SDL.texture.create.opengles2.texture_v"

///|
pub const SDL_PROP_TEXTURE_CREATE_VULKAN_TEXTURE_NUMBER = "SDL.texture.create.vulkan.texture"

///|
/// Get the properties associated with a texture.
///
/// The following read-only properties are provided by SDL:
///
/// - `SDL_PROP_TEXTURE_COLORSPACE_NUMBER`: an SDL_Colorspace value describing
///   the texture colorspace.
/// - `SDL_PROP_TEXTURE_FORMAT_NUMBER`: one of the enumerated values in
///   SDL_PixelFormat.
/// - `SDL_PROP_TEXTURE_ACCESS_NUMBER`: one of the enumerated values in
///   SDL_TextureAccess.
/// - `SDL_PROP_TEXTURE_WIDTH_NUMBER`: the width of the texture in pixels.
/// - `SDL_PROP_TEXTURE_HEIGHT_NUMBER`: the height of the texture in pixels.
/// - `SDL_PROP_TEXTURE_SDR_WHITE_POINT_FLOAT`: for HDR10 and floating point
///   textures, this defines the value of 100% diffuse white, with higher
///   values being displayed in the High Dynamic Range headroom. This defaults
///   to 100 for HDR10 textures and 1.0 for other textures.
/// - `SDL_PROP_TEXTURE_HDR_HEADROOM_FLOAT`: for HDR10 and floating point
///   textures, this defines the maximum dynamic range used by the content, in
///   terms of the SDR white point. If this is defined, any values outside the
///   range supported by the display will be scaled into the available HDR
///   headroom, otherwise they are clipped. This defaults to 1.0 for SDR
///   textures, 4.0 for HDR10 textures, and no default for floating point
///   textures.
///
/// With the direct3d11 renderer:
///
/// - `SDL_PROP_TEXTURE_D3D11_TEXTURE_POINTER`: the ID3D11Texture2D associated
///   with the texture
/// - `SDL_PROP_TEXTURE_D3D11_TEXTURE_U_POINTER`: the ID3D11Texture2D
///   associated with the U plane of a YUV texture
/// - `SDL_PROP_TEXTURE_D3D11_TEXTURE_V_POINTER`: the ID3D11Texture2D
///   associated with the V plane of a YUV texture
///
/// With the direct3d12 renderer:
///
/// - `SDL_PROP_TEXTURE_D3D12_TEXTURE_POINTER`: the ID3D12Resource associated
///   with the texture
/// - `SDL_PROP_TEXTURE_D3D12_TEXTURE_U_POINTER`: the ID3D12Resource associated
///   with the U plane of a YUV texture
/// - `SDL_PROP_TEXTURE_D3D12_TEXTURE_V_POINTER`: the ID3D12Resource associated
///   with the V plane of a YUV texture
///
/// With the vulkan renderer:
///
/// - `SDL_PROP_TEXTURE_VULKAN_TEXTURE_NUMBER`: the VkImage associated with the
///   texture
///
/// With the opengl renderer:
///
/// - `SDL_PROP_TEXTURE_OPENGL_TEXTURE_NUMBER`: the GLuint texture associated
///   with the texture
/// - `SDL_PROP_TEXTURE_OPENGL_TEXTURE_UV_NUMBER`: the GLuint texture
///   associated with the UV plane of an NV12 texture
/// - `SDL_PROP_TEXTURE_OPENGL_TEXTURE_U_NUMBER`: the GLuint texture associated
///   with the U plane of a YUV texture
/// - `SDL_PROP_TEXTURE_OPENGL_TEXTURE_V_NUMBER`: the GLuint texture associated
///   with the V plane of a YUV texture
/// - `SDL_PROP_TEXTURE_OPENGL_TEXTURE_TARGET_NUMBER`: the GLenum for the
///   texture target (`GL_TEXTURE_2D`, `GL_TEXTURE_RECTANGLE_ARB`, etc)
/// - `SDL_PROP_TEXTURE_OPENGL_TEX_W_FLOAT`: the texture coordinate width of
///   the texture (0.0 - 1.0)
/// - `SDL_PROP_TEXTURE_OPENGL_TEX_H_FLOAT`: the texture coordinate height of
///   the texture (0.0 - 1.0)
///
/// With the opengles2 renderer:
///
/// - `SDL_PROP_TEXTURE_OPENGLES2_TEXTURE_NUMBER`: the GLuint texture
///   associated with the texture
/// - `SDL_PROP_TEXTURE_OPENGLES2_TEXTURE_UV_NUMBER`: the GLuint texture
///   associated with the UV plane of an NV12 texture
/// - `SDL_PROP_TEXTURE_OPENGLES2_TEXTURE_U_NUMBER`: the GLuint texture
///   associated with the U plane of a YUV texture
/// - `SDL_PROP_TEXTURE_OPENGLES2_TEXTURE_V_NUMBER`: the GLuint texture
///   associated with the V plane of a YUV texture
/// - `SDL_PROP_TEXTURE_OPENGLES2_TEXTURE_TARGET_NUMBER`: the GLenum for the
///   texture target (`GL_TEXTURE_2D`, `GL_TEXTURE_EXTERNAL_OES`, etc)
///
/// @param texture the texture to query.
/// @return a valid property ID on success or 0 on failure; call
///          SDL_GetError() for more information.
///
/// @threadsafety It is safe to call this function from any thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// ```c
/// extern SDL_DECLSPEC SDL_PropertiesID SDLCALL SDL_GetTextureProperties(SDL_Texture *texture);
/// ```
pub extern "C" fn sdl_GetTextureProperties(
  texture : SDL_Texture,
) -> SDL_PropertiesID = "SDL_GetTextureProperties"

///|
pub const SDL_PROP_TEXTURE_COLORSPACE_NUMBER = "SDL.texture.colorspace"

///|
pub const SDL_PROP_TEXTURE_FORMAT_NUMBER = "SDL.texture.format"

///|
pub const SDL_PROP_TEXTURE_ACCESS_NUMBER = "SDL.texture.access"

///|
pub const SDL_PROP_TEXTURE_WIDTH_NUMBER = "SDL.texture.width"

///|
pub const SDL_PROP_TEXTURE_HEIGHT_NUMBER = "SDL.texture.height"

///|
pub const SDL_PROP_TEXTURE_SDR_WHITE_POINT_FLOAT = "SDL.texture.SDR_white_point"

///|
pub const SDL_PROP_TEXTURE_HDR_HEADROOM_FLOAT = "SDL.texture.HDR_headroom"

///|
pub const SDL_PROP_TEXTURE_D3D11_TEXTURE_POINTER = "SDL.texture.d3d11.texture"

///|
pub const SDL_PROP_TEXTURE_D3D11_TEXTURE_U_POINTER = "SDL.texture.d3d11.texture_u"

///|
pub const SDL_PROP_TEXTURE_D3D11_TEXTURE_V_POINTER = "SDL.texture.d3d11.texture_v"

///|
pub const SDL_PROP_TEXTURE_D3D12_TEXTURE_POINTER = "SDL.texture.d3d12.texture"

///|
pub const SDL_PROP_TEXTURE_D3D12_TEXTURE_U_POINTER = "SDL.texture.d3d12.texture_u"

///|
pub const SDL_PROP_TEXTURE_D3D12_TEXTURE_V_POINTER = "SDL.texture.d3d12.texture_v"

///|
pub const SDL_PROP_TEXTURE_OPENGL_TEXTURE_NUMBER = "SDL.texture.opengl.texture"

///|
pub const SDL_PROP_TEXTURE_OPENGL_TEXTURE_UV_NUMBER = "SDL.texture.opengl.texture_uv"

///|
pub const SDL_PROP_TEXTURE_OPENGL_TEXTURE_U_NUMBER = "SDL.texture.opengl.texture_u"

///|
pub const SDL_PROP_TEXTURE_OPENGL_TEXTURE_V_NUMBER = "SDL.texture.opengl.texture_v"

///|
pub const SDL_PROP_TEXTURE_OPENGL_TEXTURE_TARGET_NUMBER = "SDL.texture.opengl.target"

///|
pub const SDL_PROP_TEXTURE_OPENGL_TEX_W_FLOAT = "SDL.texture.opengl.tex_w"

///|
pub const SDL_PROP_TEXTURE_OPENGL_TEX_H_FLOAT = "SDL.texture.opengl.tex_h"

///|
pub const SDL_PROP_TEXTURE_OPENGLES2_TEXTURE_NUMBER = "SDL.texture.opengles2.texture"

///|
pub const SDL_PROP_TEXTURE_OPENGLES2_TEXTURE_UV_NUMBER = "SDL.texture.opengles2.texture_uv"

///|
pub const SDL_PROP_TEXTURE_OPENGLES2_TEXTURE_U_NUMBER = "SDL.texture.opengles2.texture_u"

///|
pub const SDL_PROP_TEXTURE_OPENGLES2_TEXTURE_V_NUMBER = "SDL.texture.opengles2.texture_v"

///|
pub const SDL_PROP_TEXTURE_OPENGLES2_TEXTURE_TARGET_NUMBER = "SDL.texture.opengles2.target"

///|
pub const SDL_PROP_TEXTURE_VULKAN_TEXTURE_NUMBER = "SDL.texture.vulkan.texture"

///|
/// Get the renderer that created an SDL_Texture.
///
/// @param texture the texture to query.
/// @return a pointer to the SDL_Renderer that created the texture, or NULL on
///          failure; call SDL_GetError() for more information.
///
/// @threadsafety It is safe to call this function from any thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// ```c
/// extern SDL_DECLSPEC SDL_Renderer * SDLCALL SDL_GetRendererFromTexture(SDL_Texture *texture);
/// ```
pub extern "C" fn sdl_GetRendererFromTexture(
  texture : SDL_Texture,
) -> SDL_Renderer = "SDL_GetRendererFromTexture"

///|
/// Get the size of a texture, as floating point values.
///
/// @param texture the texture to query.
/// @param w a pointer filled in with the width of the texture in pixels. This
///          argument can be NULL if you don't need this information.
/// @param h a pointer filled in with the height of the texture in pixels. This
///          argument can be NULL if you don't need this information.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetTextureSize(SDL_Texture *texture, float *w, float *h);
/// ```
#owned(w, h)
pub extern "C" fn sdl_GetTextureSize(
  texture : SDL_Texture,
  w : FixedArray[Float],
  h : FixedArray[Float],
) -> Bool = "SDL_GetTextureSize"

///|
/// Set an additional color value multiplied into render copy operations.
///
/// When this texture is rendered, during the copy operation each source color
/// channel is modulated by the appropriate color value according to the
/// following formula:
///
/// `srcC = srcC * (color / 255)`
///
/// Color modulation is not always supported by the renderer; it will return
/// false if color modulation is not supported.
///
/// @param texture the texture to update.
/// @param r the red color value multiplied into copy operations.
/// @param g the green color value multiplied into copy operations.
/// @param b the blue color value multiplied into copy operations.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetTextureColorMod
/// @see SDL_SetTextureAlphaMod
/// @see SDL_SetTextureColorModFloat
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetTextureColorMod(SDL_Texture *texture, Uint8 r, Uint8 g, Uint8 b);
/// ```
pub extern "C" fn sdl_SetTextureColorMod(
  texture : SDL_Texture,
  r : Byte,
  g : Byte,
  b : Byte,
) -> Bool = "SDL_SetTextureColorMod"

///|
/// Set an additional color value multiplied into render copy operations.
///
/// When this texture is rendered, during the copy operation each source color
/// channel is modulated by the appropriate color value according to the
/// following formula:
///
/// `srcC = srcC * color`
///
/// Color modulation is not always supported by the renderer; it will return
/// false if color modulation is not supported.
///
/// @param texture the texture to update.
/// @param r the red color value multiplied into copy operations.
/// @param g the green color value multiplied into copy operations.
/// @param b the blue color value multiplied into copy operations.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetTextureColorModFloat
/// @see SDL_SetTextureAlphaModFloat
/// @see SDL_SetTextureColorMod
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetTextureColorModFloat(SDL_Texture *texture, float r, float g, float b);
/// ```
pub extern "C" fn sdl_SetTextureColorModFloat(
  texture : SDL_Texture,
  r : Float,
  g : Float,
  b : Float,
) -> Bool = "SDL_SetTextureColorModFloat"

///|
/// Get the additional color value multiplied into render copy operations.
///
/// @param texture the texture to query.
/// @param r a pointer filled in with the current red color value.
/// @param g a pointer filled in with the current green color value.
/// @param b a pointer filled in with the current blue color value.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetTextureAlphaMod
/// @see SDL_GetTextureColorModFloat
/// @see SDL_SetTextureColorMod
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetTextureColorMod(SDL_Texture *texture, Uint8 *r, Uint8 *g, Uint8 *b);
/// ```
#owned(r, g, b)
pub extern "C" fn sdl_GetTextureColorMod(
  texture : SDL_Texture,
  r : Bytes,
  g : Bytes,
  b : Bytes,
) -> Bool = "SDL_GetTextureColorMod"

///|
/// Get the additional color value multiplied into render copy operations.
///
/// @param texture the texture to query.
/// @param r a pointer filled in with the current red color value.
/// @param g a pointer filled in with the current green color value.
/// @param b a pointer filled in with the current blue color value.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetTextureAlphaModFloat
/// @see SDL_GetTextureColorMod
/// @see SDL_SetTextureColorModFloat
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetTextureColorModFloat(SDL_Texture *texture, float *r, float *g, float *b);
/// ```
#owned(r, g, b)
pub extern "C" fn sdl_GetTextureColorModFloat(
  texture : SDL_Texture,
  r : FixedArray[Float],
  g : FixedArray[Float],
  b : FixedArray[Float],
) -> Bool = "SDL_GetTextureColorModFloat"

///|
/// Set an additional alpha value multiplied into render copy operations.
///
/// When this texture is rendered, during the copy operation the source alpha
/// value is modulated by this alpha value according to the following formula:
///
/// `srcA = srcA * (alpha / 255)`
///
/// Alpha modulation is not always supported by the renderer; it will return
/// false if alpha modulation is not supported.
///
/// @param texture the texture to update.
/// @param alpha the source alpha value multiplied into copy operations.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetTextureAlphaMod
/// @see SDL_SetTextureAlphaModFloat
/// @see SDL_SetTextureColorMod
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetTextureAlphaMod(SDL_Texture *texture, Uint8 alpha);
/// ```
pub extern "C" fn sdl_SetTextureAlphaMod(
  texture : SDL_Texture,
  alpha : Byte,
) -> Bool = "SDL_SetTextureAlphaMod"

///|
/// Set an additional alpha value multiplied into render copy operations.
///
/// When this texture is rendered, during the copy operation the source alpha
/// value is modulated by this alpha value according to the following formula:
///
/// `srcA = srcA * alpha`
///
/// Alpha modulation is not always supported by the renderer; it will return
/// false if alpha modulation is not supported.
///
/// @param texture the texture to update.
/// @param alpha the source alpha value multiplied into copy operations.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetTextureAlphaModFloat
/// @see SDL_SetTextureAlphaMod
/// @see SDL_SetTextureColorModFloat
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetTextureAlphaModFloat(SDL_Texture *texture, float alpha);
/// ```
pub extern "C" fn sdl_SetTextureAlphaModFloat(
  texture : SDL_Texture,
  alpha : Float,
) -> Bool = "SDL_SetTextureAlphaModFloat"

///|
/// Get the additional alpha value multiplied into render copy operations.
///
/// @param texture the texture to query.
/// @param alpha a pointer filled in with the current alpha value.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetTextureAlphaModFloat
/// @see SDL_GetTextureColorMod
/// @see SDL_SetTextureAlphaMod
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetTextureAlphaMod(SDL_Texture *texture, Uint8 *alpha);
/// ```
#owned(alpha)
pub extern "C" fn sdl_GetTextureAlphaMod(
  texture : SDL_Texture,
  alpha : Bytes,
) -> Bool = "SDL_GetTextureAlphaMod"

///|
/// Get the additional alpha value multiplied into render copy operations.
///
/// @param texture the texture to query.
/// @param alpha a pointer filled in with the current alpha value.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetTextureAlphaMod
/// @see SDL_GetTextureColorModFloat
/// @see SDL_SetTextureAlphaModFloat
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetTextureAlphaModFloat(SDL_Texture *texture, float *alpha);
/// ```
#owned(alpha)
pub extern "C" fn sdl_GetTextureAlphaModFloat(
  texture : SDL_Texture,
  alpha : FixedArray[Float],
) -> Bool = "SDL_GetTextureAlphaModFloat"

///|
/// Set the blend mode for a texture, used by SDL_RenderTexture().
///
/// If the blend mode is not supported, the closest supported mode is chosen
/// and this function returns false.
///
/// @param texture the texture to update.
/// @param blendMode the SDL_BlendMode to use for texture blending.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetTextureBlendMode
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetTextureBlendMode(SDL_Texture *texture, SDL_BlendMode blendMode);
/// ```
pub extern "C" fn sdl_SetTextureBlendMode(
  texture : SDL_Texture,
  blendMode : SDL_BlendMode,
) -> Bool = "SDL_SetTextureBlendMode"

///|
/// Get the blend mode used for texture copy operations.
///
/// @param texture the texture to query.
/// @param blendMode a pointer filled in with the current SDL_BlendMode.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_SetTextureBlendMode
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetTextureBlendMode(SDL_Texture *texture, SDL_BlendMode *blendMode);
/// ```
#owned(blendMode)
pub extern "C" fn sdl_GetTextureBlendMode(
  texture : SDL_Texture,
  blendMode : FixedArray[SDL_BlendMode],
) -> Bool = "SDL_GetTextureBlendMode"

///|
/// Set the scale mode used for texture scale operations.
///
/// The default texture scale mode is SDL_SCALEMODE_LINEAR.
///
/// If the scale mode is not supported, the closest supported mode is chosen.
///
/// @param texture the texture to update.
/// @param scaleMode the SDL_ScaleMode to use for texture scaling.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetTextureScaleMode
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetTextureScaleMode(SDL_Texture *texture, SDL_ScaleMode scaleMode);
/// ```
pub extern "C" fn sdl_SetTextureScaleMode(
  texture : SDL_Texture,
  scaleMode : SDL_ScaleMode,
) -> Bool = "SDL_SetTextureScaleMode"

///|
/// Get the scale mode used for texture scale operations.
///
/// @param texture the texture to query.
/// @param scaleMode a pointer filled in with the current scale mode.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_SetTextureScaleMode
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetTextureScaleMode(SDL_Texture *texture, SDL_ScaleMode *scaleMode);
/// ```
#owned(scaleMode)
pub extern "C" fn sdl_GetTextureScaleMode(
  texture : SDL_Texture,
  scaleMode : FixedArray[SDL_ScaleMode],
) -> Bool = "SDL_GetTextureScaleMode"

///|
/// Update the given texture rectangle with new pixel data.
///
/// The pixel data must be in the pixel format of the texture, which can be
/// queried using the SDL_PROP_TEXTURE_FORMAT_NUMBER property.
///
/// This is a fairly slow function, intended for use with static textures that
/// do not change often.
///
/// If the texture is intended to be updated often, it is preferred to create
/// the texture as streaming and use the locking functions referenced below.
/// While this function will work with streaming textures, for optimization
/// reasons you may not get the pixels back if you lock the texture afterward.
///
/// @param texture the texture to update.
/// @param rect an SDL_Rect structure representing the area to update, or NULL
///             to update the entire texture.
/// @param pixels the raw pixel data in the format of the texture.
/// @param pitch the number of bytes in a row of pixel data, including padding
///              between lines.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_LockTexture
/// @see SDL_UnlockTexture
/// @see SDL_UpdateNVTexture
/// @see SDL_UpdateYUVTexture
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_UpdateTexture(SDL_Texture *texture, const SDL_Rect *rect, const void *pixels, int pitch);
/// ```
#owned(rect)
pub extern "C" fn sdl_UpdateTexture(
  texture : SDL_Texture,
  rect : SDL_Rect,
  pixels : VoidPtr,
  pitch : Int,
) -> Bool = "SDL_UpdateTexture"

///| Update a rectangle within a planar YV12 or IYUV texture with new pixel

///|
/// data.
///
/// You can use SDL_UpdateTexture() as long as your pixel data is a contiguous
/// block of Y and U/V planes in the proper order, but this function is
/// available if your pixel data is not contiguous.
///
/// @param texture the texture to update.
/// @param rect a pointer to the rectangle of pixels to update, or NULL to
///             update the entire texture.
/// @param Yplane the raw pixel data for the Y plane.
/// @param Ypitch the number of bytes between rows of pixel data for the Y
///               plane.
/// @param Uplane the raw pixel data for the U plane.
/// @param Upitch the number of bytes between rows of pixel data for the U
///               plane.
/// @param Vplane the raw pixel data for the V plane.
/// @param Vpitch the number of bytes between rows of pixel data for the V
///               plane.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_UpdateNVTexture
/// @see SDL_UpdateTexture
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_UpdateYUVTexture(SDL_Texture *texture,
///                                                 const SDL_Rect *rect,
///                                                 const Uint8 *Yplane, int Ypitch,
///                                                 const Uint8 *Uplane, int Upitch,
///                                                 const Uint8 *Vplane, int Vpitch);
/// ```
#owned(rect, yplane, uplane, vplane)
pub extern "C" fn sdl_UpdateYUVTexture(
  texture : SDL_Texture,
  rect : SDL_Rect,
  yplane : FixedArray[Byte],
  ypitch : Int,
  uplane : FixedArray[Byte],
  upitch : Int,
  vplane : FixedArray[Byte],
  vpitch : Int,
) -> Bool = "SDL_UpdateYUVTexture"
