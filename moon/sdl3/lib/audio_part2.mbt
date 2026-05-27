/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

/// 
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
///

///|
/// Set a callback that runs when data is requested from an audio stream.
/// 
/// This callback is called _before_ data is obtained from the stream, giving
/// the callback the chance to add more on-demand.
/// 
/// @param stream the audio stream to set the new callback on.
/// @param callback the new callback function to call when data is requested
///                 from the stream.
/// @param userdata an opaque pointer provided to the callback for its own
///                 personal use.
/// @return true on success or false on failure.
/// 
/// @threadsafety It is safe to call this function from any thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_SetAudioStreamPutCallback
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetAudioStreamGetCallback(SDL_AudioStream *stream, SDL_AudioStreamCallback callback, void *userdata);
/// ```
pub extern "C" fn sdl_SetAudioStreamGetCallback(
  stream : SDL_AudioStream,
  callback : SDL_AudioStreamCallback,
  userdata : VoidPtr,
) -> Bool = "SDL_SetAudioStreamGetCallback"

///|
/// Set a callback that runs when data is added to an audio stream.
/// 
/// This callback is called _after_ the data is added to the stream, giving the
/// callback the chance to obtain it immediately.
/// 
/// @param stream the audio stream to set the new callback on.
/// @param callback the new callback function to call when data is added to the
///                 stream.
/// @param userdata an opaque pointer provided to the callback for its own
///                 personal use.
/// @return true on success or false on failure.
/// 
/// @threadsafety It is safe to call this function from any thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_SetAudioStreamGetCallback
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_SetAudioStreamPutCallback(SDL_AudioStream *stream, SDL_AudioStreamCallback callback, void *userdata);
/// ```
pub extern "C" fn sdl_SetAudioStreamPutCallback(
  stream : SDL_AudioStream,
  callback : SDL_AudioStreamCallback,
  userdata : VoidPtr,
) -> Bool = "SDL_SetAudioStreamPutCallback"

///|
/// Free an audio stream.
/// 
/// This will release all allocated data, including any audio that is still
/// queued. You do not need to manually clear the stream first.
/// 
/// @param stream the audio stream to destroy.
/// 
/// @threadsafety It is safe to call this function from any thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_CreateAudioStream
/// 
/// ```c
/// extern SDL_DECLSPEC void SDLCALL SDL_DestroyAudioStream(SDL_AudioStream *stream);
/// ```
pub extern "C" fn sdl_DestroyAudioStream(stream : SDL_AudioStream) = "SDL_DestroyAudioStream"

///|
/// Convenience function for straightforward audio init for the common case.
/// 
/// If all your app intends to do is provide a single source of PCM audio, this
/// function allows you to do all your audio setup in a single call.
/// 
/// @param devid an audio device to open, or SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK
///              or SDL_AUDIO_DEVICE_DEFAULT_RECORDING.
/// @param spec the audio stream's data format. Can be NULL.
/// @param callback a callback where the app will provide new data for
///                 playback, or receive new data for recording. Can be NULL.
/// @param userdata app-controlled pointer passed to callback. Can be NULL.
/// @return an audio stream on success, ready to use, or NULL on failure.
/// 
/// @threadsafety It is safe to call this function from any thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_GetAudioStreamDevice
/// @see SDL_ResumeAudioStreamDevice
/// 
/// ```c
/// extern SDL_DECLSPEC SDL_AudioStream * SDLCALL SDL_OpenAudioDeviceStream(SDL_AudioDeviceID devid, const SDL_AudioSpec *spec, SDL_AudioStreamCallback callback, void *userdata);
/// ```
#owned(spec)
pub extern "C" fn sdl_OpenAudioDeviceStream(
  devid : SDL_AudioDeviceID,
  spec : FixedArray[SDL_AudioSpec],
  callback : SDL_AudioStreamCallback,
  userdata : VoidPtr,
) -> SDL_AudioStream = "SDL_OpenAudioDeviceStream"

///|
/// Load the audio data of a WAVE file into memory.
/// 
/// @param path the file path of the WAV file to open.
/// @param spec a pointer to an SDL_AudioSpec that will be set to the WAVE
///             data's format details on successful return.
/// @param audio_buf a pointer filled with the audio data, allocated by the
///                  function.
/// @param audio_len a pointer filled with the length of the audio data buffer
///                  in bytes.
/// @return true on success.
/// 
/// @threadsafety It is safe to call this function from any thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// @see SDL_free
/// @see SDL_LoadWAV_IO
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_LoadWAV(const char *path, SDL_AudioSpec *spec, Uint8 **audio_buf, Uint32 *audio_len);
/// ```
pub fn sdl_LoadWAV(
  path : String,
  spec : FixedArray[SDL_AudioSpec],
  audio_buf : FixedArray[FixedArray[UInt]],
  audio_len : FixedArray[UInt],
) -> Bool {
  __sdl_LoadWAV(string_to_cbytes(path), spec, audio_buf, audio_len)
}

///|
#owned(path, spec, audio_buf, audio_len)
extern "C" fn __sdl_LoadWAV(
  path : Bytes,
  spec : FixedArray[SDL_AudioSpec],
  audio_buf : FixedArray[FixedArray[UInt]],
  audio_len : FixedArray[UInt],
) -> Bool = "SDL_LoadWAV"

///|
/// Mix audio data in a specified format.
/// 
/// This takes an audio buffer `src` of `len` bytes of `format` data and mixes
/// it into `dst`, performing addition, volume adjustment, and overflow
/// clipping.
/// 
/// @param dst the destination for the mixed audio.
/// @param src the source audio buffer to be mixed.
/// @param format the SDL_AudioFormat structure representing the desired audio
///               format.
/// @param len the length of the audio buffer in bytes.
/// @param volume ranges from 0.0 - 1.0, and should be set to 1.0 for full
///               audio volume.
/// @return true on success or false on failure.
/// 
/// @threadsafety It is safe to call this function from any thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_MixAudio(Uint8 *dst, const Uint8 *src, SDL_AudioFormat format, Uint32 len, float volume);
/// ```
#owned(dst, src)
pub extern "C" fn sdl_MixAudio(
  dst : FixedArray[UInt],
  src : FixedArray[UInt],
  format : SDL_AudioFormat,
  len : UInt,
  volume : Float,
) -> Bool = "SDL_MixAudio"

///|
/// Convert some audio data of one format to another format.
/// 
/// @param src_spec the format details of the input audio.
/// @param src_data the audio data to be converted.
/// @param src_len the len of src_data.
/// @param dst_spec the format details of the output audio.
/// @param dst_data will be filled with a pointer to converted audio data,
///                 which should be freed with SDL_free(). On error, it will be
///                 NULL.
/// @param dst_len will be filled with the len of dst_data.
/// @return true on success or false on failure.
/// 
/// @threadsafety It is safe to call this function from any thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC bool SDLCALL SDL_ConvertAudioSamples(const SDL_AudioSpec *src_spec, const Uint8 *src_data, int src_len, const SDL_AudioSpec *dst_spec, Uint8 **dst_data, int *dst_len);
/// ```
#owned(src_spec, src_data, dst_spec, dst_data, dst_len)
pub extern "C" fn sdl_ConvertAudioSamples(
  src_spec : FixedArray[SDL_AudioSpec],
  src_data : FixedArray[UInt],
  src_len : Int,
  dst_spec : FixedArray[SDL_AudioSpec],
  dst_data : FixedArray[FixedArray[UInt]],
  dst_len : FixedArray[Int],
) -> Bool = "SDL_ConvertAudioSamples"

///|
/// Get the human readable name of an audio format.
/// 
/// @param format the audio format to query.
/// @return the human readable name of the specified audio format or
///          "SDL_AUDIO_UNKNOWN" if the format isn't recognized.
/// 
/// @threadsafety It is safe to call this function from any thread.
/// 
/// @since This function is available since SDL 3.2.0.
/// 
/// ```c
/// extern SDL_DECLSPEC const char * SDLCALL SDL_GetAudioFormatName(SDL_AudioFormat format);
/// ```
pub fn sdl_GetAudioFormatName(format : SDL_AudioFormat) -> String {
  let cres = __sdl_GetAudioFormatName(format)
  let res = cres.to_string()
  free_cstr(cres)
  res
}

///|
extern "C" fn __sdl_GetAudioFormatName(format : SDL_AudioFormat) -> CStr = "SDL_GetAudioFormatName"
