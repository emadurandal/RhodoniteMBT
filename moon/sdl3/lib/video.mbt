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

/// # CategoryVideo
/// 
/// SDL's video subsystem is largely interested in abstracting window
/// management from the underlying operating system. You can create windows,
/// manage them in various ways, set them fullscreen, and get events when
/// interesting things happen with them, such as the mouse or keyboard
/// interacting with a window.
/// 
/// The video subsystem is also interested in abstracting away some
/// platform-specific differences in OpenGL: context creation, swapping
/// buffers, etc. This may be crucial to your app, but also you are not
/// required to use OpenGL at all. In fact, SDL can provide rendering to those
/// windows as well, either with an easy-to-use
/// [2D API](https://wiki.libsdl.org/SDL3/CategoryRender)
/// or with a more-powerful
/// [GPU API](https://wiki.libsdl.org/SDL3/CategoryGPU)
/// . Of course, it can simply get out of your way and give you the window
/// handles you need to use Vulkan, Direct3D, Metal, or whatever else you like
/// directly, too.
/// 
/// The video subsystem covers a lot of functionality, out of necessity, so it
/// is worth perusing the list of functions just to see what's available, but
/// most apps can get by with simply creating a window and listening for
/// events, so start with SDL_CreateWindow() and SDL_PollEvent().

///|
/// This is a unique ID for a display for the time it is connected to the
/// system, and is never reused for the lifetime of the application.
/// 
/// If the display is disconnected and reconnected, it will get a new ID.
/// 
/// The value 0 is an invalid ID.
/// 
/// @since This datatype is available since SDL 3.2.0.
/// 
/// ```c
/// typedef Uint32 SDL_DisplayID;
/// ```
pub type SDL_DisplayID = UInt

///|
/// This is a unique ID for a window.
/// 
/// The value 0 is an invalid ID.
/// 
/// @since This datatype is available since SDL 3.2.0.
/// 
/// ```c
/// typedef Uint32 SDL_WindowID;
/// ```
pub type SDL_WindowID = UInt

///|
/// System theme.
/// 
/// @since This enum is available since SDL 3.2.0.
/// 
/// ```c
/// typedef enum SDL_SystemTheme
/// {
///     SDL_SYSTEM_THEME_UNKNOWN,   /**< Unknown system theme */
///     SDL_SYSTEM_THEME_LIGHT,     /**< Light colored system theme */
///     SDL_SYSTEM_THEME_DARK       /**< Dark colored system theme */
/// } SDL_SystemTheme;
/// ```
pub(all) enum SDL_SystemTheme {
  SDL_SYSTEM_THEME_UNKNOWN
  SDL_SYSTEM_THEME_LIGHT
  SDL_SYSTEM_THEME_DARK
}

///|
/// Internal display mode data.
/// 
/// This lives as a field in SDL_DisplayMode, as opaque data.
/// 
/// @since This struct is available since SDL 3.2.0.
/// 
/// @see SDL_DisplayMode
/// 
/// ```c
/// typedef struct SDL_DisplayModeData SDL_DisplayModeData;
/// ```
#external
pub type SDL_DisplayModeData

///|
/// The structure that defines a display mode.
/// 
/// @since This struct is available since SDL 3.2.0.
/// 
/// @see SDL_GetFullscreenDisplayModes
/// @see SDL_GetDesktopDisplayMode
/// @see SDL_GetCurrentDisplayMode
/// @see SDL_SetWindowFullscreenMode
/// @see SDL_GetWindowFullscreenMode
/// 
/// ```c
/// typedef struct SDL_DisplayMode
/// {
///     SDL_DisplayID displayID;        /**< the display this mode is associated with */
///     SDL_PixelFormat format;         /**< pixel format */
///     int w;                          /**< width */
///     int h;                          /**< height */
///     float pixel_density;            /**< scale converting size to pixels (e.g. a 1920x1080 mode with 2.0 scale would have 3840x2160 pixels) */
///     float refresh_rate;             /**< refresh rate (or 0.0f for unspecified) */
///     int refresh_rate_numerator;     /**< precise refresh rate numerator (or 0 for unspecified) */
///     int refresh_rate_denominator;   /**< precise refresh rate denominator */
/// 
///     SDL_DisplayModeData *internal;  /**< Private */
/// 
/// } SDL_DisplayMode;
/// ```
pub(all) struct SDL_DisplayMode {
  displayID : SDL_DisplayID
  format : UInt // SDL_PixelFormat
  w : Int
  h : Int
  pixel_density : Float
  refresh_rate : Float
  refresh_rate_numerator : Int
  refresh_rate_denominator : Int
  internal : SDL_DisplayModeData
}

///|
/// Display orientation values; the way a display is rotated.
/// 
/// @since This enum is available since SDL 3.2.0.
/// 
/// ```c
/// typedef enum SDL_DisplayOrientation
/// {
///     SDL_ORIENTATION_UNKNOWN,            /**< The display orientation can't be determined */
///     SDL_ORIENTATION_LANDSCAPE,          /**< The display is in landscape mode, with the right side up, relative to portrait mode */
///     SDL_ORIENTATION_LANDSCAPE_FLIPPED,  /**< The display is in landscape mode, with the left side up, relative to portrait mode */
///     SDL_ORIENTATION_PORTRAIT,           /**< The display is in portrait mode */
///     SDL_ORIENTATION_PORTRAIT_FLIPPED    /**< The display is in portrait mode, upside down */
/// } SDL_DisplayOrientation;
/// ```
pub(all) enum SDL_DisplayOrientation {
  SDL_ORIENTATION_UNKNOWN
  SDL_ORIENTATION_LANDSCAPE
  SDL_ORIENTATION_LANDSCAPE_FLIPPED
  SDL_ORIENTATION_PORTRAIT
  SDL_ORIENTATION_PORTRAIT_FLIPPED
}

///|
/// The struct used as an opaque handle to a window.
/// 
/// @since This struct is available since SDL 3.2.0.
/// 
/// @see SDL_CreateWindow
/// 
/// ```c
/// typedef struct SDL_Window SDL_Window;
/// ```
#external
pub type SDL_Window

///|
pub fn SDL_Window::is_null(self : Self) -> Bool {
  is_nullptr(self)
}

///|
/// The flags on a window.
/// 
/// These cover a lot of true/false, or on/off, window state. Some of it is
/// immutable after being set through SDL_CreateWindow(), some of it can be
/// changed on existing windows by the app, and some of it might be altered by
/// the user or system outside of the app's control.
/// 
/// @since This datatype is available since SDL 3.2.0.
/// 
/// @see SDL_GetWindowFlags
/// 
/// ```c
/// typedef Uint64 SDL_WindowFlags;
/// ```
pub type SDL_WindowFlags = UInt64

// Window flag constants

///|
pub const SDL_WINDOW_FULLSCREEN : SDL_WindowFlags = 0x0000000000000001UL

///|
pub const SDL_WINDOW_OPENGL : SDL_WindowFlags = 0x0000000000000002UL

///|
pub const SDL_WINDOW_OCCLUDED : SDL_WindowFlags = 0x0000000000000004UL

///|
pub const SDL_WINDOW_HIDDEN : SDL_WindowFlags = 0x0000000000000008UL

///|
pub const SDL_WINDOW_BORDERLESS : SDL_WindowFlags = 0x0000000000000010UL

///|
pub const SDL_WINDOW_RESIZABLE : SDL_WindowFlags = 0x0000000000000020UL

///|
pub const SDL_WINDOW_MINIMIZED : SDL_WindowFlags = 0x0000000000000040UL

///|
pub const SDL_WINDOW_MAXIMIZED : SDL_WindowFlags = 0x0000000000000080UL

///|
pub const SDL_WINDOW_MOUSE_GRABBED : SDL_WindowFlags = 0x0000000000000100UL

///|
pub const SDL_WINDOW_INPUT_FOCUS : SDL_WindowFlags = 0x0000000000000200UL

///|
pub const SDL_WINDOW_MOUSE_FOCUS : SDL_WindowFlags = 0x0000000000000400UL

///|
pub const SDL_WINDOW_EXTERNAL : SDL_WindowFlags = 0x0000000000000800UL

///|
pub const SDL_WINDOW_MODAL : SDL_WindowFlags = 0x0000000000001000UL

///|
pub const SDL_WINDOW_HIGH_PIXEL_DENSITY : SDL_WindowFlags = 0x0000000000002000UL

///|
pub const SDL_WINDOW_MOUSE_CAPTURE : SDL_WindowFlags = 0x0000000000004000UL

///|
pub const SDL_WINDOW_MOUSE_RELATIVE_MODE : SDL_WindowFlags = 0x0000000000008000UL

///|
pub const SDL_WINDOW_ALWAYS_ON_TOP : SDL_WindowFlags = 0x0000000000010000UL

///|
pub const SDL_WINDOW_UTILITY : SDL_WindowFlags = 0x0000000000020000UL

///|
pub const SDL_WINDOW_TOOLTIP : SDL_WindowFlags = 0x0000000000040000UL

///|
pub const SDL_WINDOW_POPUP_MENU : SDL_WindowFlags = 0x0000000000080000UL

///|
pub const SDL_WINDOW_KEYBOARD_GRABBED : SDL_WindowFlags = 0x0000000000100000UL

///|
pub const SDL_WINDOW_VULKAN : SDL_WindowFlags = 0x0000000010000000UL

///|
pub const SDL_WINDOW_METAL : SDL_WindowFlags = 0x0000000020000000UL

///|
pub const SDL_WINDOW_TRANSPARENT : SDL_WindowFlags = 0x0000000040000000UL

///|
pub const SDL_WINDOW_NOT_FOCUSABLE : SDL_WindowFlags = 0x0000000080000000UL

///|
/// Window flash operation.
/// 
/// @since This enum is available since SDL 3.2.0.
/// 
/// ```c
/// typedef enum SDL_FlashOperation
/// {
///     SDL_FLASH_CANCEL,                   /**< Cancel any window flash state */
///     SDL_FLASH_BRIEFLY,                  /**< Flash the window briefly to get attention */
///     SDL_FLASH_UNTIL_FOCUSED             /**< Flash the window until it gets focus */
/// } SDL_FlashOperation;
/// ```
pub(all) enum SDL_FlashOperation {
  SDL_FLASH_CANCEL
  SDL_FLASH_BRIEFLY
  SDL_FLASH_UNTIL_FOCUSED
}

///|
/// Window progress state
/// 
/// @since This enum is available since SDL 3.2.8.
/// 
/// ```c
/// typedef enum SDL_ProgressState
/// {
///     SDL_PROGRESS_STATE_INVALID = -1,    /**< An invalid progress state indicating an error; check SDL_GetError() */
///     SDL_PROGRESS_STATE_NONE,            /**< No progress bar is shown */
///     SDL_PROGRESS_STATE_INDETERMINATE,   /**< The progress bar is shown in a indeterminate state */
///     SDL_PROGRESS_STATE_NORMAL,          /**< The progress bar is shown in a normal state */
///     SDL_PROGRESS_STATE_PAUSED,          /**< The progress bar is shown in a paused state */
///     SDL_PROGRESS_STATE_ERROR            /**< The progress bar is shown in a state indicating the application had an error */
/// } SDL_ProgressState;
/// ```
pub(all) enum SDL_ProgressState {
  SDL_PROGRESS_STATE_INVALID
  SDL_PROGRESS_STATE_NONE
  SDL_PROGRESS_STATE_INDETERMINATE
  SDL_PROGRESS_STATE_NORMAL
  SDL_PROGRESS_STATE_PAUSED
  SDL_PROGRESS_STATE_ERROR
}

///|
/// An opaque handle to an OpenGL context.
/// 
/// @since This datatype is available since SDL 3.2.0.
/// 
/// @see SDL_GL_CreateContext
/// 
/// ```c
/// typedef struct SDL_GLContextState *SDL_GLContext;
/// ```
#external
pub type SDL_GLContext

///|
pub fn SDL_GLContext::is_null(self : Self) -> Bool {
  is_nullptr(self)
}

///|
/// Opaque type for an EGL display.
/// 
/// @since This datatype is available since SDL 3.2.0.
/// 
/// ```c
/// typedef void *SDL_EGLDisplay;
/// ```
pub type SDL_EGLDisplay = VoidPtr

///|
/// Opaque type for an EGL config.
/// 
/// @since This datatype is available since SDL 3.2.0.
/// 
/// ```c
/// typedef void *SDL_EGLConfig;
/// ```
pub type SDL_EGLConfig = VoidPtr

///|
/// Opaque type for an EGL surface.
/// 
/// @since This datatype is available since SDL 3.2.0.
/// 
/// ```c
/// typedef void *SDL_EGLSurface;
/// ```
pub type SDL_EGLSurface = VoidPtr

///|
/// An EGL attribute, used when creating an EGL context.
/// 
/// @since This datatype is available since SDL 3.2.0.
/// 
/// ```c
/// typedef intptr_t SDL_EGLAttrib;
/// ```
pub type SDL_EGLAttrib = Int64

///|
/// An EGL integer attribute, used when creating an EGL surface.
/// 
/// @since This datatype is available since SDL 3.2.0.
/// 
/// ```c
/// typedef int SDL_EGLint;
/// ```
pub type SDL_EGLint = Int

///|
/// EGL platform attribute initialization callback.
/// 
/// This is called when SDL is attempting to create an EGL context, to let the
/// app add extra attributes to its eglGetPlatformDisplay() call.
/// 
/// The callback should return a pointer to an EGL attribute array terminated
/// with `EGL_NONE`. If this function returns NULL, the SDL_CreateWindow
/// process will fail gracefully.
/// 
/// The returned pointer should be allocated with SDL_malloc() and will be
/// passed to SDL_free().
/// 
/// The arrays returned by each callback will be appended to the existing
/// attribute arrays defined by SDL.
/// 
/// @param userdata an app-controlled pointer that is passed to the callback.
/// @return a newly-allocated array of attributes, terminated with `EGL_NONE`.
/// 
/// @since This datatype is available since SDL 3.2.0.
/// 
/// @see SDL_EGL_SetAttributeCallbacks
/// 
/// ```c
/// typedef SDL_EGLAttrib *(SDLCALL *SDL_EGLAttribArrayCallback)(void *userdata);
/// ```
pub type SDL_EGLAttribArrayCallback = FuncRef[
  (VoidPtr) -> FixedArray[SDL_EGLAttrib],
]

///|
/// EGL surface/context attribute initialization callback types.
/// 
/// This is called when SDL is attempting to create an EGL surface, to let the
/// app add extra attributes to its eglCreateWindowSurface() or
/// eglCreateContext calls.
/// 
/// For convenience, the EGLDisplay and EGLConfig to use are provided to the
/// callback.
/// 
/// The callback should return a pointer to an EGL attribute array terminated
/// with `EGL_NONE`. If this function returns NULL, the SDL_CreateWindow
/// process will fail gracefully.
/// 
/// The returned pointer should be allocated with SDL_malloc() and will be
/// passed to SDL_free().
/// 
/// The arrays returned by each callback will be appended to the existing
/// attribute arrays defined by SDL.
/// 
/// @param userdata an app-controlled pointer that is passed to the callback.
/// @param display the EGL display to be used.
/// @param config the EGL config to be used.
/// @return a newly-allocated array of attributes, terminated with `EGL_NONE`.
/// 
/// @since This datatype is available since SDL 3.2.0.
/// 
/// @see SDL_EGL_SetAttributeCallbacks
/// 
/// ```c
/// typedef SDL_EGLint *(SDLCALL *SDL_EGLIntArrayCallback)(void *userdata, SDL_EGLDisplay display, SDL_EGLConfig config);
/// ```
pub type SDL_EGLIntArrayCallback = FuncRef[
  (VoidPtr, SDL_EGLDisplay, SDL_EGLConfig) -> FixedArray[SDL_EGLint],
]

///|
/// An enumeration of OpenGL configuration attributes.
/// 
/// While you can set most OpenGL attributes normally, the attributes listed
/// above must be known before SDL creates the window that will be used with
/// the OpenGL context. These attributes are set and read with
/// SDL_GL_SetAttribute() and SDL_GL_GetAttribute().
/// 
/// In some cases, these attributes are minimum requests; the GL does not
/// promise to give you exactly what you asked for. It's possible to ask for a
/// 16-bit depth buffer and get a 24-bit one instead, for example, or to ask
/// for no stencil buffer and still have one available. Context creation should
/// fail if the GL can't provide your requested attributes at a minimum, but
/// you should check to see exactly what you got.
/// 
/// @since This enum is available since SDL 3.2.0.
/// 
/// ```c
/// typedef enum SDL_GLAttr
/// {
///     SDL_GL_RED_SIZE,
///     SDL_GL_GREEN_SIZE,
///     SDL_GL_BLUE_SIZE,
///     SDL_GL_ALPHA_SIZE,
///     SDL_GL_BUFFER_SIZE,
///     SDL_GL_DOUBLEBUFFER,
///     SDL_GL_DEPTH_SIZE,
///     SDL_GL_STENCIL_SIZE,
///     SDL_GL_ACCUM_RED_SIZE,
///     SDL_GL_ACCUM_GREEN_SIZE,
///     SDL_GL_ACCUM_BLUE_SIZE,
///     SDL_GL_ACCUM_ALPHA_SIZE,
///     SDL_GL_STEREO,
///     SDL_GL_MULTISAMPLEBUFFERS,
///     SDL_GL_MULTISAMPLESAMPLES,
///     SDL_GL_ACCELERATED_VISUAL,
///     SDL_GL_RETAINED_BACKING,
///     SDL_GL_CONTEXT_MAJOR_VERSION,
///     SDL_GL_CONTEXT_MINOR_VERSION,
///     SDL_GL_CONTEXT_FLAGS,
///     SDL_GL_CONTEXT_PROFILE_MASK,
///     SDL_GL_SHARE_WITH_CURRENT_CONTEXT,
///     SDL_GL_FRAMEBUFFER_SRGB_CAPABLE,
///     SDL_GL_CONTEXT_RELEASE_BEHAVIOR,
///     SDL_GL_CONTEXT_RESET_NOTIFICATION,
///     SDL_GL_CONTEXT_NO_ERROR,
///     SDL_GL_FLOATBUFFERS,
///     SDL_GL_EGL_PLATFORM
/// } SDL_GLAttr;
/// ```
pub(all) enum SDL_GLAttr {
  SDL_GL_RED_SIZE
  SDL_GL_GREEN_SIZE
  SDL_GL_BLUE_SIZE
  SDL_GL_ALPHA_SIZE
  SDL_GL_BUFFER_SIZE
  SDL_GL_DOUBLEBUFFER
  SDL_GL_DEPTH_SIZE
  SDL_GL_STENCIL_SIZE
  SDL_GL_ACCUM_RED_SIZE
  SDL_GL_ACCUM_GREEN_SIZE
  SDL_GL_ACCUM_BLUE_SIZE
  SDL_GL_ACCUM_ALPHA_SIZE
  SDL_GL_STEREO
  SDL_GL_MULTISAMPLEBUFFERS
  SDL_GL_MULTISAMPLESAMPLES
  SDL_GL_ACCELERATED_VISUAL
  SDL_GL_RETAINED_BACKING
  SDL_GL_CONTEXT_MAJOR_VERSION
  SDL_GL_CONTEXT_MINOR_VERSION
  SDL_GL_CONTEXT_FLAGS
  SDL_GL_CONTEXT_PROFILE_MASK
  SDL_GL_SHARE_WITH_CURRENT_CONTEXT
  SDL_GL_FRAMEBUFFER_SRGB_CAPABLE
  SDL_GL_CONTEXT_RELEASE_BEHAVIOR
  SDL_GL_CONTEXT_RESET_NOTIFICATION
  SDL_GL_CONTEXT_NO_ERROR
  SDL_GL_FLOATBUFFERS
  SDL_GL_EGL_PLATFORM
}

// GL Profile flags

///|
pub type SDL_GLProfile = UInt

///|
pub const SDL_GL_CONTEXT_PROFILE_CORE : SDL_GLProfile = 0x0001U

///|
pub const SDL_GL_CONTEXT_PROFILE_COMPATIBILITY : SDL_GLProfile = 0x0002U

///|
pub const SDL_GL_CONTEXT_PROFILE_ES : SDL_GLProfile = 0x0004U

// GL Context flags

///|
pub type SDL_GLContextFlag = UInt

///|
pub const SDL_GL_CONTEXT_DEBUG_FLAG : SDL_GLContextFlag = 0x0001U

///|
pub const SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG : SDL_GLContextFlag = 0x0002U

///|
pub const SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG : SDL_GLContextFlag = 0x0004U

///|
pub const SDL_GL_CONTEXT_RESET_ISOLATION_FLAG : SDL_GLContextFlag = 0x0008U

// GL Context release flags

///|
pub type SDL_GLContextReleaseFlag = UInt

///|
pub const SDL_GL_CONTEXT_RELEASE_BEHAVIOR_NONE : SDL_GLContextReleaseFlag = 0x0000U

///|
pub const SDL_GL_CONTEXT_RELEASE_BEHAVIOR_FLUSH : SDL_GLContextReleaseFlag = 0x0001U

// GL Context reset notification flags

///|
pub type SDL_GLContextResetNotification = UInt

///|
pub const SDL_GL_CONTEXT_RESET_NO_NOTIFICATION : SDL_GLContextResetNotification = 0x0000U

///|
pub const SDL_GL_CONTEXT_RESET_LOSE_CONTEXT : SDL_GLContextResetNotification = 0x0001U

///|
/// Get the number of video drivers compiled into SDL.
/// 
/// @return the number of built in video drivers.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GetVideoDriver
/// 
/// ```c
/// extern SDL_DECLSPEC int SDLCALL SDL_GetNumVideoDrivers(void);
/// ```
pub extern "C" fn sdl_GetNumVideoDrivers() -> Int = "SDL_GetNumVideoDrivers"

///|
/// Get the name of a built in video driver.
/// 
/// The video drivers are presented in the order in which they are normally
/// checked during initialization.
/// 
/// The names of drivers are all simple, low-ASCII identifiers, like "cocoa",
/// "x11" or "windows". These never have Unicode characters, and are not meant
/// to be proper names.
/// 
/// @param index the index of a video driver.
/// @return the name of the video driver with the given **index**, or NULL if
///          index is out of bounds.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GetNumVideoDrivers
/// 
/// ```c
/// extern SDL_DECLSPEC const char * SDLCALL SDL_GetVideoDriver(int index);
/// ```
pub fn sdl_GetVideoDriver(index : Int) -> String {
  let cres = __sdl_GetVideoDriver(index)
  let res = cres.to_string()
  free_cstr(cres)
  res
}

///|
extern "C" fn __sdl_GetVideoDriver(index : Int) -> CStr = "SDL_GetVideoDriver"

///|
/// Get the name of the currently initialized video driver.
/// 
/// The names of drivers are all simple, low-ASCII identifiers, like "cocoa",
/// "x11" or "windows". These never have Unicode characters, and are not meant
/// to be proper names.
/// 
/// @return the name of the current video driver or NULL if no driver has been
///          initialized.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GetNumVideoDrivers
/// @see SDL_GetVideoDriver
/// 
/// ```c
/// extern SDL_DECLSPEC const char * SDLCALL SDL_GetCurrentVideoDriver(void);
/// ```
pub fn sdl_GetCurrentVideoDriver() -> String {
  let cres = __sdl_GetCurrentVideoDriver()
  let res = cres.to_string()
  free_cstr(cres)
  res
}

///|
extern "C" fn __sdl_GetCurrentVideoDriver() -> CStr = "SDL_GetCurrentVideoDriver"

///|
/// Get the current system theme.
/// 
/// @return the current system theme, light, dark, or unknown.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC SDL_SystemTheme SDLCALL SDL_GetSystemTheme(void);
/// ```
pub extern "C" fn sdl_GetSystemTheme() -> SDL_SystemTheme = "SDL_GetSystemTheme"

///|
/// Get a list of currently connected displays.
/// 
/// @param count a pointer filled in with the number of displays returned, may
///              be NULL.
/// @return a 0 terminated array of display instance IDs or NULL on failure;
///          call SDL_GetError() for more information. This should be freed
///          with SDL_free() when it is no longer needed.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GetPrimaryDisplay
/// 
/// ```c
/// extern SDL_DECLSPEC SDL_DisplayID * SDLCALL SDL_GetDisplays(int *count);
/// ```
#owned(count)
pub extern "C" fn sdl_GetDisplays(
  count : FixedArray[Int],
) -> FixedArray[SDL_DisplayID] = "SDL_GetDisplays"

///|
/// Return the primary display.
/// 
/// @return the instance ID of the primary display on success or 0 on failure;
///          call SDL_GetError() for more information.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GetDisplays
/// 
/// ```c
/// extern SDL_DECLSPEC SDL_DisplayID SDLCALL SDL_GetPrimaryDisplay(void);
/// ```
pub extern "C" fn sdl_GetPrimaryDisplay() -> SDL_DisplayID = "SDL_GetPrimaryDisplay"

///|
/// Get the properties associated with a display.
/// 
/// @param displayID the instance ID of the display to query.
/// @return a valid property ID on success or 0 on failure; call
///          SDL_GetError() for more information.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC SDL_PropertiesID SDLCALL SDL_GetDisplayProperties(SDL_DisplayID displayID);
/// ```
pub extern "C" fn sdl_GetDisplayProperties(displayID : SDL_DisplayID) -> UInt = "SDL_GetDisplayProperties" // SDL_PropertiesID is Uint32

///|
/// Get the name of a display in UTF-8 encoding.
/// 
/// @param displayID the instance ID of the display to query.
/// @return the name of a display or NULL on failure; call SDL_GetError() for
///          more information.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC const char * SDLCALL SDL_GetDisplayName(SDL_DisplayID displayID);
/// ```
pub fn sdl_GetDisplayName(displayID : SDL_DisplayID) -> String {
  let cres = __sdl_GetDisplayName(displayID)
  let res = cres.to_string()
  free_cstr(cres)
  res
}

///|
extern "C" fn __sdl_GetDisplayName(displayID : SDL_DisplayID) -> CStr = "SDL_GetDisplayName"

///|
/// Get the desktop area represented by a display.
/// 
/// The primary display is always located at (0,0).
/// 
/// @param displayID the instance ID of the display to query.
/// @param rect the SDL_Rect structure filled in with the display bounds.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GetDisplayUsableBounds
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetDisplayBounds(SDL_DisplayID displayID, SDL_Rect *rect);
/// ```
#owned(rect)
pub extern "C" fn sdl_GetDisplayBounds(
  displayID : SDL_DisplayID,
  rect : FixedArray[SDL_Rect],
) -> Bool = "SDL_GetDisplayBounds"

///|
/// Get the usable desktop area represented by a display.
/// 
/// The primary display is always located at (0,0).
/// 
/// This is the same area as SDL_GetDisplayBounds() reports, but with portions
/// reserved by the system removed. For example, on Apple's macOS, this
/// subtracts the area occupied by the menu bar and dock.
/// 
/// Setting a window to be fullscreen generally bypasses these unusable areas,
/// so these are good guidelines for the maximum space available to a
/// non-fullscreen window.
/// 
/// @param displayID the instance ID of the display to query.
/// @param rect the SDL_Rect structure filled in with the display bounds.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GetDisplayBounds
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_GetDisplayUsableBounds(SDL_DisplayID displayID, SDL_Rect *rect);
/// ```
#owned(rect)
pub extern "C" fn sdl_GetDisplayUsableBounds(
  displayID : SDL_DisplayID,
  rect : FixedArray[SDL_Rect],
) -> Bool = "SDL_GetDisplayUsableBounds"

///|
/// Get the orientation of a display.
/// 
/// @param displayID the instance ID of the display to query.
/// @return the SDL_DisplayOrientation enum value of the display, or
///          SDL_ORIENTATION_UNKNOWN if it isn't available.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC SDL_DisplayOrientation SDLCALL SDL_GetNaturalDisplayOrientation(SDL_DisplayID displayID);
/// ```
pub extern "C" fn sdl_GetNaturalDisplayOrientation(
  displayID : SDL_DisplayID,
) -> SDL_DisplayOrientation = "SDL_GetNaturalDisplayOrientation"

///|
/// Get the orientation of a display.
/// 
/// @param displayID the instance ID of the display to query.
/// @return the SDL_DisplayOrientation enum value of the display, or
///          SDL_ORIENTATION_UNKNOWN if it isn't available.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC SDL_DisplayOrientation SDLCALL SDL_GetCurrentDisplayOrientation(SDL_DisplayID displayID);
/// ```
pub extern "C" fn sdl_GetCurrentDisplayOrientation(
  displayID : SDL_DisplayID,
) -> SDL_DisplayOrientation = "SDL_GetCurrentDisplayOrientation"

///|
/// Get the content scale of a display.
/// 
/// The content scale is the expected scale for content based on the DPI
/// settings of the display. For example, a 4K display might have a 2.0 scale to
/// indicate that UI elements should be drawn twice as large as normal to
/// account for the increased pixel density.
/// 
/// The default value is 1.0.
/// 
/// This function can be called before SDL_Init().
/// 
/// @param displayID the instance ID of the display to query.
/// @return the content scale of the display, or 0.0f on failure; call
///          SDL_GetError() for more information.
/// 
/// @threadsafety This function should only be called on the main thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC float SDLCALL SDL_GetDisplayContentScale(SDL_DisplayID displayID);
/// ```
pub extern "C" fn sdl_GetDisplayContentScale(
  displayID : SDL_DisplayID,
) -> Float = "SDL_GetDisplayContentScale"

// 这里我会为了简洁起见，添加一些最重要的函数。完整版本会包含更多函数
