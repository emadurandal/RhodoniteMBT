///|
/// Linux swapchain relay: render offscreen, then blit to the swapchain on present.
///
/// Native visual regression renders to `create_rgba8_render_texture` successfully; some
/// Wayland/Vulkan swapchains accept clears but not ECS geometry when used as the sole
/// color attachment.

///|
struct LinuxSwapchainRelay {
  texture : GPUTexture
  width : UInt
  height : UInt
  swap_format : String
}

///|
/// WGSL color target format for relay rendering; must match the relay texture.
fn linux_swapchain_relay_render_format(swap_format : String) -> String {
  swap_format
}

///|
/// Releases relay GPU resources.
fn linux_swapchain_relay_release(relay : LinuxSwapchainRelay) -> Unit {
  relay.texture.raw.release()
}

///|
/// Builds or rebuilds relay resources for the configured swapchain size and format.
fn linux_swapchain_relay_ensure(
  relay : @ref.Ref[LinuxSwapchainRelay?],
  device : WebGPUDevice,
  width : UInt,
  height : UInt,
  swap_format : String,
) -> Unit {
  match relay.val {
    Some(existing) =>
      if existing.width == width &&
        existing.height == height &&
        existing.swap_format == swap_format {
        return
      } else {
        linux_swapchain_relay_release(existing)
      }
    None => ()
  }
  let wgpu_dev = device.device.raw
  let usage = @wgpu.TextureUsage::from_u64(
    @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT | @wgpu.TEXTURE_USAGE_COPY_SRC,
  )
  let texture = GPUTexture::{
    raw: wgpu_dev.create_texture_u32(
      width,
      height,
      1U,
      usage,
      @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
      texture_format_from_string(swap_format),
    ),
  }
  relay.val = Some({ texture, width, height, swap_format })
}

///|
/// Blits the relay texture into the acquired swapchain texture and submits the pass.
fn linux_swapchain_relay_blit_to_swapchain(
  relay : LinuxSwapchainRelay,
  swap_texture : @wgpu.Texture,
  device : WebGPUDevice,
  queue : WebGPUQueue,
) -> Unit {
  let _ = device.device.raw.poll(wait=true)
  let encoder = device.device.raw.create_command_encoder()
  encoder.copy_texture_to_texture_rgba8(
    relay.texture.raw,
    swap_texture,
    relay.width,
    relay.height,
  )
  let command_buffer = encoder.finish()
  queue.queue.raw.submit_one(command_buffer)
  encoder.release()
  let _ = device.device.raw.poll(wait=true)
}

///|
/// Ensures the relay texture matches the acquired swapchain texture before rendering.
fn linux_swapchain_relay_ensure_for_swap_texture(
  relay_slot : @ref.Ref[LinuxSwapchainRelay?],
  swap_texture : @wgpu.Texture,
  device : WebGPUDevice,
  width : UInt,
  height : UInt,
) -> Unit {
  let swap_format = texture_format_to_string(swap_texture.format_u32())
  linux_swapchain_relay_ensure(relay_slot, device, width, height, swap_format)
}

///|
/// Returns the relay render target texture when relay mode is active.
fn linux_swapchain_relay_render_texture(
  relay : LinuxSwapchainRelay,
) -> WebGPUTexture {
  WebGPUTexture::new(relay.texture)
}
