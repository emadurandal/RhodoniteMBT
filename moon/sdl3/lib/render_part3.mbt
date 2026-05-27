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
/// Update a rectangle within a planar NV12 or NV21 texture with new pixels.
///
/// You can use SDL_UpdateTexture() as long as your pixel data is a contiguous
/// block of NV12/21 planes in the proper order, but this function is available
/// if your pixel data is not contiguous.
///
/// @param texture the texture to update.
/// @param rect a pointer to the rectangle of pixels to update, or NULL to
///             update the entire texture.
/// @param Yplane the raw pixel data for the Y plane.
/// @param Ypitch the number of bytes between rows of pixel data for the Y
///               plane.
/// @param UVplane the raw pixel data for the UV plane.
/// @param UVpitch the number of bytes between rows of pixel data for the UV
///                plane.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_UpdateTexture
/// @see SDL_UpdateYUVTexture
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_UpdateNVTexture(SDL_Texture *texture,
///                                                 const SDL_Rect *rect,
///                                                 const Uint8 *Yplane, int Ypitch,
///                                                 const Uint8 *UVplane, int UVpitch);
/// ```
#owned(rect, yplane, uVplane)
pub extern "C" fn sdl_UpdateNVTexture(
  texture : SDL_Texture,
  rect : SDL_Rect,
  yplane : FixedArray[Byte],
  ypitch : Int,
  uVplane : FixedArray[Byte],
  uVpitch : Int,
) -> Bool = "SDL_UpdateNVTexture"

///|
/// Lock a portion of the texture for **write-only** pixel access.
///
/// As an optimization, the pixels made available for editing don't necessarily
/// contain the old texture data. This is a write-only operation, and if you
/// need to keep a copy of the texture data you should do that at the
/// application level.
///
/// You must use SDL_UnlockTexture() to unlock the pixels and apply any
/// changes.
///
/// @param texture the texture to lock for access, which was created with
///                `SDL_TEXTUREACCESS_STREAMING`.
/// @param rect an SDL_Rect structure representing the area to lock for access;
///             NULL to lock the entire texture.
/// @param pixels this is filled in with a pointer to the locked pixels,
///               appropriately offset by the locked area.
/// @param pitch this is filled in with the pitch of the locked pixels; the
///              pitch is the length of one row in bytes.
/// @return true on success or false if the texture is not valid or was not
///          created with `SDL_TEXTUREACCESS_STREAMING`; call SDL_GetError()
///          for more information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_LockTextureToSurface
/// @see SDL_UnlockTexture
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_LockTexture(SDL_Texture *texture,
///                                            const SDL_Rect *rect,
///                                            void **pixels, int *pitch);
/// ```
#owned(rect, pixels, pitch)
pub extern "C" fn sdl_LockTexture(
  texture : SDL_Texture,
  rect : SDL_Rect,
  pixels : FixedArray[VoidPtr],
  pitch : FixedArray[Int],
) -> Bool = "SDL_LockTexture"

///| Lock a portion of the texture for **write-only** pixel access, and expose

///|
/// it as a SDL surface.
///
/// Besides providing an SDL_Surface instead of raw pixel data, this function
/// operates like SDL_LockTexture.
///
/// As an optimization, the pixels made available for editing don't necessarily
/// contain the old texture data. This is a write-only operation, and if you
/// need to keep a copy of the texture data you should do that at the
/// application level.
///
/// You must use SDL_UnlockTexture() to unlock the pixels and apply any
/// changes.
///
/// The returned surface is freed internally after calling SDL_UnlockTexture()
/// or SDL_DestroyTexture(). The caller should not free it.
///
/// @param texture the texture to lock for access, which must be created with
///                `SDL_TEXTUREACCESS_STREAMING`.
/// @param rect a pointer to the rectangle to lock for access. If the rect is
///             NULL, the entire texture will be locked.
/// @param surface a pointer to an SDL surface of size **rect**. Don't assume
///                any specific pixel content.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_LockTexture
/// @see SDL_UnlockTexture
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_LockTextureToSurface(SDL_Texture *texture, const SDL_Rect *rect, SDL_Surface **surface);
/// ```
#owned(rect, surface)
pub extern "C" fn sdl_LockTextureToSurface(
  texture : SDL_Texture,
  rect : SDL_Rect,
  surface : FixedArray[SDL_Surface],
) -> Bool = "SDL_LockTextureToSurface"

///|
/// Unlock a texture, uploading the changes to video memory, if needed.
///
/// **Warning**: Please note that SDL_LockTexture() is intended to be
/// write-only; it will not guarantee the previous contents of the texture will
/// be provided. You must fully initialize any area of a texture that you lock
/// before unlocking it, as the pixels might otherwise be uninitialized memory.
///
/// Which is to say: locking and immediately unlocking a texture can result in
/// corrupted textures, depending on the renderer in use.
///
/// @param texture a texture locked by SDL_LockTexture().
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_LockTexture
///
/// ```c
/// extern SDL_DECLSPEC void SDLCALL SDL_UnlockTexture(SDL_Texture *texture);
/// ```
pub extern "C" fn sdl_UnlockTexture(texture : SDL_Texture) -> Unit = "SDL_UnlockTexture"

///|
/// Set a texture as the current rendering target.
///
/// The default render target is the window for which the renderer was created.
/// To stop rendering to a texture and render to the window again, call this
/// function with a NULL `texture`.
///
/// Viewport, cliprect, scale, and logical presentation are unique to each
/// render target. Get and set functions for these states apply to the current
/// render target set by this function, and those states persist on each target
/// when the current render target changes.
///
/// @param renderer the rendering context.
/// @param texture the targeted texture, which must be created with the
///                `SDL_TEXTUREACCESS_TARGET` flag, or NULL to render to the
///                window instead of a texture.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetRenderTarget
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetRenderTarget(SDL_Renderer *renderer, SDL_Texture *texture);
/// ```
pub extern "C" fn sdl_SetRenderTarget(
  renderer : SDL_Renderer,
  texture : SDL_Texture,
) -> Bool = "SDL_SetRenderTarget"

///|
/// Get the current render target.
///
/// The default render target is the window for which the renderer was created,
/// and is reported a NULL here.
///
/// @param renderer the rendering context.
/// @return the current render target or NULL for the default render target.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_SetRenderTarget
///
/// ```c
/// extern SDL_DECLSPEC SDL_Texture * SDLCALL SDL_GetRenderTarget(SDL_Renderer *renderer);
/// ```
pub extern "C" fn sdl_GetRenderTarget(renderer : SDL_Renderer) -> SDL_Texture = "SDL_GetRenderTarget"

///|
/// Set a device-independent resolution and presentation mode for rendering.
///
/// This function sets the width and height of the logical rendering output.
/// The renderer will act as if the current render target is always the
/// requested dimensions, scaling to the actual resolution as necessary.
///
/// This can be useful for games that expect a fixed size, but would like to
/// scale the output to whatever is available, regardless of how a user resizes
/// a window, or if the display is high DPI.
///
/// Logical presentation can be used with both render target textures and the
/// renderer's window; the state is unique to each render target, and this
/// function sets the state for the current render target. It might be useful
/// to draw to a texture that matches the window dimensions with logical
/// presentation enabled, and then draw that texture across the entire window
/// with logical presentation disabled. Be careful not to render both with
/// logical presentation enabled, however, as this could produce
/// double-letterboxing, etc.
///
/// You can disable logical coordinates by setting the mode to
/// SDL_LOGICAL_PRESENTATION_DISABLED, and in that case you get the full pixel
/// resolution of the render target; it is safe to toggle logical presentation
/// during the rendering of a frame: perhaps most of the rendering is done to
/// specific dimensions but to make fonts look sharp, the app turns off logical
/// presentation while drawing text, for example.
///
/// For the renderer's window, letterboxing is drawn into the framebuffer if
/// logical presentation is enabled during SDL_RenderPresent; be sure to
/// reenable it before presenting if you were toggling it, otherwise the
/// letterbox areas might have artifacts from previous frames (or artifacts
/// from external overlays, etc). Letterboxing is never drawn into texture
/// render targets; be sure to call SDL_RenderClear() before drawing into the
/// texture so the letterboxing areas are cleared, if appropriate.
///
/// You can convert coordinates in an event into rendering coordinates using
/// SDL_ConvertEventToRenderCoordinates().
///
/// @param renderer the rendering context.
/// @param w the width of the logical resolution.
/// @param h the height of the logical resolution.
/// @param mode the presentation mode used.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_ConvertEventToRenderCoordinates
/// @see SDL_GetRenderLogicalPresentation
/// @see SDL_GetRenderLogicalPresentationRect
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetRenderLogicalPresentation(SDL_Renderer *renderer, int w, int h, SDL_RendererLogicalPresentation mode);
/// ```
pub extern "C" fn sdl_SetRenderLogicalPresentation(
  renderer : SDL_Renderer,
  w : Int,
  h : Int,
  mode : SDL_RendererLogicalPresentation,
) -> Bool = "SDL_SetRenderLogicalPresentation"

///|
/// Get device independent resolution and presentation mode for rendering.
///
/// This function gets the width and height of the logical rendering output, or
/// the output size in pixels if a logical resolution is not enabled.
///
/// Each render target has its own logical presentation state. This function
/// gets the state for the current render target.
///
/// @param renderer the rendering context.
/// @param w an int to be filled with the width.
/// @param h an int to be filled with the height.
/// @param mode the presentation mode used.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_SetRenderLogicalPresentation
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetRenderLogicalPresentation(SDL_Renderer *renderer, int *w, int *h, SDL_RendererLogicalPresentation *mode);
/// ```
#owned(w, h, mode)
pub extern "C" fn sdl_GetRenderLogicalPresentation(
  renderer : SDL_Renderer,
  w : FixedArray[Int],
  h : FixedArray[Int],
  mode : FixedArray[SDL_RendererLogicalPresentation],
) -> Bool = "SDL_GetRenderLogicalPresentation"

///|
/// Get the final presentation rectangle for rendering.
///
/// This function returns the calculated rectangle used for logical
/// presentation, based on the presentation mode and output size. If logical
/// presentation is disabled, it will fill the rectangle with the output size,
/// in pixels.
///
/// Each render target has its own logical presentation state. This function
/// gets the rectangle for the current render target.
///
/// @param renderer the rendering context.
/// @param rect a pointer filled in with the final presentation rectangle, may
///             be NULL.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_SetRenderLogicalPresentation
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetRenderLogicalPresentationRect(SDL_Renderer *renderer, SDL_FRect *rect);
/// ```
#owned(rect)
pub extern "C" fn sdl_GetRenderLogicalPresentationRect(
  renderer : SDL_Renderer,
  rect : SDL_FRect,
) -> Bool = "SDL_GetRenderLogicalPresentationRect"

///|
/// Get a point in render coordinates when given a point in window coordinates.
///
/// This takes into account several states:
///
/// - The window dimensions.
/// - The logical presentation settings (SDL_SetRenderLogicalPresentation)
/// - The scale (SDL_SetRenderScale)
/// - The viewport (SDL_SetRenderViewport)
///
/// @param renderer the rendering context.
/// @param window_x the x coordinate in window coordinates.
/// @param window_y the y coordinate in window coordinates.
/// @param x a pointer filled with the x coordinate in render coordinates.
/// @param y a pointer filled with the y coordinate in render coordinates.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_SetRenderLogicalPresentation
/// @see SDL_SetRenderScale
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderCoordinatesFromWindow(SDL_Renderer *renderer, float window_x, float window_y, float *x, float *y);
/// ```
#owned(x, y)
pub extern "C" fn sdl_RenderCoordinatesFromWindow(
  renderer : SDL_Renderer,
  window_x : Float,
  window_y : Float,
  x : FixedArray[Float],
  y : FixedArray[Float],
) -> Bool = "SDL_RenderCoordinatesFromWindow"

///|
/// Get a point in window coordinates when given a point in render coordinates.
///
/// This takes into account several states:
///
/// - The window dimensions.
/// - The logical presentation settings (SDL_SetRenderLogicalPresentation)
/// - The scale (SDL_SetRenderScale)
/// - The viewport (SDL_SetRenderViewport)
///
/// @param renderer the rendering context.
/// @param x the x coordinate in render coordinates.
/// @param y the y coordinate in render coordinates.
/// @param window_x a pointer filled with the x coordinate in window
///                 coordinates.
/// @param window_y a pointer filled with the y coordinate in window
///                 coordinates.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_SetRenderLogicalPresentation
/// @see SDL_SetRenderScale
/// @see SDL_SetRenderViewport
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderCoordinatesToWindow(SDL_Renderer *renderer, float x, float y, float *window_x, float *window_y);
/// ```
#owned(window_x, window_y)
pub extern "C" fn sdl_RenderCoordinatesToWindow(
  renderer : SDL_Renderer,
  x : Float,
  y : Float,
  window_x : FixedArray[Float],
  window_y : FixedArray[Float],
) -> Bool = "SDL_RenderCoordinatesToWindow"

///|
/// Convert the coordinates in an event to render coordinates.
///
/// This takes into account several states:
///
/// - The window dimensions.
/// - The logical presentation settings (SDL_SetRenderLogicalPresentation)
/// - The scale (SDL_SetRenderScale)
/// - The viewport (SDL_SetRenderViewport)
///
/// Various event types are converted with this function: mouse, touch, pen,
/// etc.
///
/// Touch coordinates are converted from normalized coordinates in the window
/// to non-normalized rendering coordinates.
///
/// Relative mouse coordinates (xrel and yrel event fields) are _also_
/// converted. Applications that do not want these fields converted should use
/// SDL_RenderCoordinatesFromWindow() on the specific event fields instead of
/// converting the entire event structure.
///
/// Once converted, coordinates may be outside the rendering area.
///
/// @param renderer the rendering context.
/// @param event the event to modify.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_RenderCoordinatesFromWindow
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_ConvertEventToRenderCoordinates(SDL_Renderer *renderer, SDL_Event *event);
/// ```
#owned(event)
pub extern "C" fn sdl_ConvertEventToRenderCoordinates(
  renderer : SDL_Renderer,
  event : SDL_Event,
) -> Bool = "SDL_ConvertEventToRenderCoordinates"

///|
/// Set the drawing area for rendering on the current target.
///
/// Drawing will clip to this area (separately from any clipping done with
/// SDL_SetRenderClipRect), and the top left of the area will become coordinate
/// (0, 0) for future drawing commands.
///
/// The area's width and height must be >= 0.
///
/// Each render target has its own viewport. This function sets the viewport
/// for the current render target.
///
/// @param renderer the rendering context.
/// @param rect the SDL_Rect structure representing the drawing area, or NULL
///             to set the viewport to the entire target.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetRenderViewport
/// @see SDL_RenderViewportSet
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetRenderViewport(SDL_Renderer *renderer, const SDL_Rect *rect);
/// ```
#owned(rect)
pub extern "C" fn sdl_SetRenderViewport(
  renderer : SDL_Renderer,
  rect : SDL_Rect,
) -> Bool = "SDL_SetRenderViewport"

///|
/// Get the drawing area for the current target.
///
/// Each render target has its own viewport. This function gets the viewport
/// for the current render target.
///
/// @param renderer the rendering context.
/// @param rect an SDL_Rect structure filled in with the current drawing area.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_RenderViewportSet
/// @see SDL_SetRenderViewport
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetRenderViewport(SDL_Renderer *renderer, SDL_Rect *rect);
/// ```
#owned(rect)
pub extern "C" fn sdl_GetRenderViewport(
  renderer : SDL_Renderer,
  rect : SDL_Rect,
) -> Bool = "SDL_GetRenderViewport"

///|
/// Return whether an explicit rectangle was set as the viewport.
///
/// This is useful if you're saving and restoring the viewport and want to know
/// whether you should restore a specific rectangle or NULL.
///
/// Each render target has its own viewport. This function checks the viewport
/// for the current render target.
///
/// @param renderer the rendering context.
/// @return true if the viewport was set to a specific rectangle, or false if
///          it was set to NULL (the entire target).
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetRenderViewport
/// @see SDL_SetRenderViewport
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderViewportSet(SDL_Renderer *renderer);
/// ```
pub extern "C" fn sdl_RenderViewportSet(renderer : SDL_Renderer) -> Bool = "SDL_RenderViewportSet"

///|
/// Get the safe area for rendering within the current viewport.
///
/// Some devices have portions of the screen which are partially obscured or
/// not interactive, possibly due to on-screen controls, curved edges, camera
/// notches, TV overscan, etc. This function provides the area of the current
/// viewport which is safe to have interactible content. You should continue
/// rendering into the rest of the render target, but it should not contain
/// visually important or interactible content.
///
/// @param renderer the rendering context.
/// @param rect a pointer filled in with the area that is safe for interactive
///             content.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetRenderSafeArea(SDL_Renderer *renderer, SDL_Rect *rect);
/// ```
#owned(rect)
pub extern "C" fn sdl_GetRenderSafeArea(
  renderer : SDL_Renderer,
  rect : SDL_Rect,
) -> Bool = "SDL_GetRenderSafeArea"

///|
/// Set the clip rectangle for rendering on the specified target.
///
/// Each render target has its own clip rectangle. This function sets the
/// cliprect for the current render target.
///
/// @param renderer the rendering context.
/// @param rect an SDL_Rect structure representing the clip area, relative to
///             the viewport, or NULL to disable clipping.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetRenderClipRect
/// @see SDL_RenderClipEnabled
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetRenderClipRect(SDL_Renderer *renderer, const SDL_Rect *rect);
/// ```
#owned(rect)
pub extern "C" fn sdl_SetRenderClipRect(
  renderer : SDL_Renderer,
  rect : SDL_Rect,
) -> Bool = "SDL_SetRenderClipRect"

///|
/// Get the clip rectangle for the current target.
///
/// Each render target has its own clip rectangle. This function gets the
/// cliprect for the current render target.
///
/// @param renderer the rendering context.
/// @param rect an SDL_Rect structure filled in with the current clipping area
///             or an empty rectangle if clipping is disabled.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_RenderClipEnabled
/// @see SDL_SetRenderClipRect
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetRenderClipRect(SDL_Renderer *renderer, SDL_Rect *rect);
/// ```
#owned(rect)
pub extern "C" fn sdl_GetRenderClipRect(
  renderer : SDL_Renderer,
  rect : SDL_Rect,
) -> Bool = "SDL_GetRenderClipRect"

///|
/// Get whether clipping is enabled on the given render target.
///
/// Each render target has its own clip rectangle. This function checks the
/// cliprect for the current render target.
///
/// @param renderer the rendering context.
/// @return true if clipping is enabled or false if not; call SDL_GetError()
///          for more information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetRenderClipRect
/// @see SDL_SetRenderClipRect
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_RenderClipEnabled(SDL_Renderer *renderer);
/// ```
pub extern "C" fn sdl_RenderClipEnabled(renderer : SDL_Renderer) -> Bool = "SDL_RenderClipEnabled"

///|
/// Set the drawing scale for rendering on the current target.
///
/// The drawing coordinates are scaled by the x/y scaling factors before they
/// are used by the renderer. This allows resolution independent drawing with a
/// single coordinate system.
///
/// If this results in scaling or subpixel drawing by the rendering backend, it
/// will be handled using the appropriate quality hints. For best results use
/// integer scaling factors.
///
/// Each render target has its own scale. This function sets the scale for the
/// current render target.
///
/// @param renderer the rendering context.
/// @param scaleX the horizontal scaling factor.
/// @param scaleY the vertical scaling factor.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetRenderScale
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetRenderScale(SDL_Renderer *renderer, float scaleX, float scaleY);
/// ```
pub extern "C" fn sdl_SetRenderScale(
  renderer : SDL_Renderer,
  scaleX : Float,
  scaleY : Float,
) -> Bool = "SDL_SetRenderScale"

///|
/// Get the drawing scale for the current target.
///
/// Each render target has its own scale. This function gets the scale for the
/// current render target.
///
/// @param renderer the rendering context.
/// @param scaleX a pointer filled in with the horizontal scaling factor.
/// @param scaleY a pointer filled in with the vertical scaling factor.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_SetRenderScale
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetRenderScale(SDL_Renderer *renderer, float *scaleX, float *scaleY);
/// ```
#owned(scaleX, scaleY)
pub extern "C" fn sdl_GetRenderScale(
  renderer : SDL_Renderer,
  scaleX : FixedArray[Float],
  scaleY : FixedArray[Float],
) -> Bool = "SDL_GetRenderScale"

///|
/// Set the color used for drawing operations.
///
/// Set the color for drawing or filling rectangles, lines, and points, and for
/// SDL_RenderClear().
///
/// @param renderer the rendering context.
/// @param r the red value used to draw on the rendering target.
/// @param g the green value used to draw on the rendering target.
/// @param b the blue value used to draw on the rendering target.
/// @param a the alpha value used to draw on the rendering target; usually
///          `SDL_ALPHA_OPAQUE` (255). Use SDL_SetRenderDrawBlendMode to
///          specify how the alpha channel is used.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetRenderDrawColor
/// @see SDL_SetRenderDrawColorFloat
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetRenderDrawColor(SDL_Renderer *renderer, Uint8 r, Uint8 g, Uint8 b, Uint8 a);
/// ```
pub extern "C" fn sdl_SetRenderDrawColor(
  renderer : SDL_Renderer,
  r : Byte,
  g : Byte,
  b : Byte,
  a : Byte,
) -> Bool = "SDL_SetRenderDrawColor"

///|
/// Set the color used for drawing operations (Rect, Line and Clear).
///
/// Set the color for drawing or filling rectangles, lines, and points, and for
/// SDL_RenderClear().
///
/// @param renderer the rendering context.
/// @param r the red value used to draw on the rendering target.
/// @param g the green value used to draw on the rendering target.
/// @param b the blue value used to draw on the rendering target.
/// @param a the alpha value used to draw on the rendering target. Use
///          SDL_SetRenderDrawBlendMode to specify how the alpha channel is
///          used.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetRenderDrawColorFloat
/// @see SDL_SetRenderDrawColor
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetRenderDrawColorFloat(SDL_Renderer *renderer, float r, float g, float b, float a);
/// ```
pub extern "C" fn sdl_SetRenderDrawColorFloat(
  renderer : SDL_Renderer,
  r : Float,
  g : Float,
  b : Float,
  a : Float,
) -> Bool = "SDL_SetRenderDrawColorFloat"

///|
/// Get the color used for drawing operations (Rect, Line and Clear).
///
/// @param renderer the rendering context.
/// @param r a pointer filled in with the red value used to draw on the
///          rendering target.
/// @param g a pointer filled in with the green value used to draw on the
///          rendering target.
/// @param b a pointer filled in with the blue value used to draw on the
///          rendering target.
/// @param a a pointer filled in with the alpha value used to draw on the
///          rendering target; usually `SDL_ALPHA_OPAQUE` (255).
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetRenderDrawColorFloat
/// @see SDL_SetRenderDrawColor
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetRenderDrawColor(SDL_Renderer *renderer, Uint8 *r, Uint8 *g, Uint8 *b, Uint8 *a);
/// ```
#owned(r, g, b, a)
pub extern "C" fn sdl_GetRenderDrawColor(
  renderer : SDL_Renderer,
  r : Bytes,
  g : Bytes,
  b : Bytes,
  a : Bytes,
) -> Bool = "SDL_GetRenderDrawColor"

///|
/// Get the color used for drawing operations (Rect, Line and Clear).
///
/// @param renderer the rendering context.
/// @param r a pointer filled in with the red value used to draw on the
///          rendering target.
/// @param g a pointer filled in with the green value used to draw on the
///          rendering target.
/// @param b a pointer filled in with the blue value used to draw on the
///          rendering target.
/// @param a a pointer filled in with the alpha value used to draw on the
///          rendering target.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_SetRenderDrawColorFloat
/// @see SDL_GetRenderDrawColor
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetRenderDrawColorFloat(SDL_Renderer *renderer, float *r, float *g, float *b, float *a);
/// ```
#owned(r, g, b, a)
pub extern "C" fn sdl_GetRenderDrawColorFloat(
  renderer : SDL_Renderer,
  r : FixedArray[Float],
  g : FixedArray[Float],
  b : FixedArray[Float],
  a : FixedArray[Float],
) -> Bool = "SDL_GetRenderDrawColorFloat"

///|
/// Set the color scale used for render operations.
///
/// The color scale is an additional scale multiplied into the pixel color
/// value while rendering. This can be used to adjust the brightness of colors
/// during HDR rendering, or changing HDR video brightness when playing on an
/// SDR display.
///
/// The color scale does not affect the alpha channel, only the color
/// brightness.
///
/// @param renderer the rendering context.
/// @param scale the color scale value.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @threadsafety This function should only be called on the main thread.
///
/// @since This function is available since SDL 3.2.0.
///
/// @see SDL_GetRenderColorScale
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetRenderColorScale(SDL_Renderer *renderer, float scale);
/// ```
pub extern "C" fn sdl_SetRenderColorScale(
  renderer : SDL_Renderer,
  scale : Float,
) -> Bool = "SDL_SetRenderColorScale"
