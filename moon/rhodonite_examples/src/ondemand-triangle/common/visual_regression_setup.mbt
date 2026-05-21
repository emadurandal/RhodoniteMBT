/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Builds on-demand triangle state for visual regression render targets.
pub fn create_demo_state_for_device(
  device : @wgpu.GPUDevice,
  queue : @wgpu.GPUQueue,
  format : String,
  context? : @wgpu.GPUCanvasContext? = None,
) -> DemoState {
  let pipeline = create_pipeline(device, format)
  let uniform_buffer = device.create_buffer(
    16UL,
    @wgpu.GPU_BUFFER_USAGE_UNIFORM | @wgpu.GPU_BUFFER_USAGE_COPY_DST,
  )
  let bind_group_layout = pipeline.get_bind_group_layout(0U)
  let bind_group = device.create_bind_group({
    layout: bind_group_layout,
    entries: [
      {
        binding: 0U,
        resource: @wgpu.GPUBindingResource::Buffer(uniform_buffer),
      },
    ],
  })
  let demo_state = {
    context,
    device,
    queue,
    pipeline,
    uniform_buffer,
    bind_group_layout,
    bind_group,
    angle: 0.0,
  }
  write_angle_uniform(demo_state)
  demo_state
}
