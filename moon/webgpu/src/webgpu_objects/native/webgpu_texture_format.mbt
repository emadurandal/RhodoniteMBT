///|
fn texture_format_from_string(format : String) -> @wgpu.TextureFormat {
  match format {
    "rgba8unorm" | "rgba8-unorm" =>
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)
    "bgra8unorm" | "bgra8-unorm" =>
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_BGRA8_UNORM)
    "bgra8unorm-srgb" | "bgra8-unorm-srgb" =>
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB)
    "rgba8unorm-srgb" | "rgba8-unorm-srgb" =>
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB)
    "depth24plus" =>
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_DEPTH24_PLUS)
    _ => @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_BGRA8_UNORM)
  }
}

///|
fn texture_format_to_string(format : @wgpu.TextureFormat) -> String {
  match format.to_u32() {
    @wgpu.TEXTURE_FORMAT_BGRA8_UNORM => "bgra8unorm"
    @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB => "bgra8unorm-srgb"
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM => "rgba8unorm"
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB => "rgba8unorm-srgb"
    _ => ""
  }
}
