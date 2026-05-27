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
/// Use this function to read 16 bits of little-endian data from an
/// SDL_IOStream and return in native format.
/// 
/// SDL byteswaps the data only if necessary, so the data returned will be in
/// the native byte order.
/// 
/// This function will return false when the data stream is completely read,
/// and SDL_GetIOStatus() will return SDL_IO_STATUS_EOF. If false is returned
/// and the stream is not at EOF, SDL_GetIOStatus() will return a different
/// error value and SDL_GetError() will offer a human-readable message.
/// 
/// @param src the stream from which to read data.
/// @param value a pointer filled in with the data read.
/// @return true on successful read or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_ReadS16LE(SDL_IOStream *src, Sint16 *value);
/// ```
#owned(value)
pub extern "C" fn sdl_ReadS16LE(
  src : SDL_IOStream,
  value : FixedArray[Int],
) -> Bool = "SDL_ReadS16LE"

///|
/// Use this function to read 16 bits of big-endian data from an SDL_IOStream
/// and return in native format.
/// 
/// SDL byteswaps the data only if necessary, so the data returned will be in
/// the native byte order.
/// 
/// This function will return false when the data stream is completely read,
/// and SDL_GetIOStatus() will return SDL_IO_STATUS_EOF. If false is returned
/// and the stream is not at EOF, SDL_GetIOStatus() will return a different
/// error value and SDL_GetError() will offer a human-readable message.
/// 
/// @param src the stream from which to read data.
/// @param value a pointer filled in with the data read.
/// @return true on successful read or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_ReadU16BE(SDL_IOStream *src, Uint16 *value);
/// ```
#owned(value)
pub extern "C" fn sdl_ReadU16BE(
  src : SDL_IOStream,
  value : FixedArray[UInt],
) -> Bool = "SDL_ReadU16BE"

///|
/// Use this function to read 16 bits of big-endian data from an SDL_IOStream
/// and return in native format.
/// 
/// SDL byteswaps the data only if necessary, so the data returned will be in
/// the native byte order.
/// 
/// This function will return false when the data stream is completely read,
/// and SDL_GetIOStatus() will return SDL_IO_STATUS_EOF. If false is returned
/// and the stream is not at EOF, SDL_GetIOStatus() will return a different
/// error value and SDL_GetError() will offer a human-readable message.
/// 
/// @param src the stream from which to read data.
/// @param value a pointer filled in with the data read.
/// @return true on successful read or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_ReadS16BE(SDL_IOStream *src, Sint16 *value);
/// ```
#owned(value)
pub extern "C" fn sdl_ReadS16BE(
  src : SDL_IOStream,
  value : FixedArray[Int],
) -> Bool = "SDL_ReadS16BE"

///|
/// Use this function to read 32 bits of little-endian data from an
/// SDL_IOStream and return in native format.
/// 
/// SDL byteswaps the data only if necessary, so the data returned will be in
/// the native byte order.
/// 
/// This function will return false when the data stream is completely read,
/// and SDL_GetIOStatus() will return SDL_IO_STATUS_EOF. If false is returned
/// and the stream is not at EOF, SDL_GetIOStatus() will return a different
/// error value and SDL_GetError() will offer a human-readable message.
/// 
/// @param src the stream from which to read data.
/// @param value a pointer filled in with the data read.
/// @return true on successful read or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_ReadU32LE(SDL_IOStream *src, Uint32 *value);
/// ```
#owned(value)
pub extern "C" fn sdl_ReadU32LE(
  src : SDL_IOStream,
  value : FixedArray[UInt],
) -> Bool = "SDL_ReadU32LE"

///|
/// Use this function to read 32 bits of little-endian data from an
/// SDL_IOStream and return in native format.
/// 
/// SDL byteswaps the data only if necessary, so the data returned will be in
/// the native byte order.
/// 
/// This function will return false when the data stream is completely read,
/// and SDL_GetIOStatus() will return SDL_IO_STATUS_EOF. If false is returned
/// and the stream is not at EOF, SDL_GetIOStatus() will return a different
/// error value and SDL_GetError() will offer a human-readable message.
/// 
/// @param src the stream from which to read data.
/// @param value a pointer filled in with the data read.
/// @return true on successful read or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_ReadS32LE(SDL_IOStream *src, Sint32 *value);
/// ```
#owned(value)
pub extern "C" fn sdl_ReadS32LE(
  src : SDL_IOStream,
  value : FixedArray[Int],
) -> Bool = "SDL_ReadS32LE"

///|
/// Use this function to read 32 bits of big-endian data from an SDL_IOStream
/// and return in native format.
/// 
/// SDL byteswaps the data only if necessary, so the data returned will be in
/// the native byte order.
/// 
/// This function will return false when the data stream is completely read,
/// and SDL_GetIOStatus() will return SDL_IO_STATUS_EOF. If false is returned
/// and the stream is not at EOF, SDL_GetIOStatus() will return a different
/// error value and SDL_GetError() will offer a human-readable message.
/// 
/// @param src the stream from which to read data.
/// @param value a pointer filled in with the data read.
/// @return true on successful read or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_ReadU32BE(SDL_IOStream *src, Uint32 *value);
/// ```
#owned(value)
pub extern "C" fn sdl_ReadU32BE(
  src : SDL_IOStream,
  value : FixedArray[UInt],
) -> Bool = "SDL_ReadU32BE"

///|
/// Use this function to read 32 bits of big-endian data from an SDL_IOStream
/// and return in native format.
/// 
/// SDL byteswaps the data only if necessary, so the data returned will be in
/// the native byte order.
/// 
/// This function will return false when the data stream is completely read,
/// and SDL_GetIOStatus() will return SDL_IO_STATUS_EOF. If false is returned
/// and the stream is not at EOF, SDL_GetIOStatus() will return a different
/// error value and SDL_GetError() will offer a human-readable message.
/// 
/// @param src the stream from which to read data.
/// @param value a pointer filled in with the data read.
/// @return true on successful read or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_ReadS32BE(SDL_IOStream *src, Sint32 *value);
/// ```
#owned(value)
pub extern "C" fn sdl_ReadS32BE(
  src : SDL_IOStream,
  value : FixedArray[Int],
) -> Bool = "SDL_ReadS32BE"

///|
/// Use this function to read 64 bits of little-endian data from an
/// SDL_IOStream and return in native format.
/// 
/// SDL byteswaps the data only if necessary, so the data returned will be in
/// the native byte order.
/// 
/// This function will return false when the data stream is completely read,
/// and SDL_GetIOStatus() will return SDL_IO_STATUS_EOF. If false is returned
/// and the stream is not at EOF, SDL_GetIOStatus() will return a different
/// error value and SDL_GetError() will offer a human-readable message.
/// 
/// @param src the stream from which to read data.
/// @param value a pointer filled in with the data read.
/// @return true on successful read or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_ReadU64LE(SDL_IOStream *src, Uint64 *value);
/// ```
#owned(value)
pub extern "C" fn sdl_ReadU64LE(
  src : SDL_IOStream,
  value : FixedArray[UInt64],
) -> Bool = "SDL_ReadU64LE"

///|
/// Use this function to read 64 bits of little-endian data from an
/// SDL_IOStream and return in native format.
/// 
/// SDL byteswaps the data only if necessary, so the data returned will be in
/// the native byte order.
/// 
/// This function will return false when the data stream is completely read,
/// and SDL_GetIOStatus() will return SDL_IO_STATUS_EOF. If false is returned
/// and the stream is not at EOF, SDL_GetIOStatus() will return a different
/// error value and SDL_GetError() will offer a human-readable message.
/// 
/// @param src the stream from which to read data.
/// @param value a pointer filled in with the data read.
/// @return true on successful read or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_ReadS64LE(SDL_IOStream *src, Sint64 *value);
/// ```
#owned(value)
pub extern "C" fn sdl_ReadS64LE(
  src : SDL_IOStream,
  value : FixedArray[Int64],
) -> Bool = "SDL_ReadS64LE"

///|
/// Use this function to read 64 bits of big-endian data from an SDL_IOStream
/// and return in native format.
/// 
/// SDL byteswaps the data only if necessary, so the data returned will be in
/// the native byte order.
/// 
/// This function will return false when the data stream is completely read,
/// and SDL_GetIOStatus() will return SDL_IO_STATUS_EOF. If false is returned
/// and the stream is not at EOF, SDL_GetIOStatus() will return a different
/// error value and SDL_GetError() will offer a human-readable message.
/// 
/// @param src the stream from which to read data.
/// @param value a pointer filled in with the data read.
/// @return true on successful read or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_ReadU64BE(SDL_IOStream *src, Uint64 *value);
/// ```
#owned(value)
pub extern "C" fn sdl_ReadU64BE(
  src : SDL_IOStream,
  value : FixedArray[UInt64],
) -> Bool = "SDL_ReadU64BE"

///|
/// Use this function to read 64 bits of big-endian data from an SDL_IOStream
/// and return in native format.
/// 
/// SDL byteswaps the data only if necessary, so the data returned will be in
/// the native byte order.
/// 
/// This function will return false when the data stream is completely read,
/// and SDL_GetIOStatus() will return SDL_IO_STATUS_EOF. If false is returned
/// and the stream is not at EOF, SDL_GetIOStatus() will return a different
/// error value and SDL_GetError() will offer a human-readable message.
/// 
/// @param src the stream from which to read data.
/// @param value a pointer filled in with the data read.
/// @return true on successful read or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_ReadS64BE(SDL_IOStream *src, Sint64 *value);
/// ```
#owned(value)
pub extern "C" fn sdl_ReadS64BE(
  src : SDL_IOStream,
  value : FixedArray[Int64],
) -> Bool = "SDL_ReadS64BE"

/// Write endian functions

///|
/// Use this function to write a byte to an SDL_IOStream.
/// 
/// @param dst the SDL_IOStream to write to.
/// @param value the byte value to write.
/// @return true on successful write or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_WriteU8(SDL_IOStream *dst, Uint8 value);
/// ```
pub extern "C" fn sdl_WriteU8(dst : SDL_IOStream, value : Byte) -> Bool = "SDL_WriteU8"

///|
/// Use this function to write a signed byte to an SDL_IOStream.
/// 
/// @param dst the SDL_IOStream to write to.
/// @param value the byte value to write.
/// @return true on successful write or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_WriteS8(SDL_IOStream *dst, Sint8 value);
/// ```
pub extern "C" fn sdl_WriteS8(dst : SDL_IOStream, value : Byte) -> Bool = "SDL_WriteS8"

///|
/// Use this function to write 16 bits in native format to an SDL_IOStream as
/// little-endian data.
/// 
/// SDL byteswaps the data only if necessary, so the application always
/// specifies native format, and the data written will be in little-endian
/// format.
/// 
/// @param dst the stream to which data will be written.
/// @param value the data to be written, in native format.
/// @return true on successful write or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_WriteU16LE(SDL_IOStream *dst, Uint16 value);
/// ```
pub extern "C" fn sdl_WriteU16LE(dst : SDL_IOStream, value : UInt) -> Bool = "SDL_WriteU16LE"

///|
/// Use this function to write 16 bits in native format to an SDL_IOStream as
/// little-endian data.
/// 
/// SDL byteswaps the data only if necessary, so the application always
/// specifies native format, and the data written will be in little-endian
/// format.
/// 
/// @param dst the stream to which data will be written.
/// @param value the data to be written, in native format.
/// @return true on successful write or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_WriteS16LE(SDL_IOStream *dst, Sint16 value);
/// ```
pub extern "C" fn sdl_WriteS16LE(dst : SDL_IOStream, value : Int) -> Bool = "SDL_WriteS16LE"

///|
/// Use this function to write 16 bits in native format to an SDL_IOStream as
/// big-endian data.
/// 
/// SDL byteswaps the data only if necessary, so the application always
/// specifies native format, and the data written will be in big-endian format.
/// 
/// @param dst the stream to which data will be written.
/// @param value the data to be written, in native format.
/// @return true on successful write or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_WriteU16BE(SDL_IOStream *dst, Uint16 value);
/// ```
pub extern "C" fn sdl_WriteU16BE(dst : SDL_IOStream, value : UInt) -> Bool = "SDL_WriteU16BE"

///|
/// Use this function to write 16 bits in native format to an SDL_IOStream as
/// big-endian data.
/// 
/// SDL byteswaps the data only if necessary, so the application always
/// specifies native format, and the data written will be in big-endian format.
/// 
/// @param dst the stream to which data will be written.
/// @param value the data to be written, in native format.
/// @return true on successful write or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_WriteS16BE(SDL_IOStream *dst, Sint16 value);
/// ```
pub extern "C" fn sdl_WriteS16BE(dst : SDL_IOStream, value : Int) -> Bool = "SDL_WriteS16BE"

///|
/// Use this function to write 32 bits in native format to an SDL_IOStream as
/// little-endian data.
/// 
/// SDL byteswaps the data only if necessary, so the application always
/// specifies native format, and the data written will be in little-endian
/// format.
/// 
/// @param dst the stream to which data will be written.
/// @param value the data to be written, in native format.
/// @return true on successful write or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_WriteU32LE(SDL_IOStream *dst, Uint32 value);
/// ```
pub extern "C" fn sdl_WriteU32LE(dst : SDL_IOStream, value : UInt) -> Bool = "SDL_WriteU32LE"

///|
/// Use this function to write 32 bits in native format to an SDL_IOStream as
/// little-endian data.
/// 
/// SDL byteswaps the data only if necessary, so the application always
/// specifies native format, and the data written will be in little-endian
/// format.
/// 
/// @param dst the stream to which data will be written.
/// @param value the data to be written, in native format.
/// @return true on successful write or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_WriteS32LE(SDL_IOStream *dst, Sint32 value);
/// ```
pub extern "C" fn sdl_WriteS32LE(dst : SDL_IOStream, value : Int) -> Bool = "SDL_WriteS32LE"

///|
/// Use this function to write 32 bits in native format to an SDL_IOStream as
/// big-endian data.
/// 
/// SDL byteswaps the data only if necessary, so the application always
/// specifies native format, and the data written will be in big-endian format.
/// 
/// @param dst the stream to which data will be written.
/// @param value the data to be written, in native format.
/// @return true on successful write or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_WriteU32BE(SDL_IOStream *dst, Uint32 value);
/// ```
pub extern "C" fn sdl_WriteU32BE(dst : SDL_IOStream, value : UInt) -> Bool = "SDL_WriteU32BE"

///|
/// Use this function to write 32 bits in native format to an SDL_IOStream as
/// big-endian data.
/// 
/// SDL byteswaps the data only if necessary, so the application always
/// specifies native format, and the data written will be in big-endian format.
/// 
/// @param dst the stream to which data will be written.
/// @param value the data to be written, in native format.
/// @return true on successful write or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_WriteS32BE(SDL_IOStream *dst, Sint32 value);
/// ```
pub extern "C" fn sdl_WriteS32BE(dst : SDL_IOStream, value : Int) -> Bool = "SDL_WriteS32BE"

///|
/// Use this function to write 64 bits in native format to an SDL_IOStream as
/// little-endian data.
/// 
/// SDL byteswaps the data only if necessary, so the application always
/// specifies native format, and the data written will be in little-endian
/// format.
/// 
/// @param dst the stream to which data will be written.
/// @param value the data to be written, in native format.
/// @return true on successful write or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_WriteU64LE(SDL_IOStream *dst, Uint64 value);
/// ```
pub extern "C" fn sdl_WriteU64LE(dst : SDL_IOStream, value : UInt64) -> Bool = "SDL_WriteU64LE"

///|
/// Use this function to write 64 bits in native format to an SDL_IOStream as
/// little-endian data.
/// 
/// SDL byteswaps the data only if necessary, so the application always
/// specifies native format, and the data written will be in little-endian
/// format.
/// 
/// @param dst the stream to which data will be written.
/// @param value the data to be written, in native format.
/// @return true on successful write or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_WriteS64LE(SDL_IOStream *dst, Sint64 value);
/// ```
pub extern "C" fn sdl_WriteS64LE(dst : SDL_IOStream, value : Int64) -> Bool = "SDL_WriteS64LE"

///|
/// Use this function to write 64 bits in native format to an SDL_IOStream as
/// big-endian data.
/// 
/// SDL byteswaps the data only if necessary, so the application always
/// specifies native format, and the data written will be in big-endian format.
/// 
/// @param dst the stream to which data will be written.
/// @param value the data to be written, in native format.
/// @return true on successful write or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_WriteU64BE(SDL_IOStream *dst, Uint64 value);
/// ```
pub extern "C" fn sdl_WriteU64BE(dst : SDL_IOStream, value : UInt64) -> Bool = "SDL_WriteU64BE"

///|
/// Use this function to write 64 bits in native format to an SDL_IOStream as
/// big-endian data.
/// 
/// SDL byteswaps the data only if necessary, so the application always
/// specifies native format, and the data written will be in big-endian format.
/// 
/// @param dst the stream to which data will be written.
/// @param value the data to be written, in native format.
/// @return true on successful write or false on failure; call SDL_GetError()
///          for more information.
/// 
/// @threadsafety This function is not thread safe.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_WriteS64BE(SDL_IOStream *dst, Sint64 value);
/// ```
pub extern "C" fn sdl_WriteS64BE(dst : SDL_IOStream, value : Int64) -> Bool = "SDL_WriteS64BE"
