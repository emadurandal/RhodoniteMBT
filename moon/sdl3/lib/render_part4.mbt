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
/// Get the color scale used for render operations.
///
/// @param renderer the rendering context.
/// @param scale a pointer filled in with the current color scale value.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_SetRenderColorScale
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetRenderColorScale(SDL_Renderer *renderer, float *scale);
/// ```
#owned(scale)
pub extern "C" fn sdl_GetRenderColorScale(
  renderer : SDL_Renderer,
  scale : FixedArray[Float],
) -> Bool = "SDL_GetRenderColorScale"

///|
/// Set the blend mode used for drawing operations (Fill and Line).
///
/// If the blend mode is not supported, the closest supported mode is chosen.
///
/// @param renderer the rendering context.
/// @param blendMode the SDL_BlendMode to use for blending.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetRenderDrawBlendMode
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetRenderDrawBlendMode(SDL_Renderer *renderer, SDL_BlendMode blendMode);
/// ```
pub extern "C" fn sdl_SetRenderDrawBlendMode(
  renderer : SDL_Renderer,
  blendMode : SDL_BlendMode,
) -> Bool = "SDL_SetRenderDrawBlendMode"

///|
/// Get the blend mode used for drawing operations.
///
/// @param renderer the rendering context.
/// @param blendMode a pointer filled in with the current SDL_BlendMode.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_SetRenderDrawBlendMode
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetRenderDrawBlendMode(SDL_Renderer *renderer, SDL_BlendMode *blendMode);
/// ```
#owned(blendMode)
pub extern "C" fn sdl_GetRenderDrawBlendMode(
  renderer : SDL_Renderer,
  blendMode : FixedArray[SDL_BlendMode],
) -> Bool = "SDL_GetRenderDrawBlendMode"

///|
/// Clear the current rendering target with the drawing color.
///
/// This function clears the entire rendering target, ignoring the viewport and
/// the clip rectangle. Note, that clearing will also set/fill all pixels of
/// the rendering target to current renderer draw color, so make sure to invoke
/// SDL_SetRenderDrawColor() when needed.
///
/// @param renderer the rendering context.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_SetRenderDrawColor
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderClear(SDL_Renderer *renderer);
/// ```
pub extern "C" fn sdl_RenderClear(renderer : SDL_Renderer) -> Bool = "SDL_RenderClear"

///|
/// Draw a point on the current rendering target.
///
/// @param renderer the rendering context.
/// @param x the x coordinate of the point.
/// @param y the y coordinate of the point.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_RenderPoints
/// @see SDL_SetRenderDrawColor
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderPoint(SDL_Renderer *renderer, float x, float y);
/// ```
pub extern "C" fn sdl_RenderPoint(
  renderer : SDL_Renderer,
  x : Float,
  y : Float,
) -> Bool = "SDL_RenderPoint"

///|
/// Draw multiple points on the current rendering target.
///
/// @param renderer the rendering context.
/// @param points the points to draw.
/// @param count the number of points to draw.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_RenderPoint
/// @see SDL_SetRenderDrawColor
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderPoints(SDL_Renderer *renderer, const SDL_FPoint *points, int count);
/// ```
/// Note: the type of points `FixedArray[Float]` is correct, because SDL_FPoint is { Float, Float }
#owned(points)
pub extern "C" fn sdl_RenderPoints(
  renderer : SDL_Renderer,
  points : FixedArray[Float],
  count : Int,
) -> Bool = "SDL_RenderPoints"

///|
/// Draw a line on the current rendering target.
///
/// @param renderer the rendering context.
/// @param x1 the x coordinate of the start point.
/// @param y1 the y coordinate of the start point.
/// @param x2 the x coordinate of the end point.
/// @param y2 the y coordinate of the end point.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_RenderLines
/// @see SDL_SetRenderDrawColor
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderLine(SDL_Renderer *renderer, float x1, float y1, float x2, float y2);
/// ```
pub extern "C" fn sdl_RenderLine(
  renderer : SDL_Renderer,
  x1 : Float,
  y1 : Float,
  x2 : Float,
  y2 : Float,
) -> Bool = "SDL_RenderLine"

///|
/// Draw a series of connected lines on the current rendering target.
///
/// @param renderer the rendering context.
/// @param points the points along the lines.
/// @param count the number of points, drawing count-1 lines.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_RenderLine
/// @see SDL_SetRenderDrawColor
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderLines(SDL_Renderer *renderer, const SDL_FPoint *points, int count);
/// ```
/// Note: the type of points `FixedArray[Float]` is correct, because SDL_FPoint is { Float, Float }
#owned(points)
pub extern "C" fn sdl_RenderLines(
  renderer : SDL_Renderer,
  points : FixedArray[Float],
  count : Int,
) -> Bool = "SDL_RenderLines"

///|
/// Draw a rectangle on the current rendering target.
///
/// @param renderer the rendering context.
/// @param rect a pointer to the destination rectangle, or NULL to outline the
///             entire rendering target.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_RenderRects
/// @see SDL_SetRenderDrawColor
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderRect(SDL_Renderer *renderer, const SDL_FRect *rect);
/// ```
#owned(rect)
pub extern "C" fn sdl_RenderRect(
  renderer : SDL_Renderer,
  rect : SDL_FRect,
) -> Bool = "SDL_RenderRect"

///|
/// Draw some number of rectangles on the current rendering target.
///
/// @param renderer the rendering context.
/// @param rects a pointer to an array of destination rectangles.
/// @param count the number of rectangles.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_RenderRect
/// @see SDL_SetRenderDrawColor
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderRects(SDL_Renderer *renderer, const SDL_FRect *rects, int count);
/// ```
/// Note: the type of rects `FixedArray[Float]` is correct, because SDL_FRect is { Float, Float, Float, Float }
#owned(rects)
pub extern "C" fn sdl_RenderRects(
  renderer : SDL_Renderer,
  rects : FixedArray[Float],
  count : Int,
) -> Bool = "SDL_RenderRects"

///|
/// Fill a rectangle on the current rendering target with the drawing color.
///
/// @param renderer the rendering context.
/// @param rect a pointer to the destination rectangle, or NULL for the entire
///             rendering target.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_RenderFillRects
/// @see SDL_SetRenderDrawColor
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderFillRect(SDL_Renderer *renderer, const SDL_FRect *rect);
/// ```
#owned(rect)
pub extern "C" fn sdl_RenderFillRect(
  renderer : SDL_Renderer,
  rect : SDL_FRect,
) -> Bool = "SDL_RenderFillRect"

///| Fill some number of rectangles on the current rendering target with the

///|
/// drawing color.
///
/// @param renderer the rendering context.
/// @param rects a pointer to an array of destination rectangles.
/// @param count the number of rectangles.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_RenderFillRect
/// @see SDL_SetRenderDrawColor
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderFillRects(SDL_Renderer *renderer, const SDL_FRect *rects, int count);
/// ```
/// Note: the type of rects `FixedArray[Float]` is correct, because SDL_FRect is { Float, Float, Float, Float }
#owned(rects)
pub extern "C" fn sdl_RenderFillRects(
  renderer : SDL_Renderer,
  rects : FixedArray[Float],
  count : Int,
) -> Bool = "SDL_RenderFillRects"

///|
/// Copy a portion of the texture to the current rendering target.
///
/// @param renderer the rendering context.
/// @param texture the source texture.
/// @param srcrect a pointer to the source rectangle, or NULL for the entire
///                texture.
/// @param dstrect a pointer to the destination rectangle, or NULL for the
///                entire rendering target.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_RenderTextureRotated
/// @see SDL_SetTextureAlphaMod
/// @see SDL_SetTextureBlendMode
/// @see SDL_SetTextureColorMod
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderTexture(SDL_Renderer *renderer, SDL_Texture *texture, const SDL_FRect *srcrect, const SDL_FRect *dstrect);
/// ```
#owned(srcrect, dstrect)
pub extern "C" fn sdl_RenderTexture(
  renderer : SDL_Renderer,
  texture : SDL_Texture,
  srcrect : SDL_FRect,
  dstrect : SDL_FRect,
) -> Bool = "SDL_RenderTexture"

///| Copy a portion of the texture to the current rendering target, optionally

///| rotating it by angle around the given center and also flipping it top-bottom

///|
/// and/or left-right.
///
/// @param renderer the rendering context.
/// @param texture the source texture.
/// @param srcrect a pointer to the source rectangle, or NULL for the entire
///                texture.
/// @param dstrect a pointer to the destination rectangle, or NULL for the
///                entire rendering target.
/// @param angle an angle in degrees that indicates the rotation that will be
///              applied to dstrect, rotating it in a clockwise direction.
/// @param center a pointer to a point indicating the point around which
///               dstrect will be rotated (if NULL, rotation will be done
///               around `dstrect.w / 2`, `dstrect.h / 2`).
/// @param flip a SDL_FlipMode value stating which flipping operations should
///             be performed on the texture.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_RenderTexture
/// @see SDL_SetTextureAlphaMod
/// @see SDL_SetTextureBlendMode
/// @see SDL_SetTextureColorMod
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderTextureRotated(SDL_Renderer *renderer, SDL_Texture *texture, const SDL_FRect *srcrect, const SDL_FRect *dstrect, const double angle, const SDL_FPoint *center, const SDL_FlipMode flip);
/// ```
#owned(srcrect, dstrect, center)
pub extern "C" fn sdl_RenderTextureRotated(
  renderer : SDL_Renderer,
  texture : SDL_Texture,
  srcrect : SDL_FRect,
  dstrect : SDL_FRect,
  angle : Double,
  center : SDL_FPoint,
  flip : SDL_FlipMode,
) -> Bool = "SDL_RenderTextureRotated"

///|
/// Render a list of triangles, optionally using a texture and indices into the vertex array.
///
/// @param renderer the rendering context.
/// @param texture a pointer to the texture to apply to the geometry, or NULL
///                if no texture is required.
/// @param vertices a pointer to an array of vertices.
/// @param num_vertices the number of vertices in the `vertices` array.
/// @param indices a pointer to an array of indices into the `vertices` array,
///                or NULL if the vertices are to be rendered in order.
/// @param num_indices the number of indices in the `indices` array, or 0 if
///                    `indices` is NULL.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderGeometry(SDL_Renderer *renderer,
///                                                     SDL_Texture *texture,
///                                                     const SDL_Vertex *vertices, int num_vertices,
///                                                     const int *indices, int num_indices);
/// ```
#owned(vertices, indices)
pub extern "C" fn sdl_RenderGeometry(
  renderer : SDL_Renderer,
  texture : SDL_Texture,
  vertices : FixedArray[Float],
  num_vertices : Int,
  indices : FixedArray[Int],
  num_indices : Int,
) -> Bool = "SDL_RenderGeometry"

///|
/// Render a list of triangles.
///
/// Render a list of triangles, optionally using a texture and indices into the
/// vertex array. This is the same as SDL_RenderGeometry(), but with floating
/// point precision.
///
/// @param renderer the rendering context.
/// @param texture a pointer to the texture to apply to the geometry, or NULL
///                if no texture is required.
/// @param vertices a pointer to an array of vertices.
/// @param num_vertices the number of vertices in the `vertices` array.
/// @param indices a pointer to an array of indices into the `vertices` array,
///                or NULL if the vertices are to be rendered in order.
/// @param num_indices the number of indices in the `indices` array, or 0 if
///                    `indices` is NULL.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderGeometryRaw(SDL_Renderer *renderer,
///                                                   SDL_Texture *texture,
///                                                   const float *xy, int xy_stride,
///                                                   const SDL_FColor *color, int color_stride,
///                                                   const float *uv, int uv_stride,
///                                                   int num_vertices,
///                                                   const void *indices, int num_indices, int size_indices);
/// ```
#owned(xy, color, uv)
pub extern "C" fn sdl_RenderGeometryRaw(
  renderer : SDL_Renderer,
  texture : SDL_Texture,
  xy : FixedArray[Float],
  xy_stride : Int,
  color : SDL_FColor,
  color_stride : Int,
  uv : FixedArray[Float],
  uv_stride : Int,
  num_vertices : Int,
  indices : VoidPtr,
  num_indices : Int,
  size_indices : Int,
) -> Bool = "SDL_RenderGeometryRaw"

///|
/// Update the screen with rendering performed.
///
/// SDL's rendering functions operate on a backbuffer; that is, calling a
/// rendering function such as SDL_RenderLine() does not directly put a line
/// on the screen, but rather updates the backbuffer. As such, you compose
/// your entire scene and then present the backbuffer to the screen as a
/// single operation.
///
/// A renderer may be automatically presented in the event loop, but may also
/// need to be manually presented with this function. You should check the
/// `SDL_PROP_WINDOW_CREATE_RENDERER_PRESENT_NUMBER` hint for details.
///
/// @param renderer the rendering context
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_CreateRenderer
/// @see SDL_DestroyRenderer
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderPresent(SDL_Renderer *renderer);
/// ```
pub extern "C" fn sdl_RenderPresent(renderer : SDL_Renderer) -> Bool = "SDL_RenderPresent"

///|
/// Destroy the specified texture.
///
/// @param texture the texture to destroy.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_CreateTexture
/// @see SDL_CreateTextureFromSurface
/// @see SDL_CreateTextureWithProperties
///
/// ```c
/// extern SDL_DECLSPEC void SDLCALL SDL_DestroyTexture(SDL_Texture *texture);
/// ```
pub extern "C" fn sdl_DestroyTexture(texture : SDL_Texture) -> Unit = "SDL_DestroyTexture"

///|
/// Destroy the rendering context for a window and free associated textures.
///
/// @param renderer the rendering context
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_CreateRenderer
///
/// ```c
/// extern SDL_DECLSPEC void SDLCALL SDL_DestroyRenderer(SDL_Renderer *renderer);
/// ```
pub extern "C" fn sdl_DestroyRenderer(renderer : SDL_Renderer) -> Unit = "SDL_DestroyRenderer"

///|
/// Force the rendering context to flush any pending commands to the device.
///
/// You don't normally need to call this function unless you are planning to
/// escape the SDL render API and render either pure OpenGl / Direct3D or
/// another library on top of an SDL window.
///
/// This function is not thread safe and should only be called from the main
/// thread.
///
/// @param renderer the rendering context
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderFlush(SDL_Renderer *renderer);
/// ```
pub extern "C" fn sdl_RenderFlush(renderer : SDL_Renderer) -> Bool = "SDL_RenderFlush"

///|
/// Set the VSync setting for a renderer.
///
/// @param renderer the renderer to modify.
/// @param vsync `1` to enable VSync, `0` to disable it, and `-1` for adaptive
///              VSync.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetRenderVSync
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetRenderVSync(SDL_Renderer *renderer, int vsync);
/// ```
pub extern "C" fn sdl_SetRenderVSync(
  renderer : SDL_Renderer,
  vsync : Int,
) -> Bool = "SDL_SetRenderVSync"

///|
/// Get the VSync setting for a renderer.
///
/// @param renderer the renderer to query.
/// @param vsync a pointer filled with the VSync setting; `1` if VSync is
///              enabled, `0` if it's disabled, and `-1` if adaptive VSync is
///              enabled.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_SetRenderVSync
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetRenderVSync(SDL_Renderer *renderer, int *vsync);
/// ```
#owned(vsync)
pub extern "C" fn sdl_GetRenderVSync(
  renderer : SDL_Renderer,
  vsync : Ref[Int],
) -> Bool = "SDL_GetRenderVSync"
