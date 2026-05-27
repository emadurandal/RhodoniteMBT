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
/// Save an SDL_Surface into JPEG image data, via an SDL_IOStream.
///
/// @param surface the SDL surface to save.
/// @param dst the SDL_IOStream to save the image data to.
/// @param closeio true to close/free the SDL_IOStream before returning, false
///                to leave it open.
/// @param quality [0; 33] is Lowest quality, [34; 66] is Middle quality, [67;
///                100] is Highest quality.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
///
/// @since This function is available since SDL_image 3.0.0.
///
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL IMG_SaveJPG_IO(SDL_Surface *surface, SDL_IOStream *dst, bool closeio, int quality);
/// ```
pub extern "C" fn img_SaveJPG_IO(
  surface : SDL_Surface,
  dst : SDL_IOStream,
  closeio : Bool,
  quality : Int,
) -> Bool = "IMG_SaveJPG_IO"

///| Animation support functions

///|
/// Load an animation from a file.
///
/// When done with the returned animation, the app should dispose of it with a
/// call to IMG_FreeAnimation().
///
/// @param file path on the filesystem containing an animated image.
/// @return a new IMG_Animation, or NULL on error.
///
/// @since This function is available since SDL_image 3.0.0.
///
/// ```c
/// extern SDL_DECLSPEC IMG_Animation * SDLCALL IMG_LoadAnimation(const char *file);
/// ```
#owned(file)
extern "C" fn __img_LoadAnimation(file : Bytes) -> IMG_Animation = "IMG_LoadAnimation"

///|
pub fn img_LoadAnimation(file : String) -> IMG_Animation {
  __img_LoadAnimation(string_to_cbytes(file))
}

///|
/// Load an animation from an SDL_IOStream.
///
/// @param src an SDL_IOStream that data will be read from.
/// @param closeio true to close/free the SDL_IOStream before returning, false
///                to leave it open.
/// @return a new IMG_Animation, or NULL on error.
///
/// @since This function is available since SDL_image 3.0.0.
///
/// ```c
/// extern SDL_DECLSPEC IMG_Animation * SDLCALL IMG_LoadAnimation_IO(SDL_IOStream *src, bool closeio);
/// ```
pub extern "C" fn img_LoadAnimation_IO(
  src : SDL_IOStream,
  closeio : Bool,
) -> IMG_Animation = "IMG_LoadAnimation_IO"

///|
/// Load an animation from an SDL datasource
///
/// @param src an SDL_IOStream that data will be read from.
/// @param closeio true to close/free the SDL_IOStream before returning, false
///                to leave it open.
/// @param type a filename extension that represent this data ("GIF", etc).
/// @return a new IMG_Animation, or NULL on error.
///
/// @since This function is available since SDL_image 3.0.0.
///
/// ```c
/// extern SDL_DECLSPEC IMG_Animation * SDLCALL IMG_LoadAnimationTyped_IO(SDL_IOStream *src, bool closeio, const char *type);
/// ```
#owned(type_)
extern "C" fn __img_LoadAnimationTyped_IO(
  src : SDL_IOStream,
  closeio : Bool,
  type_ : Bytes,
) -> IMG_Animation = "IMG_LoadAnimationTyped_IO"

///|
pub fn img_LoadAnimationTyped_IO(
  src : SDL_IOStream,
  closeio : Bool,
  type_ : String,
) -> IMG_Animation {
  __img_LoadAnimationTyped_IO(src, closeio, string_to_cbytes(type_))
}

///|
/// Dispose of an IMG_Animation and free its resources.
///
/// The provided `anim` pointer is not valid once this call returns.
///
/// @param anim IMG_Animation to dispose of.
///
/// @since This function is available since SDL_image 3.0.0.
///
/// ```c
/// extern SDL_DECLSPEC void SDLCALL IMG_FreeAnimation(IMG_Animation *anim);
/// ```
pub extern "C" fn img_FreeAnimation(anim : IMG_Animation) -> Unit = "IMG_FreeAnimation"

///|
/// Load a GIF animation directly.
///
/// @param src an SDL_IOStream that data will be read from.
/// @return a new IMG_Animation, or NULL on error.
///
/// @since This function is available since SDL_image 3.0.0.
///
/// ```c
/// extern SDL_DECLSPEC IMG_Animation * SDLCALL IMG_LoadGIFAnimation_IO(SDL_IOStream *src);
/// ```
pub extern "C" fn img_LoadGIFAnimation_IO(src : SDL_IOStream) -> IMG_Animation = "IMG_LoadGIFAnimation_IO"

///|
/// Load a WEBP animation directly.
///
/// @param src an SDL_IOStream that data will be read from.
/// @return a new IMG_Animation, or NULL on error.
///
/// @since This function is available since SDL_image 3.0.0.
///
/// ```c
/// extern SDL_DECLSPEC IMG_Animation * SDLCALL IMG_LoadWEBPAnimation_IO(SDL_IOStream *src);
/// ```
pub extern "C" fn img_LoadWEBPAnimation_IO(src : SDL_IOStream) -> IMG_Animation = "IMG_LoadWEBPAnimation_IO"
