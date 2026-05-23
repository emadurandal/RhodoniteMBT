/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Default fallback type for browser GPU objects.
pub type GPU

///|
/// Default fallback type for browser GPU adapters.
pub type GPUAdapter

///|
/// Default fallback type for browser GPU devices.
pub type GPUDevice

///|
/// Default fallback type for browser GPU queues.
pub type GPUQueue

///|
/// Default fallback type for browser canvas contexts.
pub type GPUCanvasContext

///|
/// Default fallback type for browser GPU textures.
pub type GPUTexture

///|
/// Default fallback type for browser GPU texture views.
pub type GPUTextureView

///|
/// Default fallback type for browser GPU samplers.
pub type GPUSampler

///|
/// Default fallback type for browser GPU external textures.
pub type GPUExternalTexture

///|
/// Default fallback type for browser GPU shader modules.
pub type GPUShaderModule

///|
/// Default fallback type for browser GPU render pipelines.
pub type GPURenderPipeline

///|
/// Default fallback type for browser GPU command encoders.
pub type GPUCommandEncoder

///|
/// Default fallback type for browser GPU render pass encoders.
pub type GPURenderPassEncoder

///|
/// Default fallback type for browser GPU command buffers.
pub type GPUCommandBuffer

///|
/// Default fallback type for browser GPU buffers.
pub type GPUBuffer

///|
/// Default fallback type for browser GPU bind group entries.
pub type GPUBindGroupEntry

///|
/// Default fallback type for browser GPU bind group layouts.
pub type GPUBindGroupLayout

///|
/// Default fallback type for browser GPU pipeline layouts.
pub type GPUPipelineLayout

///|
/// Default fallback type for browser GPU bind groups.
pub type GPUBindGroup

///|
/// Default fallback type for browser canvas elements.
pub type HTMLCanvasElement

///|
/// Default fallback type for native opaque pointers.
pub type OpaquePtr

///|
/// Default fallback type for cross-backend WebGPU instances.
pub type WebGPUInstance

///|
/// Default fallback type for cross-backend WebGPU adapters.
pub type WebGPUAdapter

///|
/// Default fallback type for cross-backend WebGPU devices.
pub type WebGPUDevice

///|
/// Default fallback type for cross-backend WebGPU queues.
pub type WebGPUQueue

///|
/// Default fallback type for cross-backend canvas contexts.
pub type WebGPUCanvasContext

///|
/// Default fallback type for cross-backend WebGPU textures.
pub type WebGPUTexture

///|
/// Default fallback type for cross-backend command encoders.
pub type WebGPUCommandEncoder

///|
/// Default fallback type for cross-backend render pass encoders.
pub type WebGPURenderPassEncoder

///|
/// Default fallback type for cross-backend WebGPU contexts.
pub type WebGPUContext

///|
/// Default fallback type for render pass depth stencil attachments.
pub type WebGPURenderPassDepthStencilAttachment

///|
/// Default fallback type for render pass color attachments.
pub type WebGPURenderPassColorAttachment

///|
/// Default fallback type for render pass descriptors.
pub type WebGPURenderPassDescriptor

///|
/// Default fallback type for render pipeline descriptors.
pub type WebGPURenderPipelineDescriptor

///|
/// Aborts if the backend fallback is reached at runtime.
fn[T] unavailable() -> T {
  abort(
    "webgpu_objects default fallback was used; select the js or native implementation with overrides",
  )
}

///|
/// Returns the browser `navigator.gpu` object in real JS builds.
pub fn navigatorGPU() -> GPU {
  unavailable()
}

///|
/// Returns a WebGPU canvas context from a browser canvas in real JS builds.
pub fn canvas_getContext(_canvas : HTMLCanvasElement) -> GPUCanvasContext {
  unavailable()
}

///|
/// Wraps a browser GPU object in real JS builds.
pub fn create_webgpu_instance(_gpu : GPU) -> WebGPUInstance {
  unavailable()
}

///|
/// Creates a native WebGPU instance in real native builds.
pub fn create_native_webgpu_instance() -> WebGPUInstance raise Error {
  unavailable()
}

///|
/// Wraps a browser canvas context in real JS builds.
pub fn create_canvas_context(
  _context : GPUCanvasContext,
) -> WebGPUCanvasContext {
  unavailable()
}

///|
/// Creates a Metal-backed canvas context in real native builds.
pub fn create_metal_canvas_context(
  _instance : WebGPUInstance,
  _canvas : HTMLCanvasElement,
  _width : Int,
  _height : Int,
) -> WebGPUCanvasContext {
  unavailable()
}

///|
/// Reports whether a native canvas context has a null surface.
pub fn webgpu_canvas_context_surface_is_null(
  _context : WebGPUCanvasContext,
) -> Bool {
  unavailable()
}

///|
/// Creates a Wayland-backed canvas context in real native builds.
pub fn create_wayland_canvas_context(
  _instance : WebGPUInstance,
  _display : OpaquePtr,
  _surface : OpaquePtr,
  _width : Int,
  _height : Int,
) -> WebGPUCanvasContext {
  unavailable()
}

///|
/// Creates an Xlib-backed canvas context in real native builds.
pub fn create_xlib_canvas_context(
  _instance : WebGPUInstance,
  _display : OpaquePtr,
  _window : UInt64,
  _width : Int,
  _height : Int,
) -> WebGPUCanvasContext {
  unavailable()
}

///|
/// Requests a native adapter for a canvas in real native builds.
pub fn native_webgpu_instance_request_adapter_for_canvas(
  _instance : WebGPUInstance,
  _context : WebGPUCanvasContext,
) -> WebGPUAdapter raise Error {
  unavailable()
}

///|
/// Creates a cross-backend WebGPU context in real JS/native builds.
pub fn create_webgpu_context(
  _device : WebGPUDevice,
  _context : WebGPUCanvasContext,
  _format : String,
  _queue : WebGPUQueue,
) -> WebGPUContext {
  unavailable()
}

///|
/// Returns the preferred canvas format in real JS/native builds.
pub fn webgpu_instance_get_preferred_canvas_format(
  _instance : WebGPUInstance,
) -> String {
  unavailable()
}

///|
/// Returns the preferred surface format in real native builds.
pub fn webgpu_instance_get_preferred_canvas_format_for_surface(
  _instance : WebGPUInstance,
  _adapter : WebGPUAdapter,
  _context : WebGPUCanvasContext,
) -> String {
  unavailable()
}

///|
/// Requests a browser adapter in real JS builds.
pub async fn webgpu_instance_request_adapter(
  _instance : WebGPUInstance,
) -> WebGPUAdapter {
  unavailable()
}

///|
/// Requests a native adapter in real native builds.
pub fn native_webgpu_instance_request_adapter(
  _instance : WebGPUInstance,
) -> WebGPUAdapter raise Error {
  unavailable()
}

///|
/// Requests a browser device in real JS builds.
pub async fn webgpu_adapter_request_device(
  _adapter : WebGPUAdapter,
) -> WebGPUDevice {
  unavailable()
}

///|
/// Requests a native device in real native builds.
pub fn native_webgpu_adapter_request_device(
  _adapter : WebGPUAdapter,
) -> WebGPUDevice raise Error {
  unavailable()
}

///|
/// Extracts a raw browser GPU device in real JS builds.
pub fn webgpu_device_get(_device : WebGPUDevice) -> GPUDevice {
  unavailable()
}

///|
/// Extracts a wrapped WebGPU queue in real JS/native builds.
pub fn webgpu_device_get_queue(_device : WebGPUDevice) -> WebGPUQueue {
  unavailable()
}

///|
/// Polls a device in real native builds.
pub fn webgpu_device_poll(_device : WebGPUDevice, wait? : Bool) -> Bool {
  ignore(wait)
  unavailable()
}

///|
/// Releases a device in real native builds.
pub fn webgpu_device_release(_device : WebGPUDevice) -> Unit {
  unavailable()
}

///|
/// Configures a canvas context in real JS/native builds.
pub fn webgpu_canvas_context_configure(
  _context : WebGPUCanvasContext,
  _device : GPUDevice,
  _format : String,
) -> Unit {
  unavailable()
}

///|
/// Resizes a canvas context in real JS/native builds.
pub fn webgpu_canvas_context_resize(
  _context : WebGPUCanvasContext,
  _device : GPUDevice,
  _format : String,
  _width : Int,
  _height : Int,
) -> Unit {
  unavailable()
}

///|
/// Returns a canvas context format in real JS/native builds.
pub fn webgpu_canvas_context_get_format(
  _context : WebGPUCanvasContext,
) -> String {
  unavailable()
}

///|
/// Releases a canvas context in real native builds.
pub fn webgpu_canvas_context_release(_context : WebGPUCanvasContext) -> Unit {
  unavailable()
}

///|
/// Requests a native canvas present capture in real native builds.
pub fn native_canvas_present_capture_begin() -> Unit {
  unavailable()
}

///|
/// Takes a native canvas present capture in real native builds.
pub fn native_canvas_present_capture_take() -> Bytes {
  unavailable()
}

///|
/// Releases a queue in real native builds.
pub fn webgpu_queue_release(_queue : WebGPUQueue) -> Unit {
  unavailable()
}

///|
/// Releases an adapter in real native builds.
pub fn webgpu_adapter_release(_adapter : WebGPUAdapter) -> Unit {
  unavailable()
}

///|
/// Processes native instance events in real native builds.
pub fn webgpu_instance_process_events(_instance : WebGPUInstance) -> Unit {
  unavailable()
}

///|
/// Releases an instance in real native builds.
pub fn webgpu_instance_release(_instance : WebGPUInstance) -> Unit {
  unavailable()
}

///|
/// Extracts context fields in real JS/native builds.
pub fn webgpu_context_get(
  _context : WebGPUContext,
) -> (WebGPUDevice, WebGPUCanvasContext, String, WebGPUQueue) {
  unavailable()
}

///|
/// Creates a shader module in real JS/native builds.
pub fn webgpu_device_create_shader_module(
  _device : WebGPUDevice,
  _source : String,
) -> GPUShaderModule {
  unavailable()
}

///|
/// Creates a render pipeline in real JS/native builds.
pub fn webgpu_device_create_render_pipeline(
  _device : WebGPUDevice,
  _layout : GPUPipelineLayout?,
  _vertex : GPUShaderModule,
  _fragment : GPUShaderModule,
  topology~ : @webgpu_enums.GPUPrimitiveTopology,
  formats~ : Array[String],
  vertex_buffers~ : Array[@webgpu_enums.GPUVertexBufferLayout],
  depth_stencil_format~ : String,
) -> GPURenderPipeline {
  ignore(topology)
  ignore(formats)
  ignore(vertex_buffers)
  ignore(depth_stencil_format)
  unavailable()
}

///|
/// Gets a bind group layout in real JS/native builds.
pub fn webgpu_render_pipeline_get_bind_group_layout(
  _pipeline : GPURenderPipeline,
  _index : UInt,
) -> GPUBindGroupLayout {
  unavailable()
}

///|
/// Creates a bind group layout in real JS/native builds.
pub fn webgpu_device_create_bind_group_layout(
  _device : WebGPUDevice,
  _bindings : Array[UInt],
  _visibilities : Array[UInt64],
  _buffer_types : Array[UInt],
  _has_dynamic_offsets : Array[Bool],
  _min_binding_sizes : Array[UInt64],
) -> GPUBindGroupLayout {
  unavailable()
}

///|
/// Creates a pipeline layout in real JS/native builds.
pub fn webgpu_device_create_pipeline_layout(
  _device : WebGPUDevice,
  _bind_group_layouts : Array[GPUBindGroupLayout],
) -> GPUPipelineLayout {
  unavailable()
}

///|
/// Creates a buffer bind group entry in real JS/native builds.
pub fn gp_bind_group_entry_buffer(
  _binding : UInt,
  _buffer : GPUBuffer,
) -> GPUBindGroupEntry {
  unavailable()
}

///|
/// Creates a buffer binding entry in real JS/native builds.
pub fn gp_bind_group_entry_buffer_binding(
  _binding : UInt,
  _buffer : GPUBuffer,
  _offset : UInt64,
  _size : UInt64,
) -> GPUBindGroupEntry {
  unavailable()
}

///|
/// Creates a texture view bind group entry in real JS/native builds.
pub fn gp_bind_group_entry_texture_view(
  _binding : UInt,
  _view : GPUTextureView,
) -> GPUBindGroupEntry {
  unavailable()
}

///|
/// Creates a texture bind group entry in real JS/native builds.
pub fn gp_bind_group_entry_texture(
  _binding : UInt,
  _texture : WebGPUTexture,
) -> GPUBindGroupEntry {
  unavailable()
}

///|
/// Creates a sampler bind group entry in real JS/native builds.
pub fn gp_bind_group_entry_sampler(
  _binding : UInt,
  _sampler : GPUSampler,
) -> GPUBindGroupEntry {
  unavailable()
}

///|
/// Creates an external texture bind group entry in real JS/native builds.
pub fn gp_bind_group_entry_external_texture(
  _binding : UInt,
  _texture : GPUExternalTexture,
) -> GPUBindGroupEntry {
  unavailable()
}

///|
/// Creates a bind group in real JS/native builds.
pub fn webgpu_device_create_bind_group(
  _device : WebGPUDevice,
  _layout : GPUBindGroupLayout,
  _entries : Array[GPUBindGroupEntry],
) -> GPUBindGroup {
  unavailable()
}

///|
/// Creates a buffer in real JS/native builds.
pub fn webgpu_device_create_buffer(
  _device : WebGPUDevice,
  _size : UInt64,
  _usage : UInt64,
) -> GPUBuffer {
  unavailable()
}

///|
/// Creates a texture in real JS/native builds.
pub fn webgpu_device_create_texture(
  _device : WebGPUDevice,
  _width : UInt,
  _height : UInt,
  _format : String,
  _usage : UInt64,
) -> WebGPUTexture {
  unavailable()
}

///|
/// Releases a texture in real native builds.
pub fn webgpu_texture_release(_texture : WebGPUTexture) -> Unit {
  unavailable()
}

///|
/// Creates a command encoder in real JS/native builds.
pub fn webgpu_device_create_command_encoder(
  _device : WebGPUDevice,
) -> WebGPUCommandEncoder {
  unavailable()
}

///|
/// Gets the current canvas texture in real JS/native builds.
pub fn webgpu_canvas_context_get_current_texture(
  _context : WebGPUCanvasContext,
) -> WebGPUTexture {
  unavailable()
}

///|
/// Presents a canvas context in real native builds.
pub fn webgpu_canvas_context_present(_context : WebGPUCanvasContext) -> Unit {
  unavailable()
}

///|
/// Creates a texture view in real JS/native builds.
pub fn webgpu_texture_create_view(_texture : WebGPUTexture) -> GPUTextureView {
  unavailable()
}

///|
/// Begins a render pass in real JS/native builds.
pub fn webgpu_command_encoder_begin_render_pass(
  _encoder : WebGPUCommandEncoder,
  _descriptor : WebGPURenderPassDescriptor,
) -> WebGPURenderPassEncoder {
  unavailable()
}

///|
/// Finishes a command encoder in real JS/native builds.
pub fn webgpu_command_encoder_finish(
  _encoder : WebGPUCommandEncoder,
) -> GPUCommandBuffer {
  unavailable()
}

///|
/// Submits a command buffer in real JS/native builds.
pub fn webgpu_queue_submit(
  _queue : WebGPUQueue,
  _command_buffer : GPUCommandBuffer,
) -> Unit {
  unavailable()
}

///|
/// Writes bytes into a buffer in real JS/native builds.
pub fn webgpu_queue_write_buffer(
  _queue : WebGPUQueue,
  _buffer : GPUBuffer,
  _offset : UInt64,
  _data : Bytes,
) -> Unit {
  unavailable()
}

///|
/// Writes an array view into a buffer in real JS/native builds.
pub fn webgpu_queue_write_buffer_array_view(
  _queue : WebGPUQueue,
  _buffer : GPUBuffer,
  _offset : UInt64,
  _data : ArrayView[Byte],
) -> Unit {
  unavailable()
}

///|
/// Writes a byte range into a buffer in real native builds.
pub fn webgpu_queue_write_buffer_bytes_range(
  _queue : WebGPUQueue,
  _buffer : GPUBuffer,
  _offset : UInt64,
  _data : Bytes,
  _data_offset : UInt64,
  _size : UInt64,
) -> Unit {
  unavailable()
}

///|
/// Copies an RGBA8 texture into a readback buffer in real JS/native builds.
pub fn webgpu_command_encoder_copy_texture_to_buffer_rgba8(
  _encoder : WebGPUCommandEncoder,
  _texture : WebGPUTexture,
  _buffer : GPUBuffer,
  _width : UInt,
  _height : UInt,
) -> Unit {
  unavailable()
}

///|
/// Reads back a buffer synchronously in real native builds.
pub fn webgpu_buffer_readback(
  _buffer : GPUBuffer,
  _instance : WebGPUInstance,
  _offset : UInt64,
  _size : UInt64,
) -> Bytes {
  unavailable()
}

///|
/// Reads back a buffer asynchronously in real JS builds.
pub async fn webgpu_buffer_readback_async(
  _buffer : GPUBuffer,
  _offset : UInt64,
  _size : UInt64,
) -> Bytes {
  unavailable()
}

///|
/// Reads back a buffer view in real native builds.
pub fn webgpu_buffer_readback_view(
  _buffer : GPUBuffer,
  _instance : WebGPUInstance,
  _offset : UInt64,
  _size : UInt64,
) -> BytesView {
  unavailable()
}

///|
/// Sets a render pipeline in real JS/native builds.
pub fn webgpu_render_pass_encoder_set_pipeline(
  _encoder : WebGPURenderPassEncoder,
  _pipeline : GPURenderPipeline,
) -> Unit {
  unavailable()
}

///|
/// Issues a draw command in real JS/native builds.
pub fn webgpu_render_pass_encoder_draw(
  _encoder : WebGPURenderPassEncoder,
  _vertex_count : Int,
) -> Unit {
  unavailable()
}

///|
/// Sets a vertex buffer in real JS/native builds.
pub fn webgpu_render_pass_encoder_set_vertex_buffer(
  _encoder : WebGPURenderPassEncoder,
  _slot : Int,
  _buffer : GPUBuffer,
  _offset : UInt64,
  _size : UInt64,
) -> Unit {
  unavailable()
}

///|
/// Sets an index buffer in real JS/native builds.
pub fn webgpu_render_pass_encoder_set_index_buffer(
  _encoder : WebGPURenderPassEncoder,
  _buffer : GPUBuffer,
  _format : @webgpu_enums.GPUIndexFormat,
  _offset : UInt64,
  _size : UInt64,
) -> Unit {
  unavailable()
}

///|
/// Issues an indexed draw command in real JS/native builds.
pub fn webgpu_render_pass_encoder_draw_indexed(
  _encoder : WebGPURenderPassEncoder,
  _index_count : Int,
  _instance_count : Int,
  _first_index : Int,
  _base_vertex : Int,
  _first_instance : Int,
) -> Unit {
  unavailable()
}

///|
/// Sets a bind group in real JS/native builds.
pub fn webgpu_render_pass_encoder_set_bind_group(
  _encoder : WebGPURenderPassEncoder,
  _index : UInt,
  _bind_group : GPUBindGroup,
  _dynamic_offsets : Array[UInt],
) -> Unit {
  unavailable()
}

///|
/// Ends a render pass in real JS/native builds.
pub fn webgpu_render_pass_encoder_end(
  _encoder : WebGPURenderPassEncoder,
) -> Unit {
  unavailable()
}

///|
/// Releases a shader module in real native builds.
pub fn shaderModule_release(_shader : GPUShaderModule) -> Unit {
  unavailable()
}

///|
/// Releases a render pipeline in real native builds.
pub fn renderPipeline_release(_pipeline : GPURenderPipeline) -> Unit {
  unavailable()
}

///|
/// Releases a pipeline layout in real native builds.
pub fn pipelineLayout_release(_layout : GPUPipelineLayout) -> Unit {
  unavailable()
}

///|
/// Releases a bind group layout in real native builds.
pub fn bindGroupLayout_release(_layout : GPUBindGroupLayout) -> Unit {
  unavailable()
}

///|
/// Releases a bind group in real native builds.
pub fn bindGroup_release(_bind_group : GPUBindGroup) -> Unit {
  unavailable()
}

///|
/// Releases a buffer in real native builds.
pub fn buffer_release(_buffer : GPUBuffer) -> Unit {
  unavailable()
}

///|
/// Releases a texture view in real native builds.
pub fn textureView_release(_view : GPUTextureView) -> Unit {
  unavailable()
}

///|
/// Releases a command encoder in real native builds.
pub fn webgpu_command_encoder_release(_encoder : WebGPUCommandEncoder) -> Unit {
  unavailable()
}

///|
/// Releases a render pass encoder in real native builds.
pub fn webgpu_render_pass_encoder_release(
  _encoder : WebGPURenderPassEncoder,
) -> Unit {
  unavailable()
}

///|
/// Creates a render pass color attachment in real JS/native builds.
pub fn create_render_pass_color_attachment(
  view~ : GPUTextureView,
  clearValue? : @webgpu_enums.GPUColor,
  loadOp~ : @webgpu_enums.GPULoadOp,
  storeOp~ : @webgpu_enums.GPUStoreOp,
) -> WebGPURenderPassColorAttachment {
  ignore(view)
  ignore(clearValue)
  ignore(loadOp)
  ignore(storeOp)
  unavailable()
}

///|
/// Creates a depth stencil attachment in real JS/native builds.
pub fn create_render_pass_depth_stencil_attachment(
  view~ : GPUTextureView,
  depthClearValue~ : Double?,
  depthLoadOp~ : @webgpu_enums.GPULoadOp,
  depthStoreOp~ : @webgpu_enums.GPUStoreOp,
) -> WebGPURenderPassDepthStencilAttachment {
  ignore(view)
  ignore(depthClearValue)
  ignore(depthLoadOp)
  ignore(depthStoreOp)
  unavailable()
}

///|
/// Creates a render pass descriptor in real JS/native builds.
pub fn create_render_pass_descriptor(
  colorAttachments~ : Array[WebGPURenderPassColorAttachment?],
  depthStencilAttachment? : WebGPURenderPassDepthStencilAttachment,
) -> WebGPURenderPassDescriptor {
  ignore(colorAttachments)
  ignore(depthStencilAttachment)
  unavailable()
}

///|
/// Tests whether an opaque pointer is null in real native builds.
pub fn opaque_ptr_is_null(_ptr : OpaquePtr) -> Bool {
  unavailable()
}

///|
/// Returns a null opaque pointer in real native builds.
pub fn null_opaque_ptr() -> OpaquePtr {
  unavailable()
}
