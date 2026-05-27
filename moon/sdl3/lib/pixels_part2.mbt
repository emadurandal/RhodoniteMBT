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
/// Create a palette structure with the specified number of color entries.
/// 
/// The palette entries are initialized to white.
/// 
/// @param ncolors represents the number of color entries in the color palette.
/// @return a new SDL_Palette structure on success or NULL on failure (e.g. if
///          there wasn't enough memory); call SDL_GetError() for more
///          information.
/// 
/// @threadsafety It is safe to call this function from any thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_DestroyPalette
/// @see SDL_SetPaletteColors
/// @see SDL_SetSurfacePalette
/// 
/// ```c
/// extern SDL_DECLSPEC SDL_Palette * SDLCALL SDL_CreatePalette(int ncolors);
/// ```
pub extern "C" fn sdl_CreatePalette(ncolors : Int) -> SDL_Palette = "SDL_CreatePalette"

///|
/// Set a range of colors in a palette.
/// 
/// @param palette the SDL_Palette structure to modify.
/// @param colors an array of SDL_Color structures to copy into the palette.
/// @param firstcolor the index of the first palette entry to modify.
/// @param ncolors the number of entries to modify.
/// @return true on success or false on failure; call SDL_GetError() for more
///          information.
/// 
/// @threadsafety It is safe to call this function from any thread, as long as
///               the palette is not modified or destroyed in another thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetPaletteColors(SDL_Palette *palette, const SDL_Color *colors, int firstcolor, int ncolors);
/// ```
#owned(colors)
pub extern "C" fn sdl_SetPaletteColors(
  palette : SDL_Palette,
  colors : FixedArray[SDL_Color],
  firstcolor : Int,
  ncolors : Int,
) -> Bool = "SDL_SetPaletteColors"

///|
/// Free a palette created with SDL_CreatePalette().
/// 
/// @param palette the SDL_Palette structure to be freed.
/// 
/// @threadsafety It is safe to call this function from any thread, as long as
///               the palette is not modified or destroyed in another thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_CreatePalette
/// 
/// ```c
/// extern SDL_DECLSPEC void SDLCALL SDL_DestroyPalette(SDL_Palette *palette);
/// ```
pub extern "C" fn sdl_DestroyPalette(palette : SDL_Palette) = "SDL_DestroyPalette"

///|
/// Map an RGB triple to an opaque pixel value for a given pixel format.
/// 
/// This function maps the RGB color value to the specified pixel format and
/// returns the pixel value best approximating the given RGB color value for
/// the given pixel format.
/// 
/// If the format has a palette (8-bit) the index of the closest matching color
/// in the palette will be returned.
/// 
/// If the specified pixel format has an alpha component it will be returned as
/// all 1 bits (fully opaque).
/// 
/// If the pixel format bpp (color depth) is less than 32-bpp then the unused
/// upper bits of the return value can safely be ignored (e.g., with a 16-bpp
/// format the return value can be assigned to a Uint16, and similarly a Uint8
/// for an 8-bpp format).
/// 
/// @param format a pointer to SDL_PixelFormatDetails describing the pixel
///               format.
/// @param palette an optional palette for indexed formats, may be NULL.
/// @param r the red component of the pixel in the range 0-255.
/// @param g the green component of the pixel in the range 0-255.
/// @param b the blue component of the pixel in the range 0-255.
/// @return a pixel value.
/// 
/// @threadsafety It is safe to call this function from any thread, as long as
///               the palette is not modified.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GetPixelFormatDetails
/// @see SDL_GetRGB
/// @see SDL_MapRGBA
/// @see SDL_MapSurfaceRGB
/// 
/// ```c
/// extern SDL_DECLSPEC Uint32 SDLCALL SDL_MapRGB(const SDL_PixelFormatDetails *format, const SDL_Palette *palette, Uint8 r, Uint8 g, Uint8 b);
/// ```
pub extern "C" fn sdl_MapRGB(
  format : SDL_PixelFormatDetails,
  palette : SDL_Palette,
  r : UInt,
  g : UInt,
  b : UInt,
) -> UInt = "SDL_MapRGB"

///|
/// Map an RGBA quadruple to a pixel value for a given pixel format.
/// 
/// This function maps the RGBA color value to the specified pixel format and
/// returns the pixel value best approximating the given RGBA color value for
/// the given pixel format.
/// 
/// If the specified pixel format has no alpha component the alpha value will
/// be ignored (as it will be in formats with a palette).
/// 
/// If the format has a palette (8-bit) the index of the closest matching color
/// in the palette will be returned.
/// 
/// If the pixel format bpp (color depth) is less than 32-bpp then the unused
/// upper bits of the return value can safely be ignored (e.g., with a 16-bpp
/// format the return value can be assigned to a Uint16, and similarly a Uint8
/// for an 8-bpp format).
/// 
/// @param format a pointer to SDL_PixelFormatDetails describing the pixel
///               format.
/// @param palette an optional palette for indexed formats, may be NULL.
/// @param r the red component of the pixel in the range 0-255.
/// @param g the green component of the pixel in the range 0-255.
/// @param b the blue component of the pixel in the range 0-255.
/// @param a the alpha component of the pixel in the range 0-255.
/// @return a pixel value.
/// 
/// @threadsafety It is safe to call this function from any thread, as long as
///               the palette is not modified.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GetPixelFormatDetails
/// @see SDL_GetRGBA
/// @see SDL_MapRGB
/// @see SDL_MapSurfaceRGBA
/// 
/// ```c
/// extern SDL_DECLSPEC Uint32 SDLCALL SDL_MapRGBA(const SDL_PixelFormatDetails *format, const SDL_Palette *palette, Uint8 r, Uint8 g, Uint8 b, Uint8 a);
/// ```
pub extern "C" fn sdl_MapRGBA(
  format : SDL_PixelFormatDetails,
  palette : SDL_Palette,
  r : UInt,
  g : UInt,
  b : UInt,
  a : UInt,
) -> UInt = "SDL_MapRGBA"

///|
/// Get RGB values from a pixel in the specified format.
/// 
/// This function uses the entire 8-bit [0..255] range when converting color
/// components from pixel formats with less than 8-bits per RGB component
/// (e.g., a completely white pixel in 16-bit RGB565 format would return [0xff,
/// 0xff, 0xff] not [0xf8, 0xfc, 0xf8]).
/// 
/// @param pixelvalue a pixel value.
/// @param format a pointer to SDL_PixelFormatDetails describing the pixel
///               format.
/// @param palette an optional palette for indexed formats, may be NULL.
/// @param r a pointer filled in with the red component, may be NULL.
/// @param g a pointer filled in with the green component, may be NULL.
/// @param b a pointer filled in with the blue component, may be NULL.
/// 
/// @threadsafety It is safe to call this function from any thread, as long as
///               the palette is not modified.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GetPixelFormatDetails
/// @see SDL_GetRGBA
/// @see SDL_MapRGB
/// @see SDL_MapRGBA
/// 
/// ```c
/// extern SDL_DECLSPEC void SDLCALL SDL_GetRGB(Uint32 pixelvalue, const SDL_PixelFormatDetails *format, const SDL_Palette *palette, Uint8 *r, Uint8 *g, Uint8 *b);
/// ```
#owned(r, g, b)
pub extern "C" fn sdl_GetRGB(
  pixelvalue : UInt,
  format : SDL_PixelFormatDetails,
  palette : SDL_Palette,
  r : FixedArray[UInt],
  g : FixedArray[UInt],
  b : FixedArray[UInt],
) = "SDL_GetRGB"

///|
/// Get RGBA values from a pixel in the specified format.
/// 
/// This function uses the entire 8-bit [0..255] range when converting color
/// components from pixel formats with less than 8-bits per RGB component
/// (e.g., a completely white pixel in 16-bit RGB565 format would return [0xff,
/// 0xff, 0xff] not [0xf8, 0xfc, 0xf8]).
/// 
/// If the surface has no alpha component, the alpha will be returned as 0xff
/// (100% opaque).
/// 
/// @param pixelvalue a pixel value.
/// @param format a pointer to SDL_PixelFormatDetails describing the pixel
///               format.
/// @param palette an optional palette for indexed formats, may be NULL.
/// @param r a pointer filled in with the red component, may be NULL.
/// @param g a pointer filled in with the green component, may be NULL.
/// @param b a pointer filled in with the blue component, may be NULL.
/// @param a a pointer filled in with the alpha component, may be NULL.
/// 
/// @threadsafety It is safe to call this function from any thread, as long as
///               the palette is not modified.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GetPixelFormatDetails
/// @see SDL_GetRGB
/// @see SDL_MapRGB
/// @see SDL_MapRGBA
/// 
/// ```c
/// extern SDL_DECLSPEC void SDLCALL SDL_GetRGBA(Uint32 pixelvalue, const SDL_PixelFormatDetails *format, const SDL_Palette *palette, Uint8 *r, Uint8 *g, Uint8 *b, Uint8 *a);
/// ```
#owned(r, g, b, a)
pub extern "C" fn sdl_GetRGBA(
  pixelvalue : UInt,
  format : SDL_PixelFormatDetails,
  palette : SDL_Palette,
  r : FixedArray[UInt],
  g : FixedArray[UInt],
  b : FixedArray[UInt],
  a : FixedArray[UInt],
) = "SDL_GetRGBA"
