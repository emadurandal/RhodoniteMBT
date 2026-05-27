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
/// Reset all previously set OpenGL context attributes to their default values.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GL_GetAttribute
/// @see SDL_GL_SetAttribute
/// 
/// ```c
/// extern SDL_DECLSPEC void SDLCALL SDL_GL_ResetAttributes(void);
/// ```
pub extern "C" fn sdl_GL_ResetAttributes() = "SDL_GL_ResetAttributes"

///|
/// Set an OpenGL window attribute before window creation.
/// 
/// This function sets the OpenGL attribute `attr` to `value`. The requested
/// attributes should be set before creating an OpenGL window. You should use
/// SDL_GL_GetAttribute() to check the values after creating the OpenGL
/// context, since the values obtained can differ from the requested ones.
/// 
/// @param attr an SDL_GLAttr enum value specifying the OpenGL attribute to set.
/// @param value the desired value for the attribute.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GL_GetAttribute
/// @see SDL_GL_ResetAttributes
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GL_SetAttribute(SDL_GLAttr attr, int value);
/// ```
pub extern "C" fn sdl_GL_SetAttribute(attr : SDL_GLAttr, value : Int) -> Bool = "SDL_GL_SetAttribute"

///|
/// Get the actual value for an attribute from the current context.
/// 
/// @param attr an SDL_GLAttr enum value specifying the OpenGL attribute to get.
/// @param value a pointer filled in with the current value of `attr`.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GL_ResetAttributes
/// @see SDL_GL_SetAttribute
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GL_GetAttribute(SDL_GLAttr attr, int *value);
/// ```
#owned(value)
pub extern "C" fn sdl_GL_GetAttribute(
  attr : SDL_GLAttr,
  value : FixedArray[Int],
) -> Bool = "SDL_GL_GetAttribute"

///|
/// Create an OpenGL context for an OpenGL window, and make it current.
/// 
/// Windows users new to OpenGL should note that, for historical reasons, GL
/// functions added after OpenGL version 1.1 are not available by default.
/// Those functions must be loaded at run-time, either with an OpenGL
/// extension-handling library or with SDL_GL_GetProcAddress() and its related
/// functions.
/// 
/// SDL_GLContext is an alias for `void *`. It's opaque to the application.
/// 
/// @param window the window to associate with the context.
/// @return the OpenGL context associated with `window` or NULL on failure;
///          call SDL_GetError() for more information.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GL_DestroyContext
/// @see SDL_GL_MakeCurrent
/// 
/// ```c
/// extern SDL_DECLSPEC SDL_GLContext SDLCALL SDL_GL_CreateContext(SDL_Window *window);
/// ```
pub extern "C" fn sdl_GL_CreateContext(window : SDL_Window) -> SDL_GLContext = "SDL_GL_CreateContext"

///|
/// Set up an OpenGL context for rendering into an OpenGL window.
/// 
/// The context must have been created with a compatible window.
/// 
/// @param window the window to associate with the context.
/// @param context the OpenGL context to associate with the window.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GL_CreateContext
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GL_MakeCurrent(SDL_Window *window, SDL_GLContext context);
/// ```
pub extern "C" fn sdl_GL_MakeCurrent(
  window : SDL_Window,
  context : SDL_GLContext,
) -> Bool = "SDL_GL_MakeCurrent"

///|
/// Get the currently active OpenGL context.
/// 
/// @return the currently active OpenGL context or NULL on failure; call
///          SDL_GetError() for more information.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GL_MakeCurrent
/// 
/// ```c
/// extern SDL_DECLSPEC SDL_GLContext SDLCALL SDL_GL_GetCurrentContext(void);
/// ```
pub extern "C" fn sdl_GL_GetCurrentContext() -> SDL_GLContext = "SDL_GL_GetCurrentContext"

///|
/// Get the currently active OpenGL window.
/// 
/// @return the currently active OpenGL window on success or NULL on failure;
///          call SDL_GetError() for more information.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC SDL_Window * SDLCALL SDL_GL_GetCurrentWindow(void);
/// ```
pub extern "C" fn sdl_GL_GetCurrentWindow() -> SDL_Window = "SDL_GL_GetCurrentWindow"

///|
/// Set the swap interval for the current OpenGL context.
/// 
/// Some systems allow specifying -1 for the interval, to enable adaptive
/// vsync. Adaptive vsync works the same as vsync, but if you've already missed
/// the vertical retrace for a given frame, it swaps buffers immediately, which
/// might be less jarring for the user during occasional framerate drops. If
/// an application requests adaptive vsync and the system does not support it,
/// this function will fail and return false. In such a case, you should
/// probably retry the call with 1 for the interval.
/// 
/// Adaptive vsync is implemented for some glX drivers with
/// GLX_EXT_swap_control_tear, and for some Windows drivers with
/// WGL_EXT_swap_control_tear.
/// 
/// Read more on the Khronos wiki:
/// https://www.khronos.org/opengl/wiki/Swap_Interval#Adaptive_Vsync
/// 
/// @param interval 0 for immediate updates, 1 for updates synchronized with
///                 the vertical retrace, -1 for adaptive vsync.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GL_GetSwapInterval
/// @see SDL_GL_SwapWindow
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GL_SetSwapInterval(int interval);
/// ```
pub extern "C" fn sdl_GL_SetSwapInterval(interval : Int) -> Bool = "SDL_GL_SetSwapInterval"

///|
/// Get the swap interval for the current OpenGL context.
/// 
/// If the system can't determine the swap interval, or there isn't a valid
/// current context, this function will set *interval to 0 as a safe default.
/// 
/// @param interval output interval value. 0 if there is no vertical retrace
///                 synchronization, 1 if the buffer swap is synchronized with
///                 the vertical retrace, and -1 if late swaps happen
///                 immediately instead of waiting for the next retrace.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GL_SetSwapInterval
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GL_GetSwapInterval(int *interval);
/// ```
#owned(interval)
pub extern "C" fn sdl_GL_GetSwapInterval(interval : FixedArray[Int]) -> Bool = "SDL_GL_GetSwapInterval"

///|
/// Update a window with OpenGL rendering.
/// 
/// This is used with double-buffered OpenGL contexts, which are the default.
/// 
/// On macOS, make sure you bind 0 to the draw framebuffer before swapping the
/// window, otherwise nothing will happen. If you aren't using
/// glBindFramebuffer(), this is the default and you won't have to do anything
/// extra.
/// 
/// @param window the window to change.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GL_SetSwapInterval
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GL_SwapWindow(SDL_Window *window);
/// ```
pub extern "C" fn sdl_GL_SwapWindow(window : SDL_Window) -> Bool = "SDL_GL_SwapWindow"

///|
/// Delete an OpenGL context.
/// 
/// @param context the OpenGL context to be deleted.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GL_CreateContext
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GL_DestroyContext(SDL_GLContext context);
/// ```
pub extern "C" fn sdl_GL_DestroyContext(context : SDL_GLContext) -> Bool = "SDL_GL_DestroyContext"
